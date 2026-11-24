package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks is_laser.tcl]

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

test il-no-laser "Building with no laser weapons" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(TestBldg) ""
    set ::Data::weapons(0) "Cannon"
    set ::Data::rawmapdata(Cannon) {IsLaser=no}
    set ::Data::rawmapdata(TestBldg) {Primary=Cannon}
    setup_index
    ::Checks::validate_is_laser
    expr {$::Logging::warning_count == 0}
} -result 1

test il-non-primary-laser "Laser weapon only in secondary slot warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(TestBldg) ""
    set ::Data::weapons(0) "Cannon"
    set ::Data::rawmapdata(Cannon) {IsLaser=no}
    set ::Data::weapons(1) "LaserBeam"
    set ::Data::rawmapdata(LaserBeam) {IsLaser=yes}
    set ::Data::rawmapdata(TestBldg) {Primary=Cannon Secondary=LaserBeam}
    setup_index
    ::Checks::validate_is_laser
    expr {$::Logging::warning_count > 0}
} -result 1

test il-primary-laser "Laser weapon in primary slot OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(TestBldg) ""
    set ::Data::weapons(0) "LaserBeam"
    set ::Data::rawmapdata(LaserBeam) {IsLaser=yes}
    set ::Data::rawmapdata(TestBldg) {Primary=LaserBeam Secondary=LaserBeam}
    setup_index
    ::Checks::validate_is_laser
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
