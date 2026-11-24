#----------------------------------------------------------------------------------------------------------
# test_omni_crusher.tcl - Unit tests for checks/omni_crusher.tcl
# Tests: OmniCrusher=yes without Crusher=yes detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "omni_crusher.tcl"]

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

proc set_raw {section line} {
    set ::Data::rawmapdata($section) [list $line]
}

# --------------------------------------------------------------------------
# Test 1: OmniCrusher=yes without Crusher — should warn
# --------------------------------------------------------------------------
test oc-no-crusher "OmniCrusher=yes without Crusher warns" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set_raw TANK {OmniCrusher=yes}
    setup_index
    ::Checks::validate_omni_crusher
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: OmniCrusher=yes with Crusher=yes — should pass
# --------------------------------------------------------------------------
test oc-with-crusher "OmniCrusher=yes with Crusher=yes is OK" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set_raw TANK {OmniCrusher=yes Crusher=yes}
    setup_index
    ::Checks::validate_omni_crusher
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: OmniCrusher=yes in RA2 — should pass (flag doesn't exist)
# --------------------------------------------------------------------------
test oc-ra2-mode "OmniCrusher in RA2 is ignored" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::vehicles(TANK) ""
    set_raw TANK {OmniCrusher=yes}
    setup_index
    ::Checks::validate_omni_crusher
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
