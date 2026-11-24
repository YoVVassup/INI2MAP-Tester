#----------------------------------------------------------------------------------------------------------
# test_unit_absorb_dock_unload.tcl - Unit tests for checks/unit_absorb_dock_unload.tcl
# Tests: UnitAbsorb=yes + DockUnload=yes detection
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
source [file join $script_dir "checks" "unit_absorb_dock_unload.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
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
# Test 1: UnitAbsorb=yes + DockUnload=yes in YR — should warn
# --------------------------------------------------------------------------
test uadu-warn "UnitAbsorb+DockUnload in YR warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(BR) ""
    set ::Data::rawmapdata(BR) {UnitAbsorb=yes DockUnload=yes}
    setup_index
    ::Checks::validate_unit_absorb_dock_unload
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: UnitAbsorb=yes + DockUnload=no — should pass
# --------------------------------------------------------------------------
test uadu-no-dock "UnitAbsorb+DockUnload=no is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(BR) ""
    set ::Data::rawmapdata(BR) {UnitAbsorb=yes DockUnload=no}
    setup_index
    ::Checks::validate_unit_absorb_dock_unload
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: UnitAbsorb=no + DockUnload=yes — should pass
# --------------------------------------------------------------------------
test uadu-no-absorb "UnitAbsorb=no is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(BR) ""
    set ::Data::rawmapdata(BR) {UnitAbsorb=no DockUnload=yes}
    setup_index
    ::Checks::validate_unit_absorb_dock_unload
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: In RA2 — should pass (bug only in YR+)
# --------------------------------------------------------------------------
test uadu-ra2 "RA2 mode skips check" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::buildings(BR) ""
    set ::Data::rawmapdata(BR) {UnitAbsorb=yes DockUnload=yes}
    setup_index
    ::Checks::validate_unit_absorb_dock_unload
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: In Ares — should warn
# --------------------------------------------------------------------------
test uadu-ares "Ares mode checks" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::buildings(BR) ""
    set ::Data::rawmapdata(BR) {UnitAbsorb=yes DockUnload=yes}
    setup_index
    ::Checks::validate_unit_absorb_dock_unload
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
