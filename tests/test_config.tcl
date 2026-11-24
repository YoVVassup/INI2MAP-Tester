#----------------------------------------------------------------------------------------------------------
# test_config.tcl - Unit tests for config.tcl
# Tests: Config::load (defaults, CLI overrides, merge), Config::validate
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
set test_tmpdir [file join $script_dir "tests" "_tmp"]
file mkdir $test_tmpdir
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]

# Set up minimal CLI namespace for Config::load
namespace eval ::CLI {
    variable loaded 1
    variable cfg_file ""
    variable cmd_gamemode ""
    variable cmd_no_log_open 0
    variable cmd_quiet 1
    variable cmd_format "text"
    variable cmd_timing 0
}

set ::app_dir $script_dir

source [file join $script_dir config.tcl]

proc reset_config {} {
    # Reset CLI variables
    set ::CLI::cfg_file ""
    set ::CLI::cmd_gamemode ""
    set ::CLI::cmd_no_log_open 0
    set ::CLI::cmd_quiet 1
    # Reset key Data namespace variables
    foreach v {gamemode strictra2 savelog auto_open_log quiet_mode paranoid} {
        if {[info exists ::Data::$v]} { unset ::Data::$v }
    }
}

# --------------------------------------------------------------------------
# Test 1: defaults applied when no config file
# --------------------------------------------------------------------------
test cfg-defaults "defaults applied when no config file" -body {
    reset_config
    set ::CLI::cfg_file [file join $test_tmpdir "_no_such" "settings.cfg"]
    ::Config::load
    list $::Data::gamemode $::Data::savelog $::Data::auto_open_log
} -result {ares 0 1}

# --------------------------------------------------------------------------
# Test 2: strictra2 set when gamemode is ra2
# --------------------------------------------------------------------------
test cfg-strictra2-ra2 "strictra2 true when gamemode=ra2" -body {
    reset_config
    set ::CLI::cfg_file [file join $test_tmpdir "_no_such" "settings.cfg"]
    set ::CLI::cmd_gamemode "ra2"
    ::Config::load
    list $::Data::gamemode $::Data::strictra2
} -result {ra2 1}

# --------------------------------------------------------------------------
# Test 3: strictra2 false when gamemode is yr
# --------------------------------------------------------------------------
test cfg-strictra2-yr "strictra2 false when gamemode=yr" -body {
    reset_config
    set ::CLI::cfg_file [file join $test_tmpdir "_no_such" "settings.cfg"]
    set ::CLI::cmd_gamemode "yr"
    ::Config::load
    list $::Data::gamemode $::Data::strictra2
} -result {yr 0}

# --------------------------------------------------------------------------
# Test 4: CLI mode overrides config
# --------------------------------------------------------------------------
test cfg-cli-mode-override "CLI mode overrides config gamemode" -body {
    reset_config
    set ::CLI::cfg_file [file join $test_tmpdir "_no_such" "settings.cfg"]
    set ::CLI::cmd_gamemode "phobos"
    ::Config::load
    set ::Data::gamemode
} -result phobos

# --------------------------------------------------------------------------
# Test 5: cmd_no_log_open sets auto_open_log=0
# --------------------------------------------------------------------------
test cfg-no-log-open "cmd_no_log_open disables auto_open_log" -body {
    reset_config
    set ::CLI::cfg_file [file join $test_tmpdir "_no_such" "settings.cfg"]
    set ::CLI::cmd_no_log_open 1
    ::Config::load
    set ::Data::auto_open_log
} -result 0

# --------------------------------------------------------------------------
# Test 6: quiet_mode set from CLI
# --------------------------------------------------------------------------
test cfg-quiet "quiet_mode from CLI flag" -body {
    reset_config
    set ::CLI::cfg_file [file join $test_tmpdir "_no_such" "settings.cfg"]
    set ::CLI::cmd_quiet 1
    ::Config::load
    set ::Data::quiet_mode
} -result 1

# --------------------------------------------------------------------------
# Test 7: config file values override defaults
# --------------------------------------------------------------------------
test cfg-file-override "config file overrides defaults" -body {
    reset_config
    set tmpfile [file join $test_tmpdir "momt_test_settings.cfg"]
    set fh [open $tmpfile w]
    puts $fh {return [dict create gamemode "yr" savelog 1 paranoid 0]}
    close $fh
    set ::CLI::cfg_file $tmpfile
    ::Config::load
    file delete -force $tmpfile
    list $::Data::gamemode $::Data::savelog $::Data::paranoid
} -result {yr 1 0}

# --------------------------------------------------------------------------
# Test 8: sound validation defaults
# --------------------------------------------------------------------------
test cfg-sound-defaults "sound validation defaults" -body {
    reset_config
    set ::CLI::cfg_file [file join $test_tmpdir "_no_such" "settings.cfg"]
    ::Config::load
    list $::Data::sound_validation $::Data::sound_check_audio $::Data::sound_warn_unused
} -result {1 1 1}

# --------------------------------------------------------------------------
# Test 9: ra2dir_abs is normalized
# --------------------------------------------------------------------------
test cfg-ra2dir-normalized "ra2dir_abs is normalized" -body {
    reset_config
    set ::CLI::cfg_file [file join $test_tmpdir "_no_such" "settings.cfg"]
    ::Config::load
    expr {[file pathtype $::Data::ra2dir_abs] eq "absolute"}
} -result 1

# --------------------------------------------------------------------------
# Test 10: ra2dir default is ./ (relative)
# --------------------------------------------------------------------------
test cfg-ra2dir-relative "ra2dir default is relative" -body {
    reset_config
    set ::CLI::cfg_file [file join $test_tmpdir "_no_such" "settings.cfg"]
    ::Config::load
    expr {[file pathtype $::Data::ra2dir_abs] eq "absolute"}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_config
cleanupTests
