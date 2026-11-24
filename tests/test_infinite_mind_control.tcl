package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks infinite_mind_control.tcl]

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

test imc-no-weapon "No weapons defined" -body {
    reset_state
    set ::Data::gamemode "yr"
    setup_index
    ::Checks::validate_infinite_mind_control
    expr {$::Logging::warning_count == 0}
} -result 1

test imc-damage-0 "InfiniteMindControl=yes Damage=0 warns in YR" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "MindWeapon"
    set ::Data::warheads(0) "MCWarhead"
    set ::Data::rawmapdata(MindWeapon) {InfiniteMindControl=yes Warhead=MCWarhead Damage=0}
    set ::Data::rawmapdata(MCWarhead) {MindControl=yes}
    setup_index
    ::Checks::validate_infinite_mind_control
    expr {$::Logging::warning_count > 0}
} -result 1

test imc-damage-0-phobos "InfiniteMindControl=yes Damage=0 no warn in Phobos" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::weapons(0) "MindWeapon"
    set ::Data::warheads(0) "MCWarhead"
    set ::Data::rawmapdata(MindWeapon) {InfiniteMindControl=yes Warhead=MCWarhead Damage=0}
    set ::Data::rawmapdata(MCWarhead) {MindControl=yes}
    setup_index
    ::Checks::validate_infinite_mind_control
    expr {$::Logging::warning_count == 0}
} -result 1

test imc-no-mc-warhead "InfiniteMindControl=yes but warhead lacks MindControl" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "MindWeapon"
    set ::Data::warheads(0) "BadWH"
    set ::Data::rawmapdata(MindWeapon) {InfiniteMindControl=yes Warhead=BadWH Damage=50}
    set ::Data::rawmapdata(BadWH) {MindControl=no}
    setup_index
    ::Checks::validate_infinite_mind_control
    expr {$::Logging::warning_count > 0}
} -result 1

reset_state
cleanupTests
