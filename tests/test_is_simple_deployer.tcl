package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks is_simple_deployer.tcl]

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

set jumpjet_clsid "{92612C46-F71F-11d1-AC9F-006008055BB5}"

test isd-ra2 "Skipped in RA2" -body {
    reset_state
    set ::Data::gamemode "ra2"
    set ::Data::vehicles(TestVeh) ""
    set ::Data::rawmapdata(TestVeh) {IsSimpleDeployer=yes Locomotor=$jumpjet_clsid}
    setup_index
    ::Checks::validate_is_simple_deployer
    expr {$::Logging::warning_count == 0}
} -result 1

test isd-jumpjet-no-deploy "Jumpjet IsSimpleDeployer without DeployToLand warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(JumpJet) ""
    set ::Data::rawmapdata(JumpJet) "IsSimpleDeployer=yes Locomotor=$jumpjet_clsid"
    setup_index
    ::Checks::validate_is_simple_deployer
    expr {$::Logging::warning_count > 0}
} -result 1

test isd-ground-unit "Ground unit with IsSimpleDeployer OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(GrndVeh) ""
    set ::Data::rawmapdata(GrndVeh) {IsSimpleDeployer=yes Locomotor={4A582742-9839-11d1-B709-00A024DDAFD1}}
    setup_index
    ::Checks::validate_is_simple_deployer
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
