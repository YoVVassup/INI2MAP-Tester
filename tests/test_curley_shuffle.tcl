package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks curley_shuffle.tcl]

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

test cs-affected "CurleyShuffle + AirportBound warns" -body {
    reset_state
    set ::Data::rawmapdata(General) {CurleyShuffle=yes}
    set ::Data::aircraft(HELI) ""
    set ::Data::rawmapdata(HELI) {AirportBound=yes}
    setup_index
    ::Checks::validate_curley_shuffle
    expr {$::Logging::warning_count > 0}
} -result 1

test cs-noairport "CurleyShuffle + no AirportBound no warn" -body {
    reset_state
    set ::Data::rawmapdata(General) {CurleyShuffle=yes}
    set ::Data::aircraft(HELI) ""
    set ::Data::rawmapdata(HELI) {AirportBound=no}
    setup_index
    ::Checks::validate_curley_shuffle
    expr {$::Logging::warning_count == 0}
} -result 1

test cs-disabled "CurleyShuffle=no no warning" -body {
    reset_state
    set ::Data::rawmapdata(General) {CurleyShuffle=no}
    set ::Data::aircraft(HELI) ""
    set ::Data::rawmapdata(HELI) {AirportBound=yes}
    setup_index
    ::Checks::validate_curley_shuffle
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
