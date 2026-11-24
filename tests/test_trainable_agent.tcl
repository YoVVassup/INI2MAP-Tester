#----------------------------------------------------------------------------------------------------------
# test_trainable_agent.tcl - Unit tests for checks/trainable_agent.tcl
# Tests: Agent=yes + Trainable=no factory bypass detection
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
source [file join $script_dir "checks" "trainable_agent.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::buildings
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
# Test 1: Agent=yes with factory — should warn
# --------------------------------------------------------------------------
test ta-agent-factory "Agent=yes with factory warns" -body {
    reset_state
    set ::Data::infantry(SPYES) ""
    set ::Data::rawmapdata(SPYES) {Agent=yes}
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {Factory=1}
    setup_index
    ::Checks::validate_trainable_agent
    expr {$::Logging::notice_count + $::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Agent=yes without factory — should pass
# --------------------------------------------------------------------------
test ta-agent-no-factory "Agent=yes without factory is OK" -body {
    reset_state
    set ::Data::infantry(SPYES) ""
    set ::Data::rawmapdata(SPYES) {Agent=yes}
    set ::Data::buildings(HOUSE) ""
    set ::Data::rawmapdata(HOUSE) {Factory=0}
    setup_index
    ::Checks::validate_trainable_agent
    expr {$::Logging::notice_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Agent=no with factory — should pass
# --------------------------------------------------------------------------
test ta-no-agent "Agent=no with factory is OK" -body {
    reset_state
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {Agent=no}
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {Factory=1}
    setup_index
    ::Checks::validate_trainable_agent
    expr {$::Logging::notice_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: Agent=yes + Trainable=no + factory — warning (bypasses restriction)
# --------------------------------------------------------------------------
test ta-agent-notrainable "Agent=yes + Trainable=no warns" -body {
    reset_state
    set ::Data::infantry(SPYES) ""
    set ::Data::rawmapdata(SPYES) [list "Agent=yes" "Trainable=no"]
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {Factory=1}
    setup_index
    ::Checks::validate_trainable_agent
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Agent=yes in Ares — should pass (fixed in Ares 0.2)
# --------------------------------------------------------------------------
test ta-ares-fixed "Agent=yes in Ares is OK (fixed)" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::infantry(SPYES) ""
    set ::Data::rawmapdata(SPYES) {Agent=yes}
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {Factory=1}
    setup_index
    ::Checks::validate_trainable_agent
    expr {$::Logging::notice_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
