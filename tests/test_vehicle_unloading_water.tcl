#----------------------------------------------------------------------------------------------------------
# test_vehicle_unloading_water.tcl - Unit tests for checks/vehicle_unloading_water.tcl
# Tests: UnloadingClass without Dock+Deployer detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

# --------------------------------------------------------------------------
# Source required modules
# --------------------------------------------------------------------------
set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "vehicle_unloading_water.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::vehicles
    array unset ::Data::rawmapdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# === UnloadingClass tests ===

# --------------------------------------------------------------------------
# Test 1: UnloadingClass without Dock or Deployer — should notice
# --------------------------------------------------------------------------
test vuw-uc-nodock "UnloadingClass without Dock or Deployer notices" -body {
    reset_state
    set ::Data::vehicles(TRUCK) ""
    set ::Data::rawmapdata(TRUCK) {UnloadingClass=MCV}
    setup_index
    ::Checks::validate_vehicle_unloading_water
    expr {$::Logging::notice_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: UnloadingClass with Dock=yes — should pass (has Dock)
# --------------------------------------------------------------------------
test vuw-uc-dock "UnloadingClass+Dock=yes is OK" -body {
    reset_state
    set ::Data::vehicles(DNDR) ""
    set ::Data::rawmapdata(DNDR) {UnloadingClass=MCV Dock=yes}
    setup_index
    ::Checks::validate_vehicle_unloading_water
    expr {$::Logging::notice_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: UnloadingClass with IsSimpleDeployer=yes — should pass
# --------------------------------------------------------------------------
test vuw-uc-deployer "UnloadingClass+Deployer=yes is OK" -body {
    reset_state
    set ::Data::vehicles(DNDR) ""
    set ::Data::rawmapdata(DNDR) {UnloadingClass=MCV IsSimpleDeployer=yes}
    setup_index
    ::Checks::validate_vehicle_unloading_water
    expr {$::Logging::notice_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No UnloadingClass — should pass
# --------------------------------------------------------------------------
test vuw-none "No UnloadingClass is OK" -body {
    reset_state
    set ::Data::vehicles(TRUCK) ""
    set ::Data::rawmapdata(TRUCK) {Strength=1000}
    setup_index
    ::Checks::validate_vehicle_unloading_water
    expr {$::Logging::notice_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
