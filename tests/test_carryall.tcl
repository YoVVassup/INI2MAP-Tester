#----------------------------------------------------------------------------------------------------------
# test_carryall.tcl - Unit tests for checks/carryall.tcl
# Tests: Carryall aircraft airlift validation
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks carryall.tcl]

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
# Test 1: Carryall + watercraft — should warn
# --------------------------------------------------------------------------
test ca-water "Carryall+watercraft warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(CARRY) ""
    set ::Data::rawmapdata(AircraftTypes) {0=CARRY}
    set ::Data::rawmapdata(CARRY) {Carryall=yes}
    set ::Data::vehicles(BOAT) ""
    set ::Data::rawmapdata(VehicleTypes) {0=BOAT}
    set ::Data::rawmapdata(BOAT) {MovementZone=Water}
    setup_index
    ::Checks::validate_carryall
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Carryall without watercraft — should pass
# --------------------------------------------------------------------------
test ca-land "Carryall+land vehicles OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(CARRY) ""
    set ::Data::rawmapdata(AircraftTypes) {0=CARRY}
    set ::Data::rawmapdata(CARRY) {Carryall=yes}
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(VehicleTypes) {0=TANK}
    set ::Data::rawmapdata(TANK) {MovementZone=Default}
    setup_index
    ::Checks::validate_carryall
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Non-carryall aircraft — should pass
# --------------------------------------------------------------------------
test ca-none "Non-carryall aircraft is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(JET) ""
    set ::Data::rawmapdata(AircraftTypes) {0=JET}
    set ::Data::rawmapdata(JET) {Carryall=no}
    setup_index
    ::Checks::validate_carryall
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
