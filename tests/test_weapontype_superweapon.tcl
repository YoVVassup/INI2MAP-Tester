#----------------------------------------------------------------------------------------------------------
# test_weapontype_superweapon.tcl - Unit tests for checks/weapontype_superweapon.tcl
# Tests: WeaponType first-use bug across SuperWeaponTypes
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
source [file join $script_dir "checks" "weapontype_superweapon.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::superweapons
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
# Test 1: Same WeaponType used by two SWs in YR — should warn
# --------------------------------------------------------------------------
test wtsw-dup "Duplicate WeaponType warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::superweapons(0) "SW1"
    set ::Data::superweapons(1) "SW2"
    set ::Data::rawmapdata(SW1) {WeaponType=MyWeapon Type=LightningStorm}
    set ::Data::rawmapdata(SW2) {WeaponType=MyWeapon Type=LightningStorm}
    setup_index
    ::Checks::validate_weapontype_superweapon
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Different WeaponTypes — should pass
# --------------------------------------------------------------------------
test wtsw-diff "Different WeaponTypes is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::superweapons(0) "SW1"
    set ::Data::superweapons(1) "SW2"
    set ::Data::rawmapdata(SW1) {WeaponType=Weapon1 Type=LightningStorm}
    set ::Data::rawmapdata(SW2) {WeaponType=Weapon2 Type=LightningStorm}
    setup_index
    ::Checks::validate_weapontype_superweapon
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Single SW — should pass
# --------------------------------------------------------------------------
test wtsw-single "Single SW is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::superweapons(0) "SW1"
    set ::Data::rawmapdata(SW1) {WeaponType=MyWeapon Type=LightningStorm}
    setup_index
    ::Checks::validate_weapontype_superweapon
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: Duplicate in Ares — should pass (fixed)
# --------------------------------------------------------------------------
test wtsw-ares "Duplicate in Ares is OK (fixed)" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::superweapons(0) "SW1"
    set ::Data::superweapons(1) "SW2"
    set ::Data::rawmapdata(SW1) {WeaponType=MyWeapon Type=LightningStorm}
    set ::Data::rawmapdata(SW2) {WeaponType=MyWeapon Type=LightningStorm}
    setup_index
    ::Checks::validate_weapontype_superweapon
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
