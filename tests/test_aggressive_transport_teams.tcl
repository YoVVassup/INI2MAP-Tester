#----------------------------------------------------------------------------------------------------------
# test_aggressive_transport_teams.tcl - Unit tests for checks/aggressive_transport_teams.tcl
# Tests: Aggressive + armed transport detection in TeamTypes
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir utils.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks aggressive_transport_teams.tcl]

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
# Test 1: Aggressive=yes with transport — should warn
# --------------------------------------------------------------------------
test at-transport "Aggressive+transport warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::teamtypes(TT1) "Team 1"
    set ::Data::rawmapdata(TT1) {Aggressive=yes TaskForce=TF1}
    set ::Data::taskforces(TF1) ""
    set ::Data::rawmapdata(TF1) {0=2,CHIN Name=Chinook Group=0}
    set ::Data::vehicles(CHIN) ""
    set ::Data::rawmapdata(CHIN) {Passengers=10}
    setup_index
    ::Checks::validate_aggressive_transport_teams
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Aggressive=no — should pass
# --------------------------------------------------------------------------
test at-no-agg "Aggressive=no is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::teamtypes(TT1) "Team 1"
    set ::Data::rawmapdata(TT1) {Aggressive=no TaskForce=TF1}
    set ::Data::taskforces(TF1) ""
    set ::Data::rawmapdata(TF1) {0=2,CHIN Name=Chinook Group=0}
    set ::Data::vehicles(CHIN) ""
    set ::Data::rawmapdata(CHIN) {Passengers=10}
    setup_index
    ::Checks::validate_aggressive_transport_teams
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Aggressive=yes without transport — should pass
# --------------------------------------------------------------------------
test at-no-passengers "No passengers is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::teamtypes(TT1) "Team 1"
    set ::Data::rawmapdata(TT1) {Aggressive=yes TaskForce=TF1}
    set ::Data::taskforces(TF1) ""
    set ::Data::rawmapdata(TF1) {0=5,GI Name=GI Squad Group=0}
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {Passengers=0}
    setup_index
    ::Checks::validate_aggressive_transport_teams
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
