#----------------------------------------------------------------------------------------------------------
# test_primary_none_secondary.tcl - Unit tests for checks/primary_none_secondary.tcl
# Tests: Primary=none with Secondary weapon detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "primary_none_secondary.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
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
# Test 1: Primary=none with Secondary set — should warn
# --------------------------------------------------------------------------
test pns-warn "Primary=none with Secondary warns" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) [list "Primary=none" "Secondary=M1A1"]
    setup_index
    ::Checks::validate_primary_none_secondary
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Primary=none with no Secondary — should pass
# --------------------------------------------------------------------------
test pns-ok "Primary=none without Secondary is OK" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {Primary=none}
    setup_index
    ::Checks::validate_primary_none_secondary
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Primary set with Secondary — should pass
# --------------------------------------------------------------------------
test pns-normal "Normal Primary/Secondary is OK" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) [list "Primary=M1A1" "Secondary=MGun"]
    setup_index
    ::Checks::validate_primary_none_secondary
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
