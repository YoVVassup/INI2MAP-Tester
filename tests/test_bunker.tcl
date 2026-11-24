#----------------------------------------------------------------------------------------------------------
# test_bunker.tcl - Unit tests for checks/bunker.tcl
# Tests: Bunker flag validation on buildings
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks bunker.tcl]

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
# Test 1: Bunker + 1x1 foundation — should warn
# --------------------------------------------------------------------------
test bu-1x1 "Bunker 1x1 foundation warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(PILLBOX) ""
    set ::Data::rawmapdata(BuildingTypes) {0=PILLBOX}
    set ::Data::rawmapdata(PILLBOX) {Bunker=yes Foundation=1x1}
    setup_index
    ::Checks::validate_bunker
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Bunker + InfantryAbsorb=yes + UnitAbsorb=yes — should warn
# --------------------------------------------------------------------------
test bu-both-absorb "Bunker both absorb warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(PILLBOX) ""
    set ::Data::rawmapdata(BuildingTypes) {0=PILLBOX}
    set ::Data::rawmapdata(PILLBOX) {Bunker=yes InfantryAbsorb=yes UnitAbsorb=yes}
    setup_index
    ::Checks::validate_bunker
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Bunker without 1x1 and no absorb — should pass (info only)
# --------------------------------------------------------------------------
test bu-clean "Bunker with valid foundation is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(PILLBOX) ""
    set ::Data::rawmapdata(BuildingTypes) {0=PILLBOX}
    set ::Data::rawmapdata(PILLBOX) {Bunker=yes Foundation=2x2}
    setup_index
    ::Checks::validate_bunker
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
