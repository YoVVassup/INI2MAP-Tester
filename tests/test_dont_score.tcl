package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks dont_score.tcl]

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
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test ds-yr "DontScore=yes in YR warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {DontScore=yes}
    setup_index
    ::Checks::validate_dont_score
    expr {$::Logging::warning_count > 0}
} -result 1

test ds-ra2 "DontScore=yes in RA2 skipped" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {DontScore=yes}
    setup_index
    ::Checks::validate_dont_score
    expr {$::Logging::warning_count == 0}
} -result 1

test ds-clean "DontScore=no no warning" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {DontScore=no}
    setup_index
    ::Checks::validate_dont_score
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
