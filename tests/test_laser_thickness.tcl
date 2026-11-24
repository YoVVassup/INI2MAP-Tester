package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks laser_thickness.tcl]

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

test lth-non-ares "Skipped in non-Ares modes" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "LaserW"
    set ::Data::rawmapdata(LaserW) {LaserThickness=10 IsLaser=yes}
    setup_index
    ::Checks::validate_laser_thickness
    expr {$::Logging::warning_count == 0}
} -result 1

test lth-not-laser "LaserThickness on non-laser weapon warns" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::weapons(0) "CannonW"
    set ::Data::rawmapdata(CannonW) {LaserThickness=5 IsLaser=no}
    setup_index
    ::Checks::validate_laser_thickness
    expr {$::Logging::warning_count > 0}
} -result 1

test lth-exceeds-limit "LaserThickness > 8 warns about limit" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::weapons(0) "LaserW"
    set ::Data::rawmapdata(LaserW) {LaserThickness=12 IsLaser=yes IsHouseColor=yes}
    setup_index
    ::Checks::validate_laser_thickness
    expr {$::Logging::warning_count > 0}
} -result 1

reset_state
cleanupTests
