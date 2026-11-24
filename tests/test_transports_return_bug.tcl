#----------------------------------------------------------------------------------------------------------
# test_transports_return_bug.tcl - Unit tests for checks/transports_return_bug.tcl
# Tests: TransportsReturnOnUnload + Size=1 passenger detection
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
source [file join $script_dir "checks" "transports_return_bug.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::teamtypes
    array unset ::Data::taskforces
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
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
# Test 1: TransportsReturnOnUnload=yes with Size=1 passenger — should warn
# --------------------------------------------------------------------------
test trb-warn "TransportsReturnOnUnload with Size=1 warns" -body {
    reset_state
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) {TransportsReturnOnUnload=yes TaskForce=TF1}
    set ::Data::taskforces(TF1) ""
    set ::Data::rawmapdata(TF1) {0=2,CHIN Name=Chinook Group=0}
    set ::Data::vehicles(CHIN) ""
    set ::Data::rawmapdata(CHIN) {Passengers=10}
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {Size=1}
    setup_index
    ::Checks::validate_transports_return_bug
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: TransportsReturnOnUnload=no — should pass
# --------------------------------------------------------------------------
test trb-no-flag "TransportsReturnOnUnload=no is OK" -body {
    reset_state
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) {TransportsReturnOnUnload=no TaskForce=TF1}
    set ::Data::taskforces(TF1) ""
    set ::Data::rawmapdata(TF1) {0=2,CHIN Name=Chinook Group=0}
    set ::Data::vehicles(CHIN) ""
    set ::Data::rawmapdata(CHIN) {Passengers=10}
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {Size=1}
    setup_index
    ::Checks::validate_transports_return_bug
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: No Size=1 infantry — should pass
# --------------------------------------------------------------------------
test trb-no-size1 "No Size=1 units is OK" -body {
    reset_state
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) {TransportsReturnOnUnload=yes TaskForce=TF1}
    set ::Data::taskforces(TF1) ""
    set ::Data::rawmapdata(TF1) {0=2,CHIN Name=Chinook Group=0}
    set ::Data::vehicles(CHIN) ""
    set ::Data::rawmapdata(CHIN) {Passengers=10}
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {Size=2}
    setup_index
    ::Checks::validate_transports_return_bug
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No TaskForce — should pass
# --------------------------------------------------------------------------
test trb-no-tf "Missing TaskForce is OK" -body {
    reset_state
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) {TransportsReturnOnUnload=yes TaskForce=MISSING}
    setup_index
    ::Checks::validate_transports_return_bug
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Non-transport unit in TaskForce — should pass
# --------------------------------------------------------------------------
test trb-non-transport "Non-transport unit is OK" -body {
    reset_state
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) {TransportsReturnOnUnload=yes TaskForce=TF1}
    set ::Data::taskforces(TF1) ""
    set ::Data::rawmapdata(TF1) {0=5,GI Name=GI Squad Group=0}
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {Size=1}
    setup_index
    ::Checks::validate_transports_return_bug
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
