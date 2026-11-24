package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks strength_zero.tcl]

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

test strz-normal "Normal Strength value" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(TestBldg) ""
    set ::Data::rawmapdata(TestBldg) {Strength=1000}
    setup_index
    ::Checks::validate_strength_zero
    expr {$::Logging::warning_count == 0}
} -result 1

test strz-zero-warns "Strength=0 warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TestVeh) ""
    set ::Data::rawmapdata(TestVeh) {Strength=0}
    setup_index
    ::Checks::validate_strength_zero
    expr {$::Logging::warning_count > 0}
} -result 1

test strz-not-set "Strength not set (skipped)" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(TestInf) ""
    set ::Data::rawmapdata(TestInf) {Speed=5}
    setup_index
    ::Checks::validate_strength_zero
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
