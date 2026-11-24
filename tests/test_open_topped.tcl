#----------------------------------------------------------------------------------------------------------
# test_open_topped.tcl - Unit tests for checks/open_topped.tcl
# Tests: OpenTopped=yes on buildings in YR mode
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "open_topped.tcl"]

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

proc set_raw {section line} {
    set ::Data::rawmapdata($section) [list $line]
}

# --------------------------------------------------------------------------
# Test 1: OpenTopped=yes on building in YR — should warn
# --------------------------------------------------------------------------
test ot-yes-yr "OpenTopped=yes on building warns in YR" -body {
    reset_state
    set ::Data::buildings(BARR) ""
    set_raw BARR {OpenTopped=yes}
    setup_index
    ::Checks::validate_open_topped
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: OpenTopped=yes on building in RA2 — should pass (not checked)
# --------------------------------------------------------------------------
test ot-ra2-mode "OpenTopped in RA2 is ignored" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::buildings(BARR) ""
    set_raw BARR {OpenTopped=yes}
    setup_index
    ::Checks::validate_open_topped
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: No OpenTopped set — should pass
# --------------------------------------------------------------------------
test ot-none "No OpenTopped set" -body {
    reset_state
    set ::Data::buildings(BARR) ""
    set_raw BARR {Power=50}
    setup_index
    ::Checks::validate_open_topped
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
