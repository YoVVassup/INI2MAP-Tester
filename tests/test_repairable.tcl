#----------------------------------------------------------------------------------------------------------
# test_repairable.tcl - Unit tests for checks/repairable.tcl
# Tests: Repairable=no with Capturable=yes conflict
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "repairable.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::buildings
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: Repairable=no + Capturable=yes — should warn
# --------------------------------------------------------------------------
test rep-conflict "Repairable=no + Capturable=yes warns" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) [list "Repairable=no" "Capturable=yes"]
    setup_index
    ::Checks::validate_repairable
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Repairable=no + Capturable=no — should pass
# --------------------------------------------------------------------------
test rep-no-conflict "Repairable=no + Capturable=no is OK" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) [list "Repairable=no" "Capturable=no"]
    setup_index
    ::Checks::validate_repairable
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Repairable=yes + Capturable=yes — should pass
# --------------------------------------------------------------------------
test rep-repairable "Repairable=yes + Capturable=yes is OK" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) [list "Repairable=yes" "Capturable=yes"]
    setup_index
    ::Checks::validate_repairable
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
