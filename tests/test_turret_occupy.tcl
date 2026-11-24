#----------------------------------------------------------------------------------------------------------
# test_turret_occupy.tcl - Unit tests for checks/turret_occupy.tcl
# Tests: Turret=yes + CanBeOccupied=yes detection
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
source [file join $script_dir "checks" "turret_occupy.tcl"]

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
# Test 1: Turret=yes + CanBeOccupied=yes — should warn
# --------------------------------------------------------------------------
test to-warn "Turret=yes + CanBeOccupied=yes warns" -body {
    reset_state
    set ::Data::buildings(PILL) ""
    set ::Data::rawmapdata(PILL) {Turret=yes CanBeOccupied=yes}
    setup_index
    ::Checks::validate_turret_occupy
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Turret=no + CanBeOccupied=yes — should pass
# --------------------------------------------------------------------------
test to-no-turret "Turret=no + CanBeOccupied=yes is OK" -body {
    reset_state
    set ::Data::buildings(PILL) ""
    set ::Data::rawmapdata(PILL) {Turret=no CanBeOccupied=yes}
    setup_index
    ::Checks::validate_turret_occupy
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Turret=yes + CanBeOccupied=no — should pass
# --------------------------------------------------------------------------
test to-no-occupy "Turret=yes + CanBeOccupied=no is OK" -body {
    reset_state
    set ::Data::buildings(PILL) ""
    set ::Data::rawmapdata(PILL) {Turret=yes CanBeOccupied=no}
    setup_index
    ::Checks::validate_turret_occupy
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No Turret, no CanBeOccupied — should pass
# --------------------------------------------------------------------------
test to-neither "Neither flag is OK" -body {
    reset_state
    set ::Data::buildings(PILL) ""
    set ::Data::rawmapdata(PILL) {Strength=1000}
    setup_index
    ::Checks::validate_turret_occupy
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Multiple buildings, one bad — 1 warning
# --------------------------------------------------------------------------
test to-mixed "Only one bad building warns once" -body {
    reset_state
    set ::Data::buildings(PILL) ""
    set ::Data::rawmapdata(PILL) {Turret=yes CanBeOccupied=yes}
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {Turret=no CanBeOccupied=no}
    setup_index
    ::Checks::validate_turret_occupy
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
