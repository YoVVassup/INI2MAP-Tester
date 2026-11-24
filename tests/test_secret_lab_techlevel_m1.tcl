#----------------------------------------------------------------------------------------------------------
# test_secret_lab_techlevel_m1.tcl - Unit tests for checks/secret_lab_techlevel_m1.tcl
# Tests: SecretLab + TechLevel=-1 in bonus pool detection
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
source [file join $script_dir "checks" "secret_lab_techlevel_m1.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::buildings
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: No SecretLab buildings — should pass
# --------------------------------------------------------------------------
test sltm1-no-lab "No SecretLab buildings" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {SecretLab=no}
    setup_index
    ::Checks::validate_secret_lab_techlevel_m1
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: SecretLab + TechLevel=-1 IN bonus pool — should warn
# --------------------------------------------------------------------------
test sltm1-in-pool "TechLevel=-1 in bonus pool warns" -body {
    reset_state
    set ::Data::buildings(SECLAB) ""
    set ::Data::rawmapdata(SECLAB) {SecretLab=yes}
    set ::Data::rulesdata(General) {SecretInfantry=GHOST,DOG}
    set ::Data::infantry(GHOST) ""
    set ::Data::rawmapdata(GHOST) {TechLevel=-1}
    setup_index
    ::Checks::validate_secret_lab_techlevel_m1
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: SecretLab + TechLevel=-1 NOT in bonus pool — should pass
# --------------------------------------------------------------------------
test sltm1-not-pool "TechLevel=-1 not in pool is OK" -body {
    reset_state
    set ::Data::buildings(SECLAB) ""
    set ::Data::rawmapdata(SECLAB) {SecretLab=yes}
    set ::Data::rulesdata(General) {SecretInfantry=GI}
    set ::Data::infantry(GHOST) ""
    set ::Data::rawmapdata(GHOST) {TechLevel=-1}
    setup_index
    ::Checks::validate_secret_lab_techlevel_m1
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No bonus pool defined — should pass
# --------------------------------------------------------------------------
test sltm1-no-pool "No bonus pool defined is OK" -body {
    reset_state
    set ::Data::buildings(SECLAB) ""
    set ::Data::rawmapdata(SECLAB) {SecretLab=yes}
    set ::Data::infantry(GHOST) ""
    set ::Data::rawmapdata(GHOST) {TechLevel=-1}
    setup_index
    ::Checks::validate_secret_lab_techlevel_m1
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: TechLevel=-1 in pool + vehicle — should warn
# --------------------------------------------------------------------------
test sltm1-vehicle "Vehicle in pool warns" -body {
    reset_state
    set ::Data::buildings(SECLAB) ""
    set ::Data::rawmapdata(SECLAB) {SecretLab=yes}
    set ::Data::rulesdata(General) {SecretUnits=DEST,HORV}
    set ::Data::vehicles(DEST) ""
    set ::Data::rawmapdata(DEST) {TechLevel=-1}
    setup_index
    ::Checks::validate_secret_lab_techlevel_m1
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
