package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks is_locomotor.tcl]

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

test iloc-ra2 "Skipped in RA2" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::warheads(0) "LocoWH"
    set ::Data::rawmapdata(LocoWH) {IsLocomotor=yes}
    setup_index
    ::Checks::validate_is_locomotor
    expr {$::Logging::warning_count == 0}
} -result 1

test iloc-shrapnel "IsLocomotor warhead + ShrapnelWeapon warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::warheads(0) "LocoWH"
    set ::Data::rawmapdata(LocoWH) {IsLocomotor=yes}
    set ::Data::weapons(0) "LocoWeap"
    set ::Data::rawmapdata(LocoWeap) {Warhead=LocoWH ShrapnelWeapon=ShrapWeap}
    setup_index
    ::Checks::validate_is_locomotor
    expr {$::Logging::warning_count > 0}
} -result 1

test iloc-shrapnel-phobos "IsLocomotor + ShrapnelWeapon in Phobos OK" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::warheads(0) "LocoWH"
    set ::Data::rawmapdata(LocoWH) {IsLocomotor=yes}
    set ::Data::weapons(0) "LocoWeap"
    set ::Data::rawmapdata(LocoWeap) {Warhead=LocoWH ShrapnelWeapon=ShrapWeap}
    setup_index
    ::Checks::validate_is_locomotor
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
