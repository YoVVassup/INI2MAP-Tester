#----------------------------------------------------------------------------------------------------------
# test_secret_lab_bonus_count.tcl - Unit tests for checks/secret_lab_bonus_count.tcl
# Tests: Secret Lab bonus count vs placed labs in vanilla mode
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "secret_lab_bonus_count.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
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

# --------------------------------------------------------------------------
# Test 1: More labs than bonuses — should warn without crashing
# --------------------------------------------------------------------------
test slbc-too-many "More labs than bonuses produces a warning" -body {
    reset_state
    set ::Data::buildings(SECLAB) ""
    set ::Data::rawmapdata(SECLAB) {SecretLab=yes}
    set ::Data::rawmapdata(Structures) [list "0=SECLAB" "1=SECLAB"]
    set ::Data::rulesdata(General) {SecretInfantry=GI}
    setup_index
    set rc [catch {::Checks::validate_secret_lab_bonus_count} err]
    list $rc $::Logging::warning_count
} -result {0 1}

# --------------------------------------------------------------------------
# Test 2: Labs equal to bonuses — should pass
# --------------------------------------------------------------------------
test slbc-equal "Labs equal to bonuses is OK" -body {
    reset_state
    set ::Data::buildings(SECLAB) ""
    set ::Data::rawmapdata(SECLAB) {SecretLab=yes}
    set ::Data::rawmapdata(Structures) {0=SECLAB}
    set ::Data::rulesdata(General) {SecretInfantry=GI SecretUnits=TANK}
    setup_index
    ::Checks::validate_secret_lab_bonus_count
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: No labs placed — should pass
# --------------------------------------------------------------------------
test slbc-no-labs "No labs placed is OK" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {SecretLab=no}
    set ::Data::rawmapdata(Structures) {0=FACT}
    setup_index
    ::Checks::validate_secret_lab_bonus_count
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
