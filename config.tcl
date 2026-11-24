#----------------------------------------------------------------------------------------------------------
# config.tcl - Configuration loading and defaults for INI2MAP Tester
#----------------------------------------------------------------------------------------------------------
# Loads settings.cfg, applies defaults, and stores config in ::Data namespace.
# Config file should return a dict with configuration values.
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Config::loaded]} { return }
namespace eval ::Config { variable loaded 1 }

# --- Default configuration values ---
# Used when settings.cfg doesn't provide a value.
namespace eval ::Config {
    variable defaults [dict create \
        ra2dir "./" \
        ra2rul "rulesmo.enc" \
        ra2ai  "aimo.enc" \
        ra2art "artmo.enc" \
        ra2snd "soundmo.enc" \
        ra2tm  "thememo.enc" \
        ra2eva "evamo.enc" \
        gamemode "ares" \
        savelog 0 \
        writeanims 1 \
        showunused 1 \
        paranoid 1 \
        auto_open_log 1 \
        ini_encoding "" \
        sound_validation 1 \
        sound_check_audio 1 \
        sound_warn_unused 1 \
        sound_warn_duplicate_resources 0 \
        sound_warn_orphan_resources 1 \
        crypto_dll_expected_hash "" \
        v2_salt "" \
        tclsh_path "" \
    ]
}

# --- Load configuration file and apply defaults ---
# Requires: ::CLI namespace variables (cfg_file, cmd_gamemode, cmd_no_log_open, cmd_quiet)
proc ::Config::load {} {
    variable defaults

    # Load config file
    set cfg_file $::CLI::cfg_file
    set cfg [dict create]
    if {[file exists $cfg_file]} {
        if {[catch {set cfg [source $cfg_file]} err]} {
            puts stderr "WARNING: Error loading configuration file '$cfg_file': $err"
        }
    } else {
        puts stderr "WARNING: Configuration file '$cfg_file' not found. Using defaults."
    }

    # A config source that did not return a valid dict (broken settings.cfg or
    # an error that left a partial value) must not crash the app below.
    if {[catch {dict size $cfg}]} {
        puts stderr "WARNING: Configuration file '$cfg_file' did not return a valid dict. Using defaults."
        set cfg [dict create]
    }

    # Merge config with defaults (config values override defaults)
    set merged [dict merge $defaults $cfg]

    # Apply CLI overrides
    if {$::CLI::cmd_gamemode ne ""} {
        dict set merged gamemode $::CLI::cmd_gamemode
    }
    if {$::CLI::cmd_no_log_open} {
        dict set merged auto_open_log 0
    }
    if {$::CLI::cmd_quiet} {
        set ::Data::quiet_mode 1
    } else {
        set ::Data::quiet_mode 0
    }

    # Unknown gamemode would silently behave as "ares" in validators/core.tcl
    if {[dict get $merged gamemode] ni {ra2 yr ares phobos}} {
        puts stderr "WARNING: Unknown gamemode '[dict get $merged gamemode]'. Using 'ares'."
        dict set merged gamemode ares
    }

    # Store in ::Data namespace
    set ra2dir_val [dict get $merged ra2dir]
    if {[file pathtype $ra2dir_val] eq "relative"} {
        set ::Data::ra2dir_abs [file normalize [file join $::app_dir $ra2dir_val]]
    } else {
        set ::Data::ra2dir_abs [file normalize $ra2dir_val]
    }
    set ::Data::ra2rul [dict get $merged ra2rul]
    set ::Data::ra2ai [dict get $merged ra2ai]
    set ::Data::ra2art [dict get $merged ra2art]
    set ::Data::ra2snd [dict get $merged ra2snd]
    set ::Data::ra2tm [dict get $merged ra2tm]
    set ::Data::ra2eva [dict get $merged ra2eva]
    set ::Data::savelog [dict get $merged savelog]
    set ::Data::writeanims [dict get $merged writeanims]
    set ::Data::showunused [dict get $merged showunused]
    set ::Data::auto_open_log [dict get $merged auto_open_log]
    set ::Data::gamemode [dict get $merged gamemode]
    set ::Data::strictra2 [expr {[dict get $merged gamemode] eq "ra2"}]
    set ::Data::paranoid [dict get $merged paranoid]
    set ::Data::ini_encoding [dict get $merged ini_encoding]

    # Sound validation settings
    set ::Data::sound_validation [dict get $merged sound_validation]
    set ::Data::sound_check_audio [dict get $merged sound_check_audio]
    set ::Data::sound_warn_unused [dict get $merged sound_warn_unused]
    set ::Data::sound_warn_duplicate_resources [dict get $merged sound_warn_duplicate_resources]
    set ::Data::sound_warn_orphan_resources [dict get $merged sound_warn_orphan_resources]

    # Set global variable for crypto.tcl backward compatibility
    global crypto_dll_expected_hash
    set crypto_dll_expected_hash [dict get $merged crypto_dll_expected_hash]

    # V2 salt (can be overridden by --salt CLI option)
    set ::Config::v2_salt [dict get $merged v2_salt]

    # Optional explicit tclsh location for subprocess decrypt (empty = auto-detect)
    set ::Config::tclsh_path [dict get $merged tclsh_path]
}

# --- Validate game directory and required files ---
proc ::Config::validate {} {
    if {![file isdirectory $::Data::ra2dir_abs]} {
        puts stderr "FATAL: Game directory '$::Data::ra2dir_abs' does not exist or is not a directory."
        exit 1
    }
    if {!$::Data::quiet_mode} {
        puts "Game directory: $::Data::ra2dir_abs"
    }

    set rule_files [list \
        [list "rules" $::Data::ra2rul 1] \
        [list "ai"    $::Data::ra2ai  1] \
        [list "art"   $::Data::ra2art 0] \
        [list "sound" $::Data::ra2snd 0] \
        [list "theme" $::Data::ra2tm  0] \
        [list "eva"   $::Data::ra2eva 0] \
    ]

    foreach item $rule_files {
        lassign $item name filename required
        set fullpath [file join $::Data::ra2dir_abs $filename]
        if {[file exists $fullpath] && [file readable $fullpath]} {
            if {!$::Data::quiet_mode} {
                puts "  $name: $filename (ok)"
            }
        } else {
            if {$required} {
                puts stderr "FATAL: Required $name file '$fullpath' not found or not readable."
                exit 1
            } else {
                puts "WARNING: Optional $name file '$fullpath' not found or not readable. Some features may be disabled."
            }
        }
    }
}
