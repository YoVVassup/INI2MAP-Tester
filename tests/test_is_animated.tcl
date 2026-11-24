package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks is_animated.tcl]

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
    array unset ::Data::terrains
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test ia-no-terrains "No terrain types defined" -body {
    reset_state
    set ::Data::gamemode "yr"
    setup_index
    ::Checks::validate_is_animated
    expr {$::Logging::warning_count == 0}
} -result 1

test ia-animated-no-spawns "IsAnimated=yes without SpawnsTiberium warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::terrains(TestTree) ""
    set ::Data::rawmapdata(TestTree) {IsAnimated=yes SpawnsTiberium=no}
    setup_index
    ::Checks::validate_is_animated
    expr {$::Logging::warning_count > 0}
} -result 1

test ia-animated-with-spawns "IsAnimated=yes with SpawnsTiberium=yes OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::terrains(TestTree) ""
    set ::Data::rawmapdata(TestTree) {IsAnimated=yes SpawnsTiberium=yes}
    setup_index
    ::Checks::validate_is_animated
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
