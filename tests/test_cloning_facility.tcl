#----------------------------------------------------------------------------------------------------------
# test_cloning_facility.tcl - Unit tests for checks/cloning_facility.tcl
# Tests: CloningFacility + WeaponsFactory conflict detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks cloning_facility.tcl]

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
# Test 1: CloningFacility=yes + WeaponsFactory=yes — should warn
# --------------------------------------------------------------------------
test cf-conflict "CloningFacility+WeaponsFactory warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(CLVAT) ""
    set ::Data::rawmapdata(BuildingTypes) {0=CLVAT}
    set ::Data::rawmapdata(CLVAT) {CloningFacility=yes WeaponsFactory=yes}
    setup_index
    ::Checks::validate_cloning_facility
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: CloningFacility=yes without WeaponsFactory — should pass
# --------------------------------------------------------------------------
test cf-clean "CloningFacility without WeaponsFactory is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(CLVAT) ""
    set ::Data::rawmapdata(BuildingTypes) {0=CLVAT}
    set ::Data::rawmapdata(CLVAT) {CloningFacility=yes}
    setup_index
    ::Checks::validate_cloning_facility
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Phobos mode — should skip
# --------------------------------------------------------------------------
test cf-phobos "Phobos skips check" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::buildings(CLVAT) ""
    set ::Data::rawmapdata(BuildingTypes) {0=CLVAT}
    set ::Data::rawmapdata(CLVAT) {CloningFacility=yes WeaponsFactory=yes}
    setup_index
    ::Checks::validate_cloning_facility
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
