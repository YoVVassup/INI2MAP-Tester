#----------------------------------------------------------------------------------------------------------
# test_veteran_level_reinforcement.tcl - Unit tests for checks/veteran_level_reinforcement.tcl
# Tests: VeteranLevel on TeamTypes reinforcement override
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
source [file join $script_dir "checks" "veteran_level_reinforcement.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::teamtypes
    array unset ::Data::rawmapdata
    set ::Data::gamemode "yr"
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

# --------------------------------------------------------------------------
# Test 1: VeteranLevel=1 in YR — should warn
# --------------------------------------------------------------------------
test vlr-warn "VeteranLevel=1 in YR warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) {VeteranLevel=1 TaskForce=TF1}
    ::Checks::validate_veteran_level_reinforcement
    expr {$::Logging::notice_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: VeteranLevel=0 — should pass (default)
# --------------------------------------------------------------------------
test vlr-default "VeteranLevel=0 is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) {VeteranLevel=0 TaskForce=TF1}
    ::Checks::validate_veteran_level_reinforcement
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: No VeteranLevel — should pass
# --------------------------------------------------------------------------
test vlr-none "No VeteranLevel is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) {TaskForce=TF1}
    ::Checks::validate_veteran_level_reinforcement
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: VeteranLevel=2 in Phobos — should pass (fixed)
# --------------------------------------------------------------------------
test vlr-phobos "VeteranLevel in Phobos is OK (fixed)" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) {VeteranLevel=2 TaskForce=TF1}
    ::Checks::validate_veteran_level_reinforcement
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
