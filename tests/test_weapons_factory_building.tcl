#----------------------------------------------------------------------------------------------------------
# test_weapons_factory_building.tcl - Unit tests for checks/weapons_factory_building.tcl
# Tests: WeaponsFactory=yes conflict combinations
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
source [file join $script_dir "checks" "weapons_factory_building.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::buildings
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
# Test 1: WeaponsFactory=yes + DockUnload=yes — should warn
# --------------------------------------------------------------------------
test wfb-dock "WeaponsFactory+DockUnload warns" -body {
    reset_state
    set ::Data::buildings(REF) ""
    set ::Data::rawmapdata(REF) {WeaponsFactory=yes DockUnload=yes}
    setup_index
    ::Checks::validate_weapons_factory_building
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: WeaponsFactory=yes + Hospital=yes — should warn
# --------------------------------------------------------------------------
test wfb-hospital "WeaponsFactory+Hospital warns" -body {
    reset_state
    set ::Data::buildings(HOSP) ""
    set ::Data::rawmapdata(HOSP) {WeaponsFactory=yes Hospital=yes}
    setup_index
    ::Checks::validate_weapons_factory_building
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: WeaponsFactory=yes + Factory=InfantryType — should warn
# --------------------------------------------------------------------------
test wfb-factory "WeaponsFactory+Factory=InfantryType warns" -body {
    reset_state
    set ::Data::buildings(BARR) ""
    set ::Data::rawmapdata(BARR) {WeaponsFactory=yes Factory=InfantryType}
    setup_index
    ::Checks::validate_weapons_factory_building
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: WeaponsFactory=yes + UnitRepair=yes — should warn
# --------------------------------------------------------------------------
test wfb-repair "WeaponsFactory+UnitRepair warns" -body {
    reset_state
    set ::Data::buildings(DEPO) ""
    set ::Data::rawmapdata(DEPO) {WeaponsFactory=yes UnitRepair=yes}
    setup_index
    ::Checks::validate_weapons_factory_building
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: WeaponsFactory=yes alone — should pass
# --------------------------------------------------------------------------
test wfb-ok "WeaponsFactory=yes alone is OK" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::rawmapdata(FACT) {WeaponsFactory=yes}
    setup_index
    ::Checks::validate_weapons_factory_building
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 6: WeaponsFactory=no — should pass
# --------------------------------------------------------------------------
test wfb-no "WeaponsFactory=no is OK" -body {
    reset_state
    set ::Data::buildings(REF) ""
    set ::Data::rawmapdata(REF) {WeaponsFactory=no DockUnload=yes Hospital=yes}
    setup_index
    ::Checks::validate_weapons_factory_building
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 7: Factory=InfantryType in Ares — should pass (fixed in 0.2)
# --------------------------------------------------------------------------
test wfb-ares-factory "Factory=InfantryType in Ares is OK" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::buildings(BARR) ""
    set ::Data::rawmapdata(BARR) {WeaponsFactory=yes Factory=InfantryType}
    setup_index
    ::Checks::validate_weapons_factory_building
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 8: UnitRepair in Ares — should pass (fixed in 0.6)
# --------------------------------------------------------------------------
test wfb-ares-repair "UnitRepair in Ares is OK" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::buildings(DEPO) ""
    set ::Data::rawmapdata(DEPO) {WeaponsFactory=yes UnitRepair=yes}
    setup_index
    ::Checks::validate_weapons_factory_building
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
