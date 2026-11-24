package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks laser_parameters.tcl]

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

test lp-phobos "Skipped in Phobos" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::buildings(TestBldg) ""
    set ::Data::weapons(0) "LaserA"
    set ::Data::rawmapdata(LaserA) {IsLaser=yes LaserDuration=10}
    set ::Data::weapons(1) "LaserB"
    set ::Data::rawmapdata(LaserB) {IsLaser=yes LaserDuration=20}
    set ::Data::rawmapdata(TestBldg) {Primary=LaserA Secondary=LaserB}
    setup_index
    ::Checks::validate_laser_parameters
    expr {$::Logging::warning_count == 0}
} -result 1

test lp-param-mismatch "Different LaserDuration on secondary notices" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(TestBldg) ""
    set ::Data::weapons(0) "LaserA"
    set ::Data::rawmapdata(LaserA) {IsLaser=yes LaserDuration=10}
    set ::Data::weapons(1) "LaserB"
    set ::Data::rawmapdata(LaserB) {IsLaser=yes LaserDuration=20}
    set ::Data::rawmapdata(TestBldg) {Primary=LaserA Secondary=LaserB}
    setup_index
    ::Checks::validate_laser_parameters
    expr {$::Logging::notice_count > 0}
} -result 1

test lp-non-laser-primary "Laser secondary but non-laser primary notices" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(TestBldg) ""
    set ::Data::weapons(0) "Cannon"
    set ::Data::rawmapdata(Cannon) {IsLaser=no}
    set ::Data::weapons(1) "LaserB"
    set ::Data::rawmapdata(LaserB) {IsLaser=yes}
    set ::Data::rawmapdata(TestBldg) {Primary=Cannon Secondary=LaserB}
    setup_index
    ::Checks::validate_laser_parameters
    expr {$::Logging::notice_count > 0}
} -result 1

reset_state
cleanupTests
