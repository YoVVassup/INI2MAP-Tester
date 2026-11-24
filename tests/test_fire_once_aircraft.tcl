package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks fire_once_aircraft.tcl]

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

test fo-fireonce "FireOnce=yes on aircraft warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(BOMB) ""
    set ::Data::rawmapdata(BOMB) {FireOnce=yes}
    setup_index
    ::Checks::validate_fire_once_aircraft
    expr {$::Logging::error_count > 0}
} -result 1

test fo-clean "FireOnce=no no error" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(BOMB) ""
    set ::Data::rawmapdata(BOMB) {FireOnce=no}
    setup_index
    ::Checks::validate_fire_once_aircraft
    expr {$::Logging::error_count == 0}
} -result 1

test fo-ra2 "FireOnce=yes in RA2 warns" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::aircraft(BOMB) ""
    set ::Data::rawmapdata(BOMB) {FireOnce=yes}
    setup_index
    ::Checks::validate_fire_once_aircraft
    expr {$::Logging::error_count > 0}
} -result 1

reset_state
cleanupTests
