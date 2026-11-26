#----------------------------------------------------------------------------------------------------------
# cli.tcl - Command line argument parsing for INI2MAP Tester
#----------------------------------------------------------------------------------------------------------
# Parses CLI arguments and sets configuration variables.
# Supported options:
#   --cfg <file>       - use alternative configuration file (default: settings.cfg)
#   --mode <mode>      - set game mode (ra2, yr, ares, phobos)
#   --format <fmt>     - output format: text (default), json
#   --batch <pattern>  - validate multiple maps (*.map, directory, or file list)
#   --no-log-open      - disable automatic opening of log file after validation
#   --quiet            - suppress informational console output (errors still shown)
#   --help, -h         - show help and exit
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::CLI::loaded]} { return }
namespace eval ::CLI { variable loaded 1 }

# --- Maintainer gate -------------------------------------------------------
# --salt and --show-salt exist for maintainers only. The gate is a marker file
# next to this script, i.e. inside the payload of a starpack - never next to the
# exe, so a recipient cannot add it after the fact. build.bat writes it only
# for a maintainer build (INI2MAP_MAINTAINER); a source checkout needs a local,
# gitignored copy in the project root.
namespace eval ::CLI {
    variable maintainer_mode 0
    set _cli_dir [file dirname [info script]]
    if {[file exists [file join $_cli_dir "maintainer.enabled"]]} {
        set maintainer_mode 1
    }
    unset -nocomplain _cli_dir
}

# --- Parse command line arguments ---
proc ::CLI::parse {argv} {
    variable cfg_file [file join $::app_dir "settings.cfg"]
    variable cmd_gamemode ""
    variable cmd_no_log_open 0
    variable cmd_quiet 0
    variable cmd_format "text"
    variable cmd_timing 0
    variable map_file ""
    variable batch_mode 0
    variable batch_pattern ""
    variable salt ""
    variable show_salt 0
    variable baseline_mode 0
    variable baseline_filter ""

    set i 0
    set argc [llength $argv]
    while {$i < $argc} {
        set arg [lindex $argv $i]
        switch -exact -- $arg {
            "--cfg" {
                incr i
                if {$i >= $argc} {
                    puts stderr "ERROR: --cfg requires a file argument"
                    exit 1
                }
                set cfg_file [lindex $argv $i]
                incr i
            }
            "--mode" {
                incr i
                if {$i >= $argc} {
                    puts stderr "ERROR: --mode requires an argument (ra2, yr, ares, phobos)"
                    exit 1
                }
                set cmd_gamemode [lindex $argv $i]
                if {$cmd_gamemode ni {ra2 yr ares phobos}} {
                    puts stderr "ERROR: --mode must be 'ra2', 'yr', 'ares' or 'phobos' (got: $cmd_gamemode)"
                    exit 1
                }
                incr i
            }
            "--format" {
                incr i
                if {$i >= $argc} {
                    puts stderr "ERROR: --format requires an argument (text, json)"
                    exit 1
                }
                set cmd_format [lindex $argv $i]
                if {$cmd_format ne "text" && $cmd_format ne "json"} {
                    puts stderr "ERROR: --format must be 'text' or 'json'"
                    exit 1
                }
                incr i
            }
            "--batch" {
                set batch_mode 1
                incr i
                if {$i < $argc && [string index [lindex $argv $i] 0] ne "-"} {
                    set batch_pattern [lindex $argv $i]
                    incr i
                }
            }
            "--timing" {
                set cmd_timing 1
                incr i
            }
            "--no-log-open" {
                set cmd_no_log_open 1
                incr i
            }
            "--quiet" {
                set cmd_quiet 1
                incr i
            }
            "--salt" {
                if {!$::CLI::maintainer_mode} {
                    puts stderr "ERROR: Unknown option: $arg"
                    exit 1
                }
                incr i
                if {$i >= $argc} {
                    puts stderr "ERROR: --salt requires a hex string argument"
                    exit 1
                }
                set salt [lindex $argv $i]
                incr i
            }
            "--show-salt" {
                if {!$::CLI::maintainer_mode} {
                    puts stderr "ERROR: Unknown option: $arg"
                    exit 1
                }
                set show_salt 1
                incr i
            }
            "--baseline" {
                set baseline_mode 1
                incr i
            }
            "--baseline-filter" {
                incr i
                if {$i >= $argc} {
                    puts stderr "ERROR: --baseline-filter requires a file argument"
                    exit 1
                }
                set baseline_filter [lindex $argv $i]
                incr i
            }
            "--help" - "-h" {
                ::CLI::show_help
                exit 0
            }
            default {
                if {[string index $arg 0] ne "-"} {
                    if {$map_file eq ""} {
                        set map_file $arg
                    } else {
                        puts stderr "ERROR: Multiple map files specified. Only one map file is allowed (use --batch for multiple)."
                        exit 1
                    }
                } else {
                    puts stderr "ERROR: Unknown option: $arg"
                    exit 1
                }
                incr i
            }
        }
    }

    if {!$batch_mode && $map_file eq "" && !$baseline_mode && !$show_salt} {
        puts stderr "ERROR: No map file specified."
        ::CLI::show_help_short
        exit 1
    }

    return 1
}

# --- Resolve batch pattern to list of map files ---
proc ::CLI::resolve_batch {} {
    variable batch_pattern
    variable map_file

    set maps [list]

    if {$batch_pattern ne ""} {
        # Windows paths use backslashes, but glob treats \ as an escape
        # character - normalize so "Build\*.map" and "Build/*.map" both work.
        set batch_pattern [string map [list "\\" "/"] $batch_pattern]
        # Check if it's a directory
        if {[file isdirectory $batch_pattern]} {
            foreach ext {.map .yrm .mpr} {
                foreach f [glob -nocomplain [file join $batch_pattern "*$ext"]] {
                    lappend maps $f
                }
            }
        } else {
            # Try glob expansion directly
            set expanded [glob -nocomplain $batch_pattern]
            if {[llength $expanded] > 0} {
                foreach f $expanded {
                    set ext [string tolower [file extension $f]]
                    if {$ext eq ".map" || $ext eq ".yrm" || $ext eq ".mpr"} {
                        lappend maps $f
                    }
                }
            }
            # If no matches, try appending extensions
            if {[llength $maps] == 0} {
                foreach ext {.map .yrm .mpr} {
                    set expanded [glob -nocomplain "${batch_pattern}${ext}"]
                    foreach f $expanded {
                        lappend maps $f
                    }
                }
            }
            # If still no matches, check if it's a single file
            if {[llength $maps] == 0 && [file exists $batch_pattern]} {
                lappend maps $batch_pattern
            }
        }
    } elseif {$map_file ne ""} {
        lappend maps $map_file
    }

    # Remove duplicates and sort
    set maps [lsort -unique $maps]

    if {[llength $maps] == 0} {
        puts stderr "ERROR: No map files found matching the pattern."
        exit 1
    }

    return $maps
}

# --- Show help text ---
proc ::CLI::show_help {} {
    puts "INI2MAP Tester 1.0 - Map validation tool for RA2/YR"
    puts ""
    puts {Usage: tclsh main.tcl [options] <map_file>}
    puts {       tclsh main.tcl --batch <pattern|directory>}
    puts ""
    puts "Options:"
    puts {  --cfg <file>              Use alternative configuration file (default: settings.cfg)}
    puts {  --mode <mode>             Set game mode: ra2, yr, ares, phobos (overrides settings.cfg)}
    puts {  --format <fmt>            Output format: text (default), json}
    puts {  --batch <pattern>         Validate multiple maps (glob pattern, directory, or single file)}
    puts {  --timing                  Show timing for each validation phase}
    puts {  --no-log-open             Do not automatically open the log file after validation}
    puts {  --quiet                   Suppress informational console output (errors still shown)}
    if {$::CLI::maintainer_mode} {
        puts {  --salt <hex>              Salt for v2 multi-factor encryption (64+ hex chars)}
        puts {  --show-salt               Show salt scope/source (registry/carrier/settings.cfg) and exit}
    }
    puts {  --baseline                Generate baseline.log from INI checks (no map file needed)}
    puts {  --baseline-filter <file>  Suppress known warnings from baseline file during validation}
    puts {  --help, -h                Show this help and exit}
    puts ""
    puts "Batch mode examples:"
    puts {  --batch *.map            All .map files in current directory}
    puts {  --batch maps/            All map files in maps/ subdirectory}
    puts {  --batch "mission*.map"   Files matching pattern}
    puts ""
    puts "Baseline examples:"
    puts {  --baseline               Generate baseline.log (known INI warnings)}
    puts {  --baseline-filter baseline.log  Filter out known warnings from validation}
    puts ""
    puts "Exit codes:"
    puts {  0   Validation passed with no issues}
    puts {  1   Validation completed with warnings only}
    puts {  2   Validation completed with errors}
    puts {  3   Fatal error (unhandled exception)}
}

proc ::CLI::show_help_short {} {
    puts {Usage: tclsh main.tcl [options] <map_file>}
    puts {       tclsh main.tcl --batch <pattern|directory>}
    puts {       tclsh main.tcl --baseline}
    puts {  Supported formats: .map, .yrm, .mpr}
}
