#----------------------------------------------------------------------------------------------------------
# test_walk_rate_zero.tcl - Unit tests for checks/walk_rate_zero.tcl
# Tests: WalkRate=0 crash detection
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
source [file join $script_dir "checks" "walk_rate_zero.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
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
# Test 1: WalkRate=0 infantry — should error
# --------------------------------------------------------------------------
test wrz-infantry "WalkRate=0 infantry errors" -body {
    reset_state
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {WalkRate=0}
    setup_index
    ::Checks::validate_walk_rate_zero
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: WalkRate=0 vehicle — should error
# --------------------------------------------------------------------------
test wrz-vehicle "WalkRate=0 vehicle errors" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {WalkRate=0}
    setup_index
    ::Checks::validate_walk_rate_zero
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: WalkRate=1 — should pass
# --------------------------------------------------------------------------
test wrz-ok "WalkRate=1 is OK" -body {
    reset_state
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {WalkRate=1}
    setup_index
    ::Checks::validate_walk_rate_zero
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No WalkRate — should pass
# --------------------------------------------------------------------------
test wrz-none "No WalkRate is OK" -body {
    reset_state
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {Strength=100}
    setup_index
    ::Checks::validate_walk_rate_zero
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: WalkRate=999 (high value to prevent animation) — should pass
# --------------------------------------------------------------------------
test wrz-high "WalkRate=999 is OK" -body {
    reset_state
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {WalkRate=999}
    setup_index
    ::Checks::validate_walk_rate_zero
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
