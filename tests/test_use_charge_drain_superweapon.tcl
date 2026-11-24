#----------------------------------------------------------------------------------------------------------
# test_use_charge_drain_superweapon.tcl - Unit tests for checks/use_charge_drain_superweapon.tcl
# Tests: UseChargeDrain on non-Firestorm SuperWeaponTypes
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
source [file join $script_dir "checks" "use_charge_drain_superweapon.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::superweapons
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
# Test 1: UseChargeDrain=yes on Iron Curtain — should warn
# --------------------------------------------------------------------------
test ucdsw-ic "UseChargeDrain on IronCurtain warns" -body {
    reset_state
    set ::Data::superweapons(0) "IronCurtain"
    set ::Data::rawmapdata(IronCurtain) {UseChargeDrain=yes Type=IronCurtain}
    setup_index
    ::Checks::validate_use_charge_drain_superweapon
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: UseChargeDrain=yes on Firestorm — should pass
# --------------------------------------------------------------------------
test ucdsw-firestorm "UseChargeDrain on Firestorm is OK" -body {
    reset_state
    set ::Data::superweapons(0) "Firestorm"
    set ::Data::rawmapdata(Firestorm) {UseChargeDrain=yes Type=Firestorm}
    setup_index
    ::Checks::validate_use_charge_drain_superweapon
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: UseChargeDrain=no — should pass
# --------------------------------------------------------------------------
test ucdsw-no "UseChargeDrain=no is OK" -body {
    reset_state
    set ::Data::superweapons(0) "IronCurtain"
    set ::Data::rawmapdata(IronCurtain) {UseChargeDrain=no Type=IronCurtain}
    setup_index
    ::Checks::validate_use_charge_drain_superweapon
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No UseChargeDrain — should pass
# --------------------------------------------------------------------------
test ucdsw-none "No UseChargeDrain is OK" -body {
    reset_state
    set ::Data::superweapons(0) "IronCurtain"
    set ::Data::rawmapdata(IronCurtain) {Type=IronCurtain}
    setup_index
    ::Checks::validate_use_charge_drain_superweapon
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
