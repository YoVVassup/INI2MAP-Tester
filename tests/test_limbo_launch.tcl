package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks limbo_launch.tcl]

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
    array unset ::Data::superweapons
    array unset ::Data::particles
    array unset ::Data::particlesys
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test ll-no-limbo "Weapon without LimboLaunch" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "NormalWeap"
    set ::Data::rawmapdata(NormalWeap) {LimboLaunch=no}
    setup_index
    ::Checks::validate_limbo_launch
    expr {$::Logging::warning_count == 0}
} -result 1

test ll-no-parasite "LimboLaunch=yes without Parasite warhead warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "LimboWeap"
    set ::Data::warheads(0) "BadWH"
    set ::Data::rawmapdata(LimboWeap) {LimboLaunch=yes Warhead=BadWH}
    set ::Data::rawmapdata(BadWH) {Parasite=no}
    setup_index
    ::Checks::validate_limbo_launch
    expr {$::Logging::warning_count > 0}
} -result 1

test ll-spawner-conflict "LimboLaunch=yes + Spawner=yes warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "LimboWeap"
    set ::Data::warheads(0) "ParaWH"
    set ::Data::rawmapdata(LimboWeap) {LimboLaunch=yes Warhead=ParaWH Spawner=yes}
    set ::Data::rawmapdata(ParaWH) {Parasite=yes}
    setup_index
    ::Checks::validate_limbo_launch
    expr {$::Logging::warning_count > 0}
} -result 1

reset_state
cleanupTests
