package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks is_sonic.tcl]

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

test ison-ra2 "Skipped in RA2" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::weapons(0) "SonicWeap"
    set ::Data::rawmapdata(SonicWeap) {IsSonic=yes}
    setup_index
    ::Checks::validate_is_sonic
    expr {$::Logging::warning_count == 0}
} -result 1

test ison-yr-basic "IsSonic=yes in YR warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "SonicWeap"
    set ::Data::rawmapdata(SonicWeap) {IsSonic=yes Range=5}
    setup_index
    ::Checks::validate_is_sonic
    expr {$::Logging::warning_count > 0}
} -result 1

test ison-yr-range8 "IsSonic=yes range > 8 warns about limit" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::weapons(0) "SonicWeap"
    set ::Data::rawmapdata(SonicWeap) {IsSonic=yes Range=10}
    setup_index
    ::Checks::validate_is_sonic
    expr {$::Logging::warning_count >= 2}
} -result 1

reset_state
cleanupTests
