#----------------------------------------------------------------------------------------------------------
# test_airport_bound.tcl - Unit tests for checks/airport_bound.tcl
# Tests: AirportBound=no on buildable aircraft detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks airport_bound.tcl]

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

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: Buildable aircraft with AirportBound=no — should warn
# --------------------------------------------------------------------------
test ab-buildable "Buildable aircraft AirportBound=no warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(HELI) ""
    set ::Data::rawmapdata(AircraftTypes) {0=HELI}
    set ::Data::rawmapdata(HELI) {AirportBound=no Factory=NavalYard}
    setup_index
    ::Checks::validate_airport_bound
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Non-buildable aircraft with AirportBound=no — should warn (less)
# --------------------------------------------------------------------------
test ab-nonbuild "Non-buildable aircraft AirportBound=no warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(HELI) ""
    set ::Data::rawmapdata(AircraftTypes) {0=HELI}
    set ::Data::rawmapdata(HELI) {AirportBound=no}
    setup_index
    ::Checks::validate_airport_bound
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: AirportBound=yes — should pass
# --------------------------------------------------------------------------
test ab-yes "AirportBound=yes is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(HELI) ""
    set ::Data::rawmapdata(AircraftTypes) {0=HELI}
    set ::Data::rawmapdata(HELI) {AirportBound=yes}
    setup_index
    ::Checks::validate_airport_bound
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
