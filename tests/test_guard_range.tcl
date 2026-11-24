package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks guard_range.tcl]

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

test gr-over "GuardRange > 16 warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {GuardRange=20}
    setup_index
    ::Checks::validate_guard_range
    expr {$::Logging::warning_count > 0}
} -result 1

test gr-ok "GuardRange = 8 no warning" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {GuardRange=8}
    setup_index
    ::Checks::validate_guard_range
    expr {$::Logging::warning_count == 0}
} -result 1

test gr-phobos "GuardRange > 16 in phobos skipped" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) {GuardRange=20}
    setup_index
    ::Checks::validate_guard_range
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
