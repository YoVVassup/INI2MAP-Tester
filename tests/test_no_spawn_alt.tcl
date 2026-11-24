#----------------------------------------------------------------------------------------------------------
# test_no_spawn_alt.tcl - Unit tests for checks/no_spawn_alt.tcl
# Tests: NoSpawnAlt=yes on vehicles without spawner capability
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "no_spawn_alt.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::vehicles
    array unset ::Data::weapons
    set ::Data::gamemode "yr"
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
# Test 1: NoSpawnAlt=yes but no spawner weapons — should error
# --------------------------------------------------------------------------
test nsa-no-spawner "NoSpawnAlt=yes without spawner" -body {
    reset_state
    set ::Data::weapons(0) "SpawnGun"
    set_raw SpawnGun {Spawner=yes}
    set ::Data::vehicles(BUGGY) ""
    set_raw BUGGY {NoSpawnAlt=yes}
    setup_index
    ::Checks::validate_no_spawn_alt
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: NoSpawnAlt=yes with Spawns= set — should pass
# --------------------------------------------------------------------------
test nsa-spawns-ok "NoSpawnAlt=yes with Spawns= is OK" -body {
    reset_state
    set ::Data::vehicles(APC) ""
    set_raw APC {NoSpawnAlt=yes Spawns=CRASH}
    setup_index
    ::Checks::validate_no_spawn_alt
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: NoSpawnAlt=yes on vehicle in RA2 — should pass (flag doesn't exist)
# --------------------------------------------------------------------------
test nsa-ra2-mode "NoSpawnAlt in RA2 mode is ignored" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::vehicles(BUGGY) ""
    set_raw BUGGY {NoSpawnAlt=yes}
    setup_index
    ::Checks::validate_no_spawn_alt
    expr {$::Logging::error_count == 0}
} -result 1

reset_state
cleanupTests
