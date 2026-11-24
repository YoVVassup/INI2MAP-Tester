#----------------------------------------------------------------------------------------------------------
# test_cloak_stop.tcl - Unit tests for checks/cloak_stop.tcl
# Tests: CloakStop + conflicting flags detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks cloak_stop.tcl]

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
# Test 1: CloakStop=yes + BalloonHover=yes — should warn
# --------------------------------------------------------------------------
test cs-balloon "CloakStop+BalloonHover warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(FTANK) ""
    set ::Data::rawmapdata(VehicleTypes) {0=FTANK}
    set ::Data::rawmapdata(FTANK) {CloakStop=yes BalloonHover=yes}
    setup_index
    ::Checks::validate_cloak_stop
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: CloakStop=yes + IsSimpleDeployer=yes — should warn
# --------------------------------------------------------------------------
test cs-deployer "CloakStop+Deployer warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(FTANK) ""
    set ::Data::rawmapdata(VehicleTypes) {0=FTANK}
    set ::Data::rawmapdata(FTANK) {CloakStop=yes IsSimpleDeployer=yes}
    setup_index
    ::Checks::validate_cloak_stop
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: CloakStop=yes alone — should pass
# --------------------------------------------------------------------------
test cs-clean "CloakStop alone is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(FTANK) ""
    set ::Data::rawmapdata(VehicleTypes) {0=FTANK}
    set ::Data::rawmapdata(FTANK) {CloakStop=yes}
    setup_index
    ::Checks::validate_cloak_stop
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
