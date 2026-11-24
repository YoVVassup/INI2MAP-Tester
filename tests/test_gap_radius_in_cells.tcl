package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks gap_radius_in_cells.tcl]

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
    array unset ::Data::superweapons
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test gr-over "GapRadiusInCells > 127 warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(GAP) ""
    set ::Data::rawmapdata(GAP) {GapRadiusInCells=128}
    setup_index
    ::Checks::validate_gap_radius_in_cells
    expr {$::Logging::warning_count > 0}
} -result 1

test gr-ok "GapRadiusInCells = 10 no warning" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(GAP) ""
    set ::Data::rawmapdata(GAP) {GapRadiusInCells=10}
    setup_index
    ::Checks::validate_gap_radius_in_cells
    expr {$::Logging::warning_count == 0}
} -result 1

test gr-skip "GapRadiusInCells in ares skipped" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::buildings(GAP) ""
    set ::Data::rawmapdata(GAP) {GapRadiusInCells=200}
    setup_index
    ::Checks::validate_gap_radius_in_cells
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
