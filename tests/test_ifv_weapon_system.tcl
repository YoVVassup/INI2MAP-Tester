package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks ifv_weapon_system.tcl]

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

test ifv-noturret "Gunner without TurretCount warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(IFV) ""
    set ::Data::rawmapdata(IFV) {Gunner=yes}
    setup_index
    ::Checks::validate_ifv_weapon_system
    expr {$::Logging::warning_count > 0}
} -result 1

test ifv-overflow "TurretCount > 17 in YR warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(IFV) ""
    set ::Data::rawmapdata(IFV) {Gunner=yes TurretCount=20}
    setup_index
    ::Checks::validate_ifv_weapon_system
    expr {$::Logging::warning_count > 0}
} -result 1

test ifv-ok "Valid TurretCount no warning" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(IFV) ""
    set ::Data::rawmapdata(IFV) {Gunner=yes TurretCount=5}
    setup_index
    ::Checks::validate_ifv_weapon_system
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

reset_state
cleanupTests
