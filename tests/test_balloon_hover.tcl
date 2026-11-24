#----------------------------------------------------------------------------------------------------------
# test_balloon_hover.tcl - Unit tests for checks/balloon_hover.tcl
# Tests: BalloonHover flag conflict detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks balloon_hover.tcl]

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
# Test 1: Aircraft with BalloonHover=yes + AirportBound=yes — should warn
# --------------------------------------------------------------------------
test bh-aircraft "Aircraft BalloonHover+AirportBound warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(HELIOPTER) ""
    set ::Data::rawmapdata(AircraftTypes) {0=HELIOPTER}
    set ::Data::rawmapdata(HELIOPTER) {BalloonHover=yes AirportBound=yes}
    setup_index
    ::Checks::validate_balloon_hover
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Vehicle with BalloonHover=yes — should pass (info only)
# --------------------------------------------------------------------------
test bh-vehicle "Vehicle BalloonHover is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(FLYTANK) ""
    set ::Data::rawmapdata(VehicleTypes) {0=FLYTANK}
    set ::Data::rawmapdata(FLYTANK) {BalloonHover=yes}
    setup_index
    ::Checks::validate_balloon_hover
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Infantry with BalloonHover=yes — should pass (info only)
# --------------------------------------------------------------------------
test bh-infantry "Infantry BalloonHover is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(FLYSUIT) ""
    set ::Data::rawmapdata(InfantryTypes) {0=FLYSUIT}
    set ::Data::rawmapdata(FLYSUIT) {BalloonHover=yes}
    setup_index
    ::Checks::validate_balloon_hover
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
