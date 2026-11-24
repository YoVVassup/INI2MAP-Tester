package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks sight_limit.tcl]

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

test sl-no-issues "No Sight issues" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(TestBldg) ""
    set ::Data::rawmapdata(TestBldg) {Sight=8}
    setup_index
    ::Checks::validate_sight_limit
    expr {$::Logging::warning_count == 0 && $::Logging::notice_count == 0}
} -result 1

test sl-sight-zero "Sight=0 blocks vision" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TestVeh) ""
    set ::Data::rawmapdata(TestVeh) {Sight=0}
    setup_index
    ::Checks::validate_sight_limit
    expr {$::Logging::warning_count > 0}
} -result 1

test sl-vanilla-over-10 "Sight>10 warns in vanilla RA2" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(TestInf) ""
    set ::Data::rawmapdata(TestInf) {Sight=15}
    setup_index
    ::Checks::validate_sight_limit
    expr {$::Logging::notice_count > 0}
} -result 1

reset_state
cleanupTests
