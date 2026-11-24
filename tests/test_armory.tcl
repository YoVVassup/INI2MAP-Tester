#----------------------------------------------------------------------------------------------------------
# test_armory.tcl - Unit tests for checks/armory.tcl
# Tests: Armory=yes building configuration validation
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks armory.tcl]

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
# Test 1: Armory=yes + ConstructionYard=yes — should error
# --------------------------------------------------------------------------
test arm-conyard "Armory+ConstructionYard errors" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(BARR) ""
    set ::Data::rawmapdata(BuildingTypes) {0=BARR}
    set ::Data::rawmapdata(BARR) {Armory=yes ConstructionYard=yes}
    setup_index
    ::Checks::validate_armory
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Armory=yes without Ammo — should warn
# --------------------------------------------------------------------------
test arm-no-ammo "Armory without Ammo warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(BARR) ""
    set ::Data::rawmapdata(BuildingTypes) {0=BARR}
    set ::Data::rawmapdata(BARR) {Armory=yes}
    setup_index
    ::Checks::validate_armory
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Armory=yes with Ammo and no weapon — should pass (info only)
# --------------------------------------------------------------------------
test arm-clean "Armory with Ammo is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(BARR) ""
    set ::Data::rawmapdata(BuildingTypes) {0=BARR}
    set ::Data::rawmapdata(BARR) {Armory=yes Ammo=999}
    setup_index
    ::Checks::validate_armory
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
