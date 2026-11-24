#----------------------------------------------------------------------------------------------------------
# test_unit_repair_building.tcl - Unit tests for checks/unit_repair_building.tcl
# Tests: UnitRepair=yes on BuildingTypes detection
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
source [file join $script_dir "checks" "unit_repair_building.tcl"]

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
# Test 1: UnitRepair=yes on airpad — should warn
# --------------------------------------------------------------------------
test urb-airpad "UnitRepair+airpad warns" -body {
    reset_state
    set ::Data::buildings(AF) ""
    set ::Data::rawmapdata(AF) {UnitRepair=yes Dock=yes}
    setup_index
    ::Checks::validate_unit_repair_building
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: UnitRepair=yes on non-airpad — should notice
# --------------------------------------------------------------------------
test urb-nonpad "UnitRepair+non-airpad notices" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {UnitRepair=yes}
    setup_index
    ::Checks::validate_unit_repair_building
    expr {$::Logging::notice_count > 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: UnitRepair=no — should pass
# --------------------------------------------------------------------------
test urb-no "UnitRepair=no is OK" -body {
    reset_state
    set ::Data::buildings(AF) ""
    set ::Data::rawmapdata(AF) {UnitRepair=no Dock=yes}
    setup_index
    ::Checks::validate_unit_repair_building
    expr {$::Logging::warning_count == 0 && $::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: UnitRepair=yes + AirportBound — should warn
# --------------------------------------------------------------------------
test urb-airport "UnitRepair+AirportBound warns" -body {
    reset_state
    set ::Data::buildings(AF) ""
    set ::Data::rawmapdata(AF) {UnitRepair=yes AirportBound=yes}
    setup_index
    ::Checks::validate_unit_repair_building
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: UnitRepair=yes + Fighter — should warn
# --------------------------------------------------------------------------
test urb-fighter "UnitRepair+Fighter warns" -body {
    reset_state
    set ::Data::buildings(AF) ""
    set ::Data::rawmapdata(AF) {UnitRepair=yes Fighter=yes}
    setup_index
    ::Checks::validate_unit_repair_building
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
