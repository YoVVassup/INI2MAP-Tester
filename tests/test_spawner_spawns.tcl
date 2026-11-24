package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks spawner_spawns.tcl]

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

proc setup_index {} { ::Checks::build_index }

test ss-no-spawner "No Spawner weapons defined" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "NormGun"
    set ::Data::rawmapdata(NormGun) {Spawner=no}
    setup_index
    ::Checks::validate_spawner_spawns
    expr {$::Logging::error_count == 0}
} -result 1

test ss-missing-spawns "Spawner weapon without Spawns= errors" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "SpawnGun"
    set ::Data::buildings(SpawnBldg) ""
    set ::Data::rawmapdata(SpawnGun) {Spawner=yes}
    set ::Data::rawmapdata(SpawnBldg) {Primary=SpawnGun}
    setup_index
    ::Checks::validate_spawner_spawns
    expr {$::Logging::error_count > 0}
} -result 1

test ss-valid-spawns "Spawner weapon with Spawns= defined" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "SpawnGun"
    set ::Data::buildings(SpawnBldg) ""
    set ::Data::rawmapdata(SpawnGun) {Spawner=yes}
    set ::Data::rawmapdata(SpawnBldg) {Primary=SpawnGun Spawns=SomeMinion}
    setup_index
    ::Checks::validate_spawner_spawns
    expr {$::Logging::error_count == 0}
} -result 1

reset_state
cleanupTests
