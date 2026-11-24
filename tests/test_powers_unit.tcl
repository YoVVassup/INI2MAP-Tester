#----------------------------------------------------------------------------------------------------------
# test_powers_unit.tcl - Unit tests for checks/powers_unit.tcl
# Tests: PowersUnit=yes on multiple building types owned by same house
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "powers_unit.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::buildings
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
# Test 1: Multiple PowersUnit building types — should warn
# --------------------------------------------------------------------------
test pu-multi-types "Multiple PowersUnit building types warns" -body {
    reset_state
    set ::Data::buildings(POWR1) ""
    set ::Data::rawmapdata(POWR1) {PowersUnit=yes}
    set ::Data::buildings(POWR2) ""
    set ::Data::rawmapdata(POWR2) {PowersUnit=yes}
    setup_index
    ::Checks::validate_powers_unit
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Single PowersUnit building type — should pass
# --------------------------------------------------------------------------
test pu-single "Single PowersUnit type is OK" -body {
    reset_state
    set ::Data::buildings(POWR1) ""
    set ::Data::rawmapdata(POWR1) {PowersUnit=yes}
    setup_index
    ::Checks::validate_powers_unit
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: PowersUnit=yes in RA2 — should pass (flag doesn't exist)
# --------------------------------------------------------------------------
test pu-ra2 "PowersUnit in RA2 is ignored" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::buildings(POWR1) ""
    set ::Data::rawmapdata(POWR1) {PowersUnit=yes}
    setup_index
    ::Checks::validate_powers_unit
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
