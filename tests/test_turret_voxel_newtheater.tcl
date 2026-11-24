#----------------------------------------------------------------------------------------------------------
# test_turret_voxel_newtheater.tcl - Unit tests for checks/turret_voxel_newtheater.tcl
# Tests: TurretAnimIsVoxel=yes + NewTheater detection
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
source [file join $script_dir "checks" "turret_voxel_newtheater.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::buildings
    array unset ::Data::rawmapdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: TurretAnimIsVoxel=yes without NewTheater — should warn
# --------------------------------------------------------------------------
test tvn-warn "TurretAnimIsVoxel=yes without NewTheater warns" -body {
    reset_state
    set ::Data::buildings(TWR) ""
    set ::Data::rawmapdata(TWR) {TurretAnimIsVoxel=yes NewTheater=no}
    setup_index
    ::Checks::validate_turret_voxel_newtheater
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: TurretAnimIsVoxel=yes with NewTheater=yes — should pass
# --------------------------------------------------------------------------
test tvn-ok "TurretAnimIsVoxel=yes with NewTheater=yes is OK" -body {
    reset_state
    set ::Data::buildings(TWR) ""
    set ::Data::rawmapdata(TWR) {TurretAnimIsVoxel=yes NewTheater=yes}
    setup_index
    ::Checks::validate_turret_voxel_newtheater
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: TurretAnimIsVoxel=no — should pass
# --------------------------------------------------------------------------
test tvn-no-voxel "TurretAnimIsVoxel=no is OK" -body {
    reset_state
    set ::Data::buildings(TWR) ""
    set ::Data::rawmapdata(TWR) {TurretAnimIsVoxel=no}
    setup_index
    ::Checks::validate_turret_voxel_newtheater
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No TurretAnimIsVoxel property — should pass
# --------------------------------------------------------------------------
test tvn-none "No TurretAnimIsVoxel is OK" -body {
    reset_state
    set ::Data::buildings(TWR) ""
    set ::Data::rawmapdata(TWR) {Strength=1000}
    setup_index
    ::Checks::validate_turret_voxel_newtheater
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Multiple buildings, one bad — 1 warning
# --------------------------------------------------------------------------
test tvn-mixed "Only one bad building warns once" -body {
    reset_state
    set ::Data::buildings(TWR) ""
    set ::Data::rawmapdata(TWR) {TurretAnimIsVoxel=yes NewTheater=no}
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {TurretAnimIsVoxel=yes NewTheater=yes}
    setup_index
    ::Checks::validate_turret_voxel_newtheater
    expr {$::Logging::warning_count == 1}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
