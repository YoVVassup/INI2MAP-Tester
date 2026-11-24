#----------------------------------------------------------------------------------------------------------
# test_undeploys_into.tcl - Unit tests for checks/undeploys_into.tcl
# Tests: UndeploysInto health floor and WaterBound detection
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
source [file join $script_dir "checks" "undeploys_into.tcl"]

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
# Test 1: UndeploysInto valid target — should notice (health floor)
# --------------------------------------------------------------------------
test ui-notice "UndeploysInto valid target notices" -body {
    reset_state
    set ::Data::vehicles(MCRU) ""
    set ::Data::rawmapdata(MCRU) {UndeploysInto=MCV}
    set ::Data::vehicles(MCV) ""
    set ::Data::rawmapdata(MCV) {Strength=1000}
    setup_index
    ::Checks::validate_undeploys_into
    expr {$::Logging::notice_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: UndeploysInto invalid target — should warn
# --------------------------------------------------------------------------
test ui-invalid "UndeploysInto invalid target warns" -body {
    reset_state
    set ::Data::vehicles(MCRU) ""
    set ::Data::rawmapdata(MCRU) {UndeploysInto=NONEXISTENT}
    setup_index
    ::Checks::validate_undeploys_into
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: UndeploysInto=none — should pass
# --------------------------------------------------------------------------
test ui-none "UndeploysInto=none is OK" -body {
    reset_state
    set ::Data::vehicles(MCRU) ""
    set ::Data::rawmapdata(MCRU) {UndeploysInto=none}
    setup_index
    ::Checks::validate_undeploys_into
    expr {$::Logging::warning_count == 0 && $::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No UndeploysInto — should pass
# --------------------------------------------------------------------------
test ui-empty "No UndeploysInto is OK" -body {
    reset_state
    set ::Data::vehicles(MCRU) ""
    set ::Data::rawmapdata(MCRU) {Strength=1000}
    setup_index
    ::Checks::validate_undeploys_into
    expr {$::Logging::warning_count == 0 && $::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Building with WaterBound=yes + UndeploysInto — should warn
# --------------------------------------------------------------------------
test ui-waterbound "WaterBound + UndeploysInto warns" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {UndeploysInto=MCV WaterBound=yes}
    set ::Data::vehicles(MCV) ""
    set ::Data::rawmapdata(MCV) {Strength=1000}
    setup_index
    ::Checks::validate_undeploys_into
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 6: Phobos mode — no health floor notice
# --------------------------------------------------------------------------
test ui-phobos "Phobos mode skips health floor notice" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::vehicles(MCRU) ""
    set ::Data::rawmapdata(MCRU) {UndeploysInto=MCV}
    set ::Data::vehicles(MCV) ""
    set ::Data::rawmapdata(MCV) {Strength=1000}
    setup_index
    ::Checks::validate_undeploys_into
    expr {$::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
