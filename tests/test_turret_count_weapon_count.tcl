#----------------------------------------------------------------------------------------------------------
# test_turret_count_weapon_count.tcl - Unit tests for checks/turret_count_weapon_count.tcl
# Tests: TurretCount > 0 + WeaponCount validation
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
source [file join $script_dir "checks" "turret_count_weapon_count.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::buildings
    array unset ::Data::rawmapdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: TurretCount=2 without WeaponCount — should error
# --------------------------------------------------------------------------
test tcwc-no-wc "TurretCount without WeaponCount errors" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {TurretCount=2}
    setup_index
    ::Checks::validate_turret_count_weapon_count
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: TurretCount=2 with WeaponCount=2 — should pass
# --------------------------------------------------------------------------
test tcwc-ok "TurretCount=2 WeaponCount=2 is OK" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {TurretCount=2 WeaponCount=2}
    setup_index
    ::Checks::validate_turret_count_weapon_count
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: TurretCount=3 with WeaponCount=1 — should warn (too low)
# --------------------------------------------------------------------------
test tcwc-low "TurretCount=3 WeaponCount=1 warns" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {TurretCount=3 WeaponCount=1}
    setup_index
    ::Checks::validate_turret_count_weapon_count
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: TurretCount=0 — should pass
# --------------------------------------------------------------------------
test tcwc-zero "TurretCount=0 is OK" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {TurretCount=0 WeaponCount=0}
    setup_index
    ::Checks::validate_turret_count_weapon_count
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: No TurretCount — should pass
# --------------------------------------------------------------------------
test tcwc-none "No TurretCount is OK" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {Strength=1000}
    setup_index
    ::Checks::validate_turret_count_weapon_count
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 6: Infantry type — should also check
# --------------------------------------------------------------------------
test tcwc-infantry "Infantry TurretCount checked too" -body {
    reset_state
    set ::Data::infantry(MECH) ""
    set ::Data::rawmapdata(MECH) {TurretCount=1}
    setup_index
    ::Checks::validate_turret_count_weapon_count
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
