#----------------------------------------------------------------------------------------------------------
# test_missile_spawn.tcl - Unit tests for checks/missile_spawn.tcl
# Tests: MissileSpawn=yes warning in Phobos mode
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "missile_spawn.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::buildings
    set ::Data::gamemode "phobos"
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

proc set_raw {section line} {
    set ::Data::rawmapdata($section) [list $line]
}

# --------------------------------------------------------------------------
# Test 1: No MissileSpawn set — should pass
# --------------------------------------------------------------------------
test ms-no-flag "No MissileSpawn set" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set_raw TANK {Primary=M1A1}
    setup_index
    ::Checks::validate_missile_spawn
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: MissileSpawn=yes on vehicle in Phobos — should warn
# --------------------------------------------------------------------------
test ms-vehicle-yes "Vehicle MissileSpawn=yes warns" -body {
    reset_state
    set ::Data::vehicles(ROCKET) ""
    set_raw ROCKET {MissileSpawn=yes}
    setup_index
    ::Checks::validate_missile_spawn
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: MissileSpawn=yes on infantry in Phobos — should warn
# --------------------------------------------------------------------------
test ms-infantry-yes "Infantry MissileSpawn=yes warns" -body {
    reset_state
    set ::Data::infantry(GI) ""
    set_raw GI {MissileSpawn=yes}
    setup_index
    ::Checks::validate_missile_spawn
    expr {$::Logging::warning_count > 0}
} -result 1

reset_state
cleanupTests
