package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks land_targeting.tcl]

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

test lt-no-land "Vehicle without LandTargeting" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TestVeh) ""
    set ::Data::rawmapdata(TestVeh) {LandTargeting=0}
    setup_index
    ::Checks::validate_land_targeting
    expr {$::Logging::warning_count == 0}
} -result 1

test lt-gattling "LandTargeting + IsGattling warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(GatVeh) ""
    set ::Data::rawmapdata(GatVeh) {LandTargeting=1 IsGattling=yes}
    setup_index
    ::Checks::validate_land_targeting
    expr {$::Logging::warning_count > 0}
} -result 1

test lt-deployer "LandTargeting + Deployer + DeployFire warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(DepVeh) ""
    set ::Data::rawmapdata(DepVeh) {LandTargeting=2 Deployer=yes DeployFire=yes}
    setup_index
    ::Checks::validate_land_targeting
    expr {$::Logging::warning_count > 0}
} -result 1

reset_state
cleanupTests
