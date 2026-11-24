#----------------------------------------------------------------------------------------------------------
# test_shake_screen.tcl - Unit tests for checks/shake_screen.tcl
# Tests: ShakeScreen value validation in AudioVisual
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "shake_screen.tcl"]

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
# Test 1: ShakeScreen not set — should pass
# --------------------------------------------------------------------------
test ss-none "ShakeScreen not set is OK" -body {
    reset_state
    set ::Data::rawmapdata(AudioVisual) {SomeOther=1}
    setup_index
    ::Checks::validate_shake_screen
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: ShakeScreen=100 — should pass (valid value)
# --------------------------------------------------------------------------
test ss-valid "ShakeScreen=100 is OK" -body {
    reset_state
    set ::Data::rawmapdata(AudioVisual) {ShakeScreen=100}
    setup_index
    ::Checks::validate_shake_screen
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: ShakeScreen in non-RA2/YR mode — should pass (check skipped)
# --------------------------------------------------------------------------
test ss-ares-mode "ShakeScreen in Ares mode is skipped" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::rawmapdata(AudioVisual) {ShakeScreen=0}
    setup_index
    ::Checks::validate_shake_screen
    expr {$::Logging::error_count == 0}
} -result 1

reset_state
cleanupTests
