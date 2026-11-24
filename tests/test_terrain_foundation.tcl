package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks terrain_foundation.tcl]

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
    array unset ::Data::terrains
    array unset ::Data::terrain_foundation
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test tf-normal "Terrain with Foundation=1x1 no error" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::terrains(TestTerrain) ""
    set ::Data::terrain_foundation(TestTerrain) "1x1"
    setup_index
    ::Checks::validate_terrain_foundation
    expr {$::Logging::error_count == 0}
} -result 1

test tf-zero-crash "Terrain with Foundation=0x0 errors" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::terrains(BadTerrain) ""
    set ::Data::terrain_foundation(BadTerrain) "0x0"
    setup_index
    ::Checks::validate_terrain_foundation
    expr {$::Logging::error_count > 0}
} -result 1

test tf-no-foundation "Terrain without foundation entry no error" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::terrains(NoFndTerrain) ""
    setup_index
    ::Checks::validate_terrain_foundation
    expr {$::Logging::error_count == 0}
} -result 1

reset_state
cleanupTests
