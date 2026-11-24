#----------------------------------------------------------------------------------------------------------
# test_airstrike.tcl - Unit tests for checks/airstrike.tcl
# Tests: AirstrikeTeam/AirstrikeTeamType configuration validation
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks airstrike.tcl]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::buildings
    array unset ::Data::projectiles
    array unset ::Data::warheads
    array unset ::Data::weapons
    array unset ::Data::teamtypes
    array unset ::Data::taskforces
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: Airstrike=yes without AirstrikeTeam — should error
# --------------------------------------------------------------------------
test as-missing-team "Airstrike without team errors" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(FIGHTER) ""
    set ::Data::rawmapdata(InfantryTypes) {0=FIGHTER}
    set ::Data::rawmapdata(FIGHTER) {Airstrike=yes}
    setup_index
    ::Checks::validate_airstrike
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: AirstrikeTeam=2 — should pass (valid range)
# --------------------------------------------------------------------------
test as-valid "Valid AirstrikeTeam passes" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(FIGHTER) ""
    set ::Data::rawmapdata(InfantryTypes) {0=FIGHTER}
    set ::Data::rawmapdata(FIGHTER) {Airstrike=yes AirstrikeTeam=2 AirstrikeTeamType=BULL}
    set ::Data::aircraft(BULL) ""
    setup_index
    ::Checks::validate_airstrike
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Invalid AirstrikeTeamType — should error
# --------------------------------------------------------------------------
test as-bad-type "Invalid AirstrikeTeamType errors" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(FIGHTER) ""
    set ::Data::rawmapdata(InfantryTypes) {0=FIGHTER}
    set ::Data::rawmapdata(FIGHTER) {Airstrike=yes AirstrikeTeam=2 AirstrikeTeamType=NONEXIST}
    setup_index
    ::Checks::validate_airstrike
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
