package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks is_gattling.tcl]

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

test ig-ra2 "IsGattling skipped in RA2" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::vehicles(GatTank) ""
    set ::Data::rawmapdata(GatTank) {IsGattling=yes}
    setup_index
    ::Checks::validate_is_gattling
    expr {$::Logging::warning_count == 0}
} -result 1

test ig-infantry-yr "IsGattling on infantry in YR warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(GatInf) ""
    set ::Data::rawmapdata(GatInf) {IsGattling=yes}
    setup_index
    ::Checks::validate_is_gattling
    expr {$::Logging::warning_count > 0}
} -result 1

test ig-bunker "IsGattling=yes + Bunker=yes on building warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(GatBldg) ""
    set ::Data::rawmapdata(GatBldg) {IsGattling=yes Bunker=yes}
    setup_index
    ::Checks::validate_is_gattling
    expr {$::Logging::warning_count > 0}
} -result 1

reset_state
cleanupTests
