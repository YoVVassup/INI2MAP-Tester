#----------------------------------------------------------------------------------------------------------
# test_taskforce_duplicates.tcl - Unit tests for checks/taskforce_duplicates.tcl
# Tests: Duplicate unit type detection in TaskForces
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
source [file join $script_dir "checks" "taskforce_duplicates.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::taskforces
    array unset ::Data::rawmapdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
}

# --------------------------------------------------------------------------
# Test 1: No duplicates — should pass
# --------------------------------------------------------------------------
test tfdup-no-dupes "No duplicate unit types" -body {
    reset_state
    set ::Data::taskforces(TF1) ""
    set ::Data::rawmapdata(TF1) {
        0=2,GrizzlyTank
        1=1,IFV
        Name=Test TaskForce
        Group=0
    }
    ::Checks::validate_taskforce_duplicates
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Duplicate unit type — should error
# --------------------------------------------------------------------------
test tfdup-with-dupes "Duplicate unit types detected" -body {
    reset_state
    set ::Data::taskforces(TF2) ""
    set ::Data::rawmapdata(TF2) {
        0=2,GrizzlyTank
        1=1,IFV
        2=1,GrizzlyTank
        Name=Dupe TaskForce
        Group=0
    }
    ::Checks::validate_taskforce_duplicates
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Same type in different taskforces — should pass
# --------------------------------------------------------------------------
test tfdup-diff-tf "Same type in different taskforces is OK" -body {
    reset_state
    set ::Data::taskforces(TF3) ""
    set ::Data::taskforces(TF4) ""
    set ::Data::rawmapdata(TF3) {0=2,GrizzlyTank Name=TF3 Group=0}
    set ::Data::rawmapdata(TF4) {0=3,GrizzlyTank Name=TF4 Group=0}
    ::Checks::validate_taskforce_duplicates
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: Empty taskforce — should pass
# --------------------------------------------------------------------------
test tfdup-empty "Empty taskforce is OK" -body {
    reset_state
    set ::Data::taskforces(TF5) ""
    set ::Data::rawmapdata(TF5) {Name=Empty Group=-1}
    ::Checks::validate_taskforce_duplicates
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Only Name/Group lines — should pass
# --------------------------------------------------------------------------
test tfdup-only-meta "Only Name/Group lines are OK" -body {
    reset_state
    set ::Data::taskforces(TF6) ""
    set ::Data::rawmapdata(TF6) {Name=Meta Group=0}
    ::Checks::validate_taskforce_duplicates
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 6: Multiple duplicates — should error once per type
# --------------------------------------------------------------------------
test tfdup-multi-dupes "Multiple duplicate types each error once" -body {
    reset_state
    set ::Data::taskforces(TF7) ""
    set ::Data::rawmapdata(TF7) {
        0=2,GrizzlyTank
        1=1,IFV
        2=1,GrizzlyTank
        3=3,IFV
        Name=Multi Dupe TF
        Group=0
    }
    ::Checks::validate_taskforce_duplicates
    expr {$::Logging::error_count == 2}
} -result 1

# --------------------------------------------------------------------------
# Test 7: No rawmapdata for taskforce — should skip
# --------------------------------------------------------------------------
test tfdup-no-raw "Missing rawmapdata is skipped" -body {
    reset_state
    set ::Data::taskforces(TF8) ""
    ::Checks::validate_taskforce_duplicates
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
