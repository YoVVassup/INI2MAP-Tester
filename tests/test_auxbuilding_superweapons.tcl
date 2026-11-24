#----------------------------------------------------------------------------------------------------------
# test_auxbuilding_superweapons.tcl - Unit tests for checks/auxbuilding_superweapons.tcl
# Tests: SuperWeapon AuxBuilding reference validation
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks auxbuilding_superweapons.tcl]

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
    array unset ::Data::rulesdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: AuxBuilding references invalid building — should warn
# --------------------------------------------------------------------------
test asw-invalid "Invalid AuxBuilding warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::rawmapdata(SuperWeaponTypes) {0=MYSW}
    set ::Data::rawmapdata(MYSW) {AuxBuilding=NOEXIST}
    setup_index
    ::Checks::validate_auxbuilding_superweapons
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: AuxBuilding references valid building — should warn (info about upgrade bypass)
# --------------------------------------------------------------------------
test asw-valid "Valid AuxBuilding warns about upgrade bypass" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(PYLE) ""
    set ::Data::rawmapdata(BuildingTypes) {0=PYLE}
    set ::Data::rawmapdata(SuperWeaponTypes) {0=MYSW}
    set ::Data::rawmapdata(MYSW) {AuxBuilding=PYLE}
    setup_index
    ::Checks::validate_auxbuilding_superweapons
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: No AuxBuilding set — should pass
# --------------------------------------------------------------------------
test asw-none "No AuxBuilding is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::rawmapdata(SuperWeaponTypes) {0=MYSW}
    set ::Data::rawmapdata(MYSW) {SomeProp=value}
    setup_index
    ::Checks::validate_auxbuilding_superweapons
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
