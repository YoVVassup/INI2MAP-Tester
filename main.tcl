#----------------------------------------------------------------------------------------------------------
# main.tcl - INI2MAP Tester 1.0 entry point
#----------------------------------------------------------------------------------------------------------
# Entry point that sources all modules and runs the map validation.
# Supports .map, .yrm, .mpr file formats.
# Supports batch mode for validating multiple maps.
#----------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Set up script directory
# --------------------------------------------------------------------------
set script_dir [file dirname [info script]]
if {$script_dir eq ""} { set script_dir [pwd] }

# app_dir: directory where runtime files (DLL, settings.cfg, .enc) live.
# Starpack: files next to exe. Script mode: files next to scripts.
# Starpack variants: MOMT.exe / RA2MT.exe / RA2YRMT.exe.
set ::app_dir $script_dir
set exe_path [info nameofexecutable]
if {$exe_path ne "" && [string tolower [file rootname [file tail $exe_path]]] in {momt ra2mt ra2yrmt}} {
    set ::app_dir [file normalize [file dirname $exe_path]]
}

# --------------------------------------------------------------------------
# Load all modules
# --------------------------------------------------------------------------
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "cli.tcl"]
source [file join $script_dir "cache.tcl"]
source [file join $script_dir "utils.tcl"]

# External dependencies - ffidl for FFI, sha256 for hashing
set ffidl_dir [file join $script_dir "others" "ffidl"]
set sha256_dir [file join $script_dir "others" "sha256"]

# For starpack: load native DLLs from real filesystem (VFS can't load .dll)
# In script mode this also works — loads from app_dir directly
# Try ffidl_xp.dll first (self-contained, XP-compatible, no libffi dependency)
set real_ffidl_dll ""
foreach candidate [list [file join $::app_dir "ffidl_xp.dll"] [file join $::app_dir "others" "ffidl" "ffidl_xp.dll"]] {
    if {[file exists $candidate]} { set real_ffidl_dll $candidate; break }
}
if {$real_ffidl_dll ne ""} {
    if {[catch {load $real_ffidl_dll Ffidl} err]} {
        puts stderr "FATAL: Cannot load Ffidl from $real_ffidl_dll: $err"
        exit 1
    }
    package provide Ffidl 0.9
}

# For starpack: look for files next to exe (app_dir)
set sha256_file ""
if {[file exists [file join $::app_dir "sha256.tcl"]]} {
    set sha256_file [file join $::app_dir "sha256.tcl"]
}
if {$sha256_file eq "" && [file exists [file join $sha256_dir "sha256.tcl"]]} {
    set sha256_file [file join $sha256_dir "sha256.tcl"]
}

# Add ffidl to auto_path (only if not loaded above)
if {![catch {package present Ffidl}]} {
    # Already loaded, skip auto_path
} elseif {[file isdirectory $ffidl_dir] && [file exists [file join $ffidl_dir "pkgIndex.tcl"]]} {
    if {$ffidl_dir ni $::auto_path} {
        set ::auto_path [linsert $::auto_path 0 $ffidl_dir]
    }
}
# Try to load sha256 - first from app_dir, then from others/
set sha256_loaded 0
if {$sha256_file ne ""} {
    if {[catch {source $sha256_file} err]} {
        puts stderr "WARNING: Cannot load sha256 from $sha256_file: $err"
    } else {
        set sha256_loaded 1
    }
}
if {!$sha256_loaded && [file isdirectory $sha256_dir] && [file exists [file join $sha256_dir "pkgIndex.tcl"]]} {
    if {$sha256_dir ni $::auto_path} {
        set ::auto_path [linsert $::auto_path 0 $sha256_dir]
    }
}
if {!$sha256_loaded} {
    if {[catch {package require sha256} sha256_version]} {
        puts stderr "FATAL: sha256 package not available."
        puts stderr "Please place sha256.tcl next to MOMT.exe."
        exit 1
    } else {
        set sha256_loaded 1
    }
}
if {$sha256_loaded} {
    puts "sha256 loaded."
}

source [file join $script_dir "crypto.tcl"]
source [file join $script_dir "rules_parser.tcl"]
source [file join $script_dir "map_parser.tcl"]
source [file join $script_dir "validators.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "taglist" "taglist.tcl"]
source [file join $script_dir "aicheck" "aicheck.tcl"]
source [file join $script_dir "salt.tcl"]
source [file join $script_dir "config.tcl"]
source [file join $script_dir "orchestrator.tcl"]

# --------------------------------------------------------------------------
# Parse command line arguments
# --------------------------------------------------------------------------
::CLI::parse $argv

# --------------------------------------------------------------------------
# Load and validate configuration
# --------------------------------------------------------------------------
::Config::load

# --show-salt: report where the V2 salt comes from, then exit (no map needed)
if {[info exists ::CLI::show_salt] && $::CLI::show_salt} {
    ::Salt::show
    exit 0
}

::Config::validate

# --------------------------------------------------------------------------
# Initialize crypto
# --------------------------------------------------------------------------
if {![::Crypto::init]} {
    puts stderr "FATAL: Crypto module initialization failed."
    exit 3
}

# --------------------------------------------------------------------------
# Set v2 salt from CLI or settings.cfg
# --------------------------------------------------------------------------
if {$::CLI::salt ne ""} {
    set ::Crypto::v2_salt $::CLI::salt
} elseif {[info exists ::Config::v2_salt] && $::Config::v2_salt ne ""} {
    set ::Crypto::v2_salt $::Config::v2_salt
}
# Never echo the salt itself (it is a secret); print the same placeholder
# the README shows for the expected output.
if {$::Crypto::v2_salt ne "" && !$::CLI::cmd_quiet} {
    puts "V2 salt: <64-hex salt>"
}

# --------------------------------------------------------------------------
# Initialize common runtime state
# --------------------------------------------------------------------------
set ::Data::logproc ::Logging::logputs_impl

# --------------------------------------------------------------------------
# Handle baseline mode
# --------------------------------------------------------------------------
if {$::CLI::baseline_mode} {
    if {!$::CLI::cmd_quiet} {
        puts "\n========================================"
        puts "BASELINE MODE"
        puts "========================================"
        puts "Generating baseline from INI checks..."
        puts "No map file will be parsed."
        puts "========================================\n"
    }

    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::path "[file normalize [file dirname $::CLI::cfg_file]]/"
    set ::Data::argv "baseline"
    set ::Data::started [clock milliseconds]
    set ::Data::animlog ""

    if {[catch {baseline_check} err]} {
        ::Logging::error "Unhandled exception during baseline generation: $err"
        if {[info exists ::errorInfo]} {
            puts stderr "Stack trace:"
            foreach line [split $::errorInfo \n] {
                puts stderr "  $line"
            }
        }
        exit 3
    }

    set exit_code [::Logging::get_exit_code]
    if {!$::CLI::cmd_quiet} {
        puts "\n========================================"
        puts "BASELINE COMPLETE"
        puts "  Errors:   $::Logging::error_count"
        puts "  Warnings: $::Logging::warning_count"
        puts "  Notices:  $::Logging::notice_count"
        puts "  Total:    [expr {$::Logging::error_count + $::Logging::warning_count + $::Logging::notice_count}]"
        puts "========================================"
    }
    exit $exit_code
}

# --------------------------------------------------------------------------
# Resolve map files (single or batch)
# --------------------------------------------------------------------------
if {$::CLI::batch_mode} {
    set map_files [::CLI::resolve_batch]
    if {!$::CLI::cmd_quiet} {
        puts "\nBatch mode: [llength $map_files] map(s) to validate"
        puts "========================================"
    }

    set worst_exit 0
    set total_errors 0
    set total_warnings 0
    set total_notices 0
    set total_suppressed 0
    set results [list]

    # Source audio parser once
    if {$::Data::sound_check_audio} {
        source [file join $script_dir "audio_parser.tcl"]
    }

    # Load baseline filter once for batch processing
    if {$::CLI::baseline_filter ne ""} {
        ::Logging::load_baseline $::CLI::baseline_filter
    }

    # --- Pre-load rules and audio ONCE for all maps in batch ---
    # This avoids re-decrypting 6+ .enc files for every map (~5s savings per map)
    if {[llength $map_files] > 1 && (![info exists ::Data::rules_loaded] || !$::Data::rules_loaded)} {
        if {!$::CLI::cmd_quiet} {
            puts "\nPre-loading game rules for batch mode..."
        }
        set pre_start [clock milliseconds]
        ::Rules::load_all $::Data::ra2dir_abs $::Data::ra2rul $::Data::ra2ai $::Data::ra2art $::Data::ra2snd $::Data::ra2tm $::Data::ra2eva
        if {$::Data::sound_check_audio && (![info exists ::Data::audio_idx_available] || !$::Data::audio_idx_available)} {
            ::Orchestrator::_load_audio
        }
        ::RulesCache::save
        set pre_elapsed [expr {[clock milliseconds] - $pre_start}]
        if {!$::CLI::cmd_quiet} {
            puts "Rules cached in ${pre_elapsed}ms"
        }
    }

    # Batch never auto-opens per-map logs (that would pop one window per
    # map) and always rewrites them (per-map logs ignore the savelog flag,
    # matching the previous batch behavior).
    set ::Data::auto_open_log 0
    set ::Data::savelog 0

    foreach map_path $map_files {
        set map_name [file tail $map_path]
        if {!$::CLI::cmd_quiet} {
            puts "\n--- Validating: $map_name ---"
        }

        # Restore cached rules instead of re-decrypting
        # First clear ALL ::Data arrays for clean state
        foreach arrName [info vars ::Data::*] {
            if {[array exists $arrName]} {
                catch {array unset $arrName}
            }
        }
        foreach varName {mapunits sound_defaults maperr animlog started rules_loaded theme} {
            catch {set ::Data::$varName {}}
        }
        foreach varName {mismap newini mhouses ignoreglobals maspect} {
            catch {set ::Data::$varName 0}
        }
        set ::Data::rules_loaded 0

        # Then restore cached rules + audio (avoids re-decrypting .enc files)
        if {$::RulesCache::ready} {
            ::RulesCache::restore
        }

        ::Logging::reset_counts

        set ::Data::path "[file normalize [file dirname $map_path]]/"
        set ::Data::argv $map_name
        set ::Data::started [clock milliseconds]
        if {!$::RulesCache::ready} {
            set ::Data::rules_loaded 0
        }

        if {[catch {mapcheck} err]} {
            ::Logging::error "Unhandled exception: $err"
            if {[info exists ::errorInfo]} {
                logputs "Stack trace:"
                foreach stack_line [split $::errorInfo \n] {
                    logputs "  $stack_line"
                }
            }
        }

        set ec [::Logging::get_exit_code]
        if {$ec > $worst_exit} { set worst_exit $ec }
        incr total_errors $::Logging::error_count
        incr total_warnings $::Logging::warning_count
        incr total_notices $::Logging::notice_count
        incr total_suppressed $::Logging::suppressed_count

        lappend results [list $map_name $ec $::Logging::error_count $::Logging::warning_count $::Logging::notice_count]

        # Write individual log file: JSON per map when --format json
        # (json_report.exe turns it into an HTML report), plain text otherwise.
        if {$::CLI::cmd_format eq "json"} {
            logwrite "$map_name.log"
        } else {
            set logpath "[set ::Data::path]$map_name.log"
            if {[catch {open $logpath w} fh]} {
                ::Logging::error "Cannot write log for $map_name"
            } else {
                if {[catch {
                    puts $fh "\n---- MISSION REPORT FOR $map_name ----"
                    foreach line $::Data::maperr {
                        puts $fh $line
                    }
                    puts $fh ""
                    puts $fh "---- SUMMARY ----"
                    puts $fh "Errors:   $::Logging::error_count"
                    puts $fh "Warnings: $::Logging::warning_count"
                    puts $fh "Notices:  $::Logging::notice_count"
                    puts $fh "\nTotal processing time: [expr {[clock milliseconds] - $::Data::started}]ms"
                } write_err]} {
                    ::Logging::error "Error writing log for $map_name: $write_err"
                }
                catch {close $fh}
            }
        }

        if {!$::CLI::cmd_quiet} {
            set status "OK"
            if {$ec == 1} { set status "WARN" }
            if {$ec == 2} { set status "ERROR" }
            if {$ec == 3} { set status "FATAL" }
            puts "  Result: $status (E:$::Logging::error_count W:$::Logging::warning_count N:$::Logging::notice_count)"
        }
    }

    # Print batch summary
    if {!$::CLI::cmd_quiet} {
        puts "\n========================================"
        puts "BATCH SUMMARY"
        puts "========================================"
        puts "  Maps processed: [llength $results]"
        puts "  Total errors:   $total_errors"
        puts "  Total warnings: $total_warnings"
        puts "  Total notices:  $total_notices"
        if {$total_suppressed > 0} {
            puts "  Suppressed:     $total_suppressed (baseline filter)"
        }
        puts ""
        puts "  Results by map:"
        foreach r $results {
            lassign $r name ec errs wrns notes
            set status "OK"
            if {$ec == 1} { set status "WARN" }
            if {$ec == 2} { set status "ERROR" }
            if {$ec == 3} { set status "FATAL" }
            puts "    $name: $status (E:$errs W:$wrns N:$notes)"
        }
        puts "========================================"
    }

    # Write batch summary JSON if requested
    if {$::CLI::cmd_format eq "json"} {
        set summary_path "[file normalize [pwd]]/batch_summary.json"
        if {[catch {open $summary_path w} fh]} {
            ::Logging::error "Cannot write batch summary"
        } else {
            if {[catch {
                puts $fh "{"
                puts $fh "  \"total_maps\": [llength $results],"
                puts $fh "  \"total_errors\": $total_errors,"
                puts $fh "  \"total_warnings\": $total_warnings,"
                puts $fh "  \"total_notices\": $total_notices,"
                puts $fh "  \"results\": \["
                set first 1
                foreach r $results {
                    lassign $r name ec errs wrns notes
                    set status "ok"
                    if {$ec == 1} { set status "warning" }
                    if {$ec == 2} { set status "error" }
                    if {$ec == 3} { set status "fatal" }
                    if {!$first} { puts $fh "," }
                    set first 0
                    set safe_name [string map [list "\\" "\\\\" "\"" "\\\"" "\n" "\\n" "\t" "\\t"] $name]
                    puts -nonewline $fh "    \{\"map\": \"$safe_name\", \"status\": \"$status\", \"errors\": $errs, \"warnings\": $wrns, \"notices\": $notes\}"
                }
                puts $fh ""
                puts $fh "  \]"
                puts $fh "}"
            } write_err]} {
                ::Logging::error "Error writing batch summary: $write_err"
            }
            catch {close $fh}
            if {!$::CLI::cmd_quiet} {
                puts "Batch summary saved to: $summary_path"
            }
        }
    }

    exit $worst_exit
} else {
    # Single map mode
    set ::Data::maperr {}
    ::Logging::reset_counts
    set ::Data::path "[file normalize [file dirname $::CLI::map_file]]/"
    set ::Data::argv [file tail $::CLI::map_file]
    set ::Data::started [clock milliseconds]
    set ::Data::animlog ""
    set ::Data::logproc ::Logging::logputs_impl

    if {[catch {mapcheck} err]} {
        ::Logging::error "Unhandled exception during map checking: $err"
        if {[info exists ::errorInfo]} {
            logputs "Stack trace:"
            foreach line [split $::errorInfo \n] {
                logputs "  $line"
            }
        } else {
            logputs "Stack trace not available."
        }
        logwrite
        puts stderr "\n>> ERROR: Validation failed with an unhandled exception. See log for details."
        exit 3
    }

    logwrite

    set exit_code [::Logging::get_exit_code]
    switch -- $exit_code {
        0 { puts "\n>> Validation passed with no issues." }
        1 { puts "\n>> Validation completed with warnings." }
        2 { puts stderr "\n>> Validation completed with errors." }
        3 { puts stderr "\n>> Validation failed with fatal error." }
    }
    if {$::Logging::suppressed_count > 0} {
        puts ">> Suppressed $::Logging::suppressed_count message(s) by baseline filter."
    }
    exit $exit_code
}
