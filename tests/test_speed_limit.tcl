package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks speed_limit.tcl]

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

test sml-no-issues "Normal Speed value" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(TestInf) ""
    set ::Data::rawmapdata(TestInf) {Speed=5}
    setup_index
    ::Checks::validate_speed_limit
    expr {$::Logging::warning_count == 0 && $::Logging::notice_count == 0}
} -result 1

test sml-zero-warns "Speed=0 warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TestVeh) ""
    set ::Data::rawmapdata(TestVeh) {Speed=0}
    setup_index
    ::Checks::validate_speed_limit
    expr {$::Logging::warning_count > 0}
} -result 1

test sml-infantry-fast "Infantry Speed>=14 notices" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(FastInf) ""
    set ::Data::rawmapdata(FastInf) {Speed=14}
    setup_index
    ::Checks::validate_speed_limit
    expr {$::Logging::notice_count > 0}
} -result 1

reset_state
cleanupTests
