#----------------------------------------------------------------------------------------------------------
# test_weaponx_ifv.tcl - Unit tests for checks/weaponx_ifv.tcl
# Tests: WeaponX on non-FV VehicleTypes detection
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
source [file join $script_dir "checks" "weaponx_ifv.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::vehicles
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
# Test 1: WeaponX on non-FV in YR — should warn
# --------------------------------------------------------------------------
test wxifv-nonfv "WeaponX on non-FV warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(JEEP) ""
    set ::Data::rawmapdata(JEEP) {WeaponX=MyWeapon}
    setup_index
    ::Checks::validate_weaponx_ifv
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: WeaponX on FV — should pass
# --------------------------------------------------------------------------
test wxifv-fv "WeaponX on FV is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(FV) ""
    set ::Data::rawmapdata(FV) {WeaponX=MyWeapon}
    setup_index
    ::Checks::validate_weaponx_ifv
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: No WeaponX — should pass
# --------------------------------------------------------------------------
test wxifv-none "No WeaponX is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(JEEP) ""
    set ::Data::rawmapdata(JEEP) {Strength=100}
    setup_index
    ::Checks::validate_weaponx_ifv
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: WeaponX on non-FV in Ares — should pass (fixed)
# --------------------------------------------------------------------------
test wxifv-ares "WeaponX in Ares is OK (fixed)" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::vehicles(JEEP) ""
    set ::Data::rawmapdata(JEEP) {WeaponX=MyWeapon}
    setup_index
    ::Checks::validate_weaponx_ifv
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
