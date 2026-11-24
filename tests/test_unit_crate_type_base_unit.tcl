#----------------------------------------------------------------------------------------------------------
# test_unit_crate_type_base_unit.tcl - Unit tests for checks/unit_crate_type_base_unit.tcl
# Tests: UnitCrateType vs BaseUnit mismatch detection
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
source [file join $script_dir "checks" "unit_crate_type_base_unit.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::rulesdata
    array unset ::Data::rawmapdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: UnitCrateType != BaseUnit — should warn
# --------------------------------------------------------------------------
test uctbu-mismatch "UnitCrateType != BaseUnit warns" -body {
    reset_state
    set ::Data::rulesdata(CrateRules) {UnitCrateType=JEEP}
    set ::Data::rulesdata(General) {BaseUnit=MCV}
    ::Checks::build_index
    ::Checks::validate_unit_crate_type_base_unit
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: UnitCrateType == BaseUnit — should pass
# --------------------------------------------------------------------------
test uctbu-match "UnitCrateType == BaseUnit is OK" -body {
    reset_state
    set ::Data::rulesdata(CrateRules) {UnitCrateType=MCV}
    set ::Data::rulesdata(General) {BaseUnit=MCV}
    ::Checks::build_index
    ::Checks::validate_unit_crate_type_base_unit
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: No UnitCrateType — should pass
# --------------------------------------------------------------------------
test uctbu-none "No UnitCrateType is OK" -body {
    reset_state
    set ::Data::rulesdata(CrateRules) {MoneyCrate=1000}
    set ::Data::rulesdata(General) {BaseUnit=MCV}
    ::Checks::build_index
    ::Checks::validate_unit_crate_type_base_unit
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: UnitCrateType set but no BaseUnit — should warn
# --------------------------------------------------------------------------
test uctbu-no-base "UnitCrateType without BaseUnit warns" -body {
    reset_state
    set ::Data::rulesdata(CrateRules) {UnitCrateType=MCV}
    ::Checks::build_index
    ::Checks::validate_unit_crate_type_base_unit
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Case-insensitive comparison — should pass
# --------------------------------------------------------------------------
test uctbu-case "Case-insensitive match is OK" -body {
    reset_state
    set ::Data::rulesdata(CrateRules) {UnitCrateType=mcv}
    set ::Data::rulesdata(General) {BaseUnit=MCV}
    ::Checks::build_index
    ::Checks::validate_unit_crate_type_base_unit
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
