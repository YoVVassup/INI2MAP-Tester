package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks damage_particle_systems_infantry.tcl]

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

test dps-cyborg-nodps "Cyborg without DamageParticleSystems warns" -body {
    reset_state
    set ::Data::infantry(CYB) ""
    set ::Data::rawmapdata(CYB) {Cyborg=yes}
    setup_index
    ::Checks::validate_damage_particle_systems_infantry
    expr {$::Logging::warning_count > 0}
} -result 1

test dps-cyborg-dps "Cyborg with DamageParticleSystems OK" -body {
    reset_state
    set ::Data::infantry(CYB) ""
    set ::Data::rawmapdata(CYB) {Cyborg=yes DamageParticleSystems=SparkSys}
    setup_index
    ::Checks::validate_damage_particle_systems_infantry
    expr {$::Logging::warning_count == 0}
} -result 1

test dps-notcyborg "Non-cyborg no warning" -body {
    reset_state
    set ::Data::infantry(E1) ""
    set ::Data::rawmapdata(E1) {Cyborg=no}
    setup_index
    ::Checks::validate_damage_particle_systems_infantry
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
