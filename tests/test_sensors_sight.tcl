#----------------------------------------------------------------------------------------------------------
# test_sensors_sight.tcl - Unit tests for checks/sensors_sight.tcl
# Tests: SensorsSight usage on various TechnoTypes in vanilla mode
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "sensors_sight.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::buildings
    array unset ::Data::vehicles
    array unset ::Data::infantry
    array unset ::Data::aircraft
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
# Test 1: SensorsSight > 0 on vehicle in vanilla — should warn
# --------------------------------------------------------------------------
test ss-vehicle-vanilla "SensorsSight on vehicle warns in vanilla" -body {
    reset_state
    set ::Data::vehicles(RADAR) ""
    set ::Data::rawmapdata(RADAR) {SensorsSight=10}
    setup_index
    ::Checks::validate_sensors_sight
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: SensorsSight=0 or not set — should pass
# --------------------------------------------------------------------------
test ss-zero "SensorsSight=0 is OK" -body {
    reset_state
    set ::Data::vehicles(RADAR) ""
    set ::Data::rawmapdata(RADAR) {SensorsSight=0}
    setup_index
    ::Checks::validate_sensors_sight
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: SensorsSight > 0 in Ares — should pass (bug fixed)
# --------------------------------------------------------------------------
test ss-ares-fixed "SensorsSight in Ares is OK (fixed)" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::vehicles(RADAR) ""
    set ::Data::rawmapdata(RADAR) {SensorsSight=10}
    setup_index
    ::Checks::validate_sensors_sight
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
