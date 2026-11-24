package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks sonic_mindcontrol.tcl]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::buildings
    array unset ::Data::projectiles
    array unset ::Data::warheads
    array unset ::Data::weapons
    array unset ::Data::teamtypes
    array unset ::Data::taskforces
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test smc-no-conflict "Warhead with Sonic only" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::warheads(0) "SonicWH"
    set ::Data::rawmapdata(SonicWH) {Sonic=yes MindControl=no}
    setup_index
    ::Checks::validate_sonic_mindcontrol
    expr {$::Logging::warning_count == 0}
} -result 1

test smc-both-set "Sonic+MindControl both set warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::warheads(0) "BadWH"
    set ::Data::rawmapdata(BadWH) {Sonic=yes MindControl=yes}
    setup_index
    ::Checks::validate_sonic_mindcontrol
    expr {$::Logging::warning_count > 0}
} -result 1

test smc-neither-set "Neither flag set" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::warheads(0) "NormalWH"
    set ::Data::rawmapdata(NormalWH) {Sonic=no MindControl=no}
    setup_index
    ::Checks::validate_sonic_mindcontrol
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
