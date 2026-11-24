package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks map.tcl]

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

test map-normal "Normal map dimensions - no warnings" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::rawmapdata(Map) {Size=0,0,100,100 Theater=TEMPERATE}
    setup_index
    ::Checks::validate_map
    expr {$::Logging::warning_count == 0}
} -result 1

test map-sum-exceeds "Sum > 512 warns about OverlayPack" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::rawmapdata(Map) {Size=0,0,300,300}
    setup_index
    ::Checks::validate_map
    expr {$::Logging::warning_count > 0}
} -result 1

test map-localsize-exceed "LocalSize exceeds map size errors" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::rawmapdata(Map) {Size=0,0,50,50 LocalSize=0,0,100,100}
    setup_index
    ::Checks::validate_map
    expr {$::Logging::error_count > 0}
} -result 1

reset_state
cleanupTests
