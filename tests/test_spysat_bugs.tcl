package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks spysat_bugs.tcl]

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

test spy-no-spysat "Building without SpySat" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(TestBldg) ""
    set ::Data::rawmapdata(TestBldg) {SpySat=no}
    setup_index
    ::Checks::validate_spysat_bugs
    expr {$::Logging::notice_count == 0 && $::Logging::warning_count == 0}
} -result 1

test spy-fog-warns "SpySat with FogOfWar warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(SpyBldg) ""
    set ::Data::rawmapdata(General) {FogOfWar=yes ShroudGrow=no}
    set ::Data::rawmapdata(SpyBldg) {SpySat=yes}
    setup_index
    ::Checks::validate_spysat_bugs
    expr {$::Logging::warning_count > 0}
} -result 1

test spy-phobos-skip "SpySat skipped in Phobos" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::buildings(SpyBldg) ""
    set ::Data::rawmapdata(General) {FogOfWar=yes}
    set ::Data::rawmapdata(SpyBldg) {SpySat=yes}
    setup_index
    ::Checks::validate_spysat_bugs
    expr {$::Logging::warning_count == 0 && $::Logging::notice_count == 0}
} -result 1

reset_state
cleanupTests
