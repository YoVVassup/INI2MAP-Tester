#----------------------------------------------------------------------------------------------------------
# test_powered_unit.tcl - Unit tests for checks/powered_unit.tcl
# Tests: PoweredUnit=yes on vehicles with incompatible locomotors
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "powered_unit.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::vehicles
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
# Test 1: PoweredUnit=yes with Rocket locomotor — should warn
# --------------------------------------------------------------------------
test pu-rocket "PoweredUnit=yes with Rocket locomotor warns" -body {
    reset_state
    set ::Data::vehicles(MISSILE) ""
    set ::Data::rawmapdata(MISSILE) [list "PoweredUnit=yes" "Locomotor={B7B49766-E576-11d3-9BD9-00104B972FE8}"]
    setup_index
    ::Checks::validate_powered_unit
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: PoweredUnit=yes with normal locomotor — should pass
# --------------------------------------------------------------------------
test pu-normal "PoweredUnit=yes with normal locomotor is OK" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) [list "PoweredUnit=yes" "Locomotor={4A582743-9839-11d1-B709-00A024DDAFD1}"]
    setup_index
    ::Checks::validate_powered_unit
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: PoweredUnit=yes in RA2 — should pass (flag doesn't exist)
# --------------------------------------------------------------------------
test pu-ra2 "PoweredUnit in RA2 is ignored" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {PoweredUnit=yes}
    setup_index
    ::Checks::validate_powered_unit
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
