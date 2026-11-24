package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks spray_attack.tcl]

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

test spa-ra2-skip "SprayAttack skipped in RA2 mode" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::vehicles(TestVeh) ""
    set ::Data::rawmapdata(TestVeh) {SprayAttack=yes Parasite=yes}
    setup_index
    ::Checks::validate_spray_attack
    expr {$::Logging::warning_count == 0}
} -result 1

test spa-parasite-warn "SprayAttack+Parasite warns in YR" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TestVeh) ""
    set ::Data::rawmapdata(TestVeh) {SprayAttack=yes Parasite=yes}
    setup_index
    ::Checks::validate_spray_attack
    expr {$::Logging::warning_count > 0}
} -result 1

test spa-no-parasite "SprayAttack without Parasite no warn" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::aircraft(TestAc) ""
    set ::Data::rawmapdata(TestAc) {SprayAttack=yes Parasite=no}
    setup_index
    ::Checks::validate_spray_attack
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
