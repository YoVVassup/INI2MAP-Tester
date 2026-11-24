#----------------------------------------------------------------------------------------------------------
# test_attach_effects.tcl - Unit tests for checks/attach_effects.tcl
# Tests: AttachEffect.Animation/Beacon reference validation
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks attach_effects.tcl]

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
    array unset ::Data::anims
    array unset ::Data::particlesys
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: AttachEffect.Animation references undefined animation — should warn
# --------------------------------------------------------------------------
test ae-bad-anim "Undefined AttachEffect.Animation warns" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(VehicleTypes) {0=TANK}
    set ::Data::rawmapdata(TANK) {AttachEffect.Animation=NONEXIST}
    setup_index
    ::Checks::validate_attach_effects
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: AttachEffect.Animation references valid animation — should pass
# --------------------------------------------------------------------------
test ae-valid-anim "Valid AttachEffect.Animation is OK" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::anims(GOODANIM) ""
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(VehicleTypes) {0=TANK}
    set ::Data::rawmapdata(TANK) {AttachEffect.Animation=GOODANIM}
    setup_index
    ::Checks::validate_attach_effects
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: AttachEffect used outside Ares/Phobos — should warn
# --------------------------------------------------------------------------
test ae-wrong-gamemode "AttachEffect in RA2 warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::anims(GOODANIM) ""
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(VehicleTypes) {0=TANK}
    set ::Data::rawmapdata(TANK) {AttachEffect.Animation=GOODANIM}
    setup_index
    ::Checks::validate_attach_effects
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
