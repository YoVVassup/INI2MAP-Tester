#----------------------------------------------------------------------------------------------------------
# test_thief_guard_mode.tcl - Unit tests for checks/thief_guard_mode.tcl
# Tests: Thief=yes guard mode detection
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
source [file join $script_dir "checks" "thief_guard_mode.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::infantry
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

proc set_raw {section line} {
    set ::Data::rawmapdata($section) [list $line]
}

# --------------------------------------------------------------------------
# Test 1: Thief=yes in YR — should warn
# --------------------------------------------------------------------------
test tgm-yr-yes "Thief=yes in YR warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(DOG) ""
    set_raw DOG {Thief=yes}
    setup_index
    ::Checks::validate_thief_guard_mode
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Thief=no in YR — should pass
# --------------------------------------------------------------------------
test tgm-yr-no "Thief=no in YR is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(DOG) ""
    set_raw DOG {Thief=no}
    setup_index
    ::Checks::validate_thief_guard_mode
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Thief=yes in RA2 — should pass (bug only in YR+)
# --------------------------------------------------------------------------
test tgm-ra2-yes "Thief=yes in RA2 is OK" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::infantry(DOG) ""
    set_raw DOG {Thief=yes}
    setup_index
    ::Checks::validate_thief_guard_mode
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: Thief=yes in Ares — should warn
# --------------------------------------------------------------------------
test tgm-ares-yes "Thief=yes in Ares warns" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::infantry(DOG) ""
    set_raw DOG {Thief=yes}
    setup_index
    ::Checks::validate_thief_guard_mode
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Thief=yes in Phobos — should warn
# --------------------------------------------------------------------------
test tgm-phobos-yes "Thief=yes in Phobos warns" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::infantry(DOG) ""
    set_raw DOG {Thief=yes}
    setup_index
    ::Checks::validate_thief_guard_mode
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 6: Multiple infantry, one Thief=yes — 1 warning
# --------------------------------------------------------------------------
test tgm-mixed "Only one Thief=yes warns once" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(DOG) ""
    set_raw DOG {Thief=yes}
    set ::Data::infantry(GI) ""
    set_raw GI {Thief=no}
    setup_index
    ::Checks::validate_thief_guard_mode
    expr {$::Logging::warning_count == 1}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
