package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks inviso.tcl]

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

test inviso-no-inviso "Projectile without Inviso=yes" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::projectiles(0) "Bullet"
    set ::Data::rawmapdata(Bullet) {Inviso=no}
    setup_index
    ::Checks::validate_inviso
    expr {$::Logging::warning_count == 0}
} -result 1

test inviso-airburst "Inviso=yes + Airburst=yes warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::projectiles(0) "ABProj"
    set ::Data::rawmapdata(ABProj) {Inviso=yes Airburst=yes}
    set ::Data::weapons(0) "ABWeap"
    set ::Data::rawmapdata(ABWeap) {Projectile=ABProj Warhead=ExploWH}
    set ::Data::warheads(0) "ExploWH"
    set ::Data::rawmapdata(ExploWH) {EMEffect=no}
    setup_index
    ::Checks::validate_inviso
    expr {$::Logging::warning_count > 0}
} -result 1

test inviso-phobos "Inviso=yes in Phobos - no warn" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::projectiles(0) "ABProj"
    set ::Data::rawmapdata(ABProj) {Inviso=yes Airburst=yes}
    set ::Data::weapons(0) "ABWeap"
    set ::Data::rawmapdata(ABWeap) {Projectile=ABProj Warhead=ExploWH}
    set ::Data::warheads(0) "ExploWH"
    set ::Data::rawmapdata(ExploWH) {EMEffect=yes}
    setup_index
    ::Checks::validate_inviso
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
