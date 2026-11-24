package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks minimum_range.tcl]

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

test mr-no-minrange "Weapon without MinimumRange" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "GunWeap"
    set ::Data::rawmapdata(GunWeap) {Range=5}
    setup_index
    ::Checks::validate_minimum_range
    expr {$::Logging::warning_count == 0}
} -result 1

test mr-infinite-range "MinimumRange with Range=-2 warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "SniperWeap"
    set ::Data::rawmapdata(SniperWeap) {MinimumRange=3 Range=-2}
    setup_index
    ::Checks::validate_minimum_range
    expr {$::Logging::warning_count > 0}
} -result 1

test mr-normal-range "MinimumRange with normal Range OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "TankWeap"
    set ::Data::rawmapdata(TankWeap) {MinimumRange=2 Range=8}
    setup_index
    ::Checks::validate_minimum_range
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
