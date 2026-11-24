#----------------------------------------------------------------------------------------------------------
# test_number_of_docks.tcl - Unit tests for checks/number_of_docks.tcl
# Tests: NumberOfDocks flag validation on buildings
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "number_of_docks.tcl"]

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
# Test 1: NumberOfDocks not set — should pass
# --------------------------------------------------------------------------
test nod-none "No NumberOfDocks set" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {Power=100}
    setup_index
    ::Checks::validate_number_of_docks
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: NumberOfDocks=2 on non-Helipad building — should warn
# --------------------------------------------------------------------------
test nod-non-helipad "NumberOfDocks=2 without Helipad warns" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {NumberOfDocks=2}
    setup_index
    ::Checks::validate_number_of_docks
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: NumberOfDocks=2 on Helipad — should pass
# --------------------------------------------------------------------------
test nod-helipad "NumberOfDocks=2 on Helipad is OK" -body {
    reset_state
    set ::Data::buildings(HPAD) ""
    set ::Data::rawmapdata(HPAD) [list "NumberOfDocks=2" "Helipad=yes"]
    setup_index
    ::Checks::validate_number_of_docks
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
