package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks strafing_burst.tcl]

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
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test sb-fighter-skip "Fighter=yes skips check" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(TestAc) ""
    set ::Data::rawmapdata(TestAc) {Fighter=yes}
    setup_index
    ::Checks::validate_strafing_burst
    expr {$::Logging::notice_count == 0}
} -result 1

test sb-strafing-warns "Non-fighter with Burst>1 warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(BombPlane) ""
    set ::Data::rawmapdata(BombPlane) {Fighter=no Primary=BigGun}
    set ::Data::rawmapdata(BigGun) {Burst=5}
    setup_index
    ::Checks::validate_strafing_burst
    expr {$::Logging::notice_count > 0}
} -result 1

test sb-phobos-skip "Non-fighter skipped in Phobos" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::aircraft(BombPlane) ""
    set ::Data::rawmapdata(BombPlane) {Fighter=no Primary=BigGun}
    set ::Data::rawmapdata(BigGun) {Burst=5}
    setup_index
    ::Checks::validate_strafing_burst
    expr {$::Logging::notice_count == 0}
} -result 1

reset_state
cleanupTests
