package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks super_gap_radius.tcl]

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

test sgr-normal "SuperGapRadiusInCells=10 no warn" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(TestBldg) ""
    set ::Data::rawmapdata(TestBldg) {SuperGapRadiusInCells=10}
    setup_index
    ::Checks::validate_super_gap_radius
    expr {$::Logging::warning_count == 0}
} -result 1

test sgr-over-127 "SuperGapRadiusInCells=150 warns in vanilla" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(TestBldg) ""
    set ::Data::rawmapdata(TestBldg) {SuperGapRadiusInCells=150}
    setup_index
    ::Checks::validate_super_gap_radius
    expr {$::Logging::warning_count > 0}
} -result 1

test sgr-ares-skip "SuperGapRadiusInCells=150 no warn in Ares" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::buildings(TestBldg) ""
    set ::Data::rawmapdata(TestBldg) {SuperGapRadiusInCells=150}
    setup_index
    ::Checks::validate_super_gap_radius
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
