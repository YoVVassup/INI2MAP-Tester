package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks light_size.tcl]

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

test ls-no-particlesys "No particle systems defined" -body {
    reset_state
    set ::Data::gamemode "yr"
    setup_index
    ::Checks::validate_light_size
    expr {$::Logging::error_count == 0}
} -result 1

test ls-over-75 "LightSize > 75 causes error" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::particlesys(0) "ExplosionSys"
    set ::Data::rawmapdata(ExplosionSys) {LightSize=100}
    setup_index
    ::Checks::validate_light_size
    expr {$::Logging::error_count > 0}
} -result 1

test ls-valid "LightSize=50 is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::particlesys(0) "SafeSys"
    set ::Data::rawmapdata(SafeSys) {LightSize=50}
    setup_index
    ::Checks::validate_light_size
    expr {$::Logging::error_count == 0}
} -result 1

reset_state
cleanupTests
