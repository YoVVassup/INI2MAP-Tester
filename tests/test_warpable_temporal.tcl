#----------------------------------------------------------------------------------------------------------
# test_warpable_temporal.tcl - Unit tests for checks/warpable_temporal.tcl
# Tests: Warpable=no side effects in RA2/YR
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
source [file join $script_dir "checks" "warpable_temporal.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::buildings
    array unset ::Data::rawmapdata
    set ::Data::gamemode "yr"
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: Warpable=no in YR — should warn
# --------------------------------------------------------------------------
test wt-yr "Warpable=no in YR warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {Warpable=no}
    setup_index
    ::Checks::validate_warpable_temporal
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Warpable=yes — should pass
# --------------------------------------------------------------------------
test wt-yes "Warpable=yes is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {Warpable=yes}
    setup_index
    ::Checks::validate_warpable_temporal
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Warpable=no in Ares — should pass (fixed)
# --------------------------------------------------------------------------
test wt-ares "Warpable=no in Ares is OK (fixed)" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {Warpable=no}
    setup_index
    ::Checks::validate_warpable_temporal
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No Warpable — should pass
# --------------------------------------------------------------------------
test wt-none "No Warpable is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {Strength=1000}
    setup_index
    ::Checks::validate_warpable_temporal
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
