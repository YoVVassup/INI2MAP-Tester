#----------------------------------------------------------------------------------------------------------
# test_selfheal_frames.tcl - Unit tests for checks/selfheal_frames.tcl
# Tests: SelfHealInfantryFrames/SelfHealUnitFrames value validation
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "selfheal_frames.tcl"]

proc reset_state {} {
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
# Test 1: Valid frames values — should pass
# --------------------------------------------------------------------------
test shf-valid "Valid frames values are OK" -body {
    reset_state
    set ::Data::rawmapdata(General) {SelfHealInfantryFrames=50 SelfHealUnitFrames=75}
    setup_index
    ::Checks::validate_selfheal_frames
    expr {$::Logging::error_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: SelfHealInfantryFrames=3 (low value) — should warn
# --------------------------------------------------------------------------
test shf-low-infantry "Low SelfHealInfantryFrames warns" -body {
    reset_state
    set ::Data::rawmapdata(General) {SelfHealInfantryFrames=3}
    setup_index
    ::Checks::validate_selfheal_frames
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Non-integer value — should warn
# --------------------------------------------------------------------------
test shf-non-integer "Non-integer value warns" -body {
    reset_state
    set ::Data::rawmapdata(General) {SelfHealInfantryFrames=abc}
    setup_index
    ::Checks::validate_selfheal_frames
    expr {$::Logging::warning_count > 0}
} -result 1

reset_state
cleanupTests
