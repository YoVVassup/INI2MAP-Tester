#----------------------------------------------------------------------------------------------------------
# test_rot_aircraft.tcl - Unit tests for checks/rot_aircraft.tcl
# Tests: Aircraft ROT < 2 with non-Inviso projectile detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "rot_aircraft.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::aircraft
    array unset ::Data::weapons
    array unset ::Data::projectiles
    set ::Data::gamemode "yr"
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: ROT=0 with non-Inviso projectile — should warn
# --------------------------------------------------------------------------
test ra-rot0-noninviso "ROT=0 with non-Inviso warns" -body {
    reset_state
    set ::Data::aircraft(HIND) ""
    set ::Data::rawmapdata(HIND) [list "ROT=0" "Primary=Gun"]
    set ::Data::weapons(0) "Gun"
    set ::Data::rawmapdata(Gun) {Projectile=InvisProj}
    set ::Data::projectiles(0) "InvisProj"
    set ::Data::rawmapdata(InvisProj) {Inviso=no}
    setup_index
    ::Checks::validate_rot_aircraft
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: ROT=1 with Inviso projectile — should pass
# --------------------------------------------------------------------------
test ra-rot1-inviso "ROT=1 with Inviso projectile is OK" -body {
    reset_state
    set ::Data::aircraft(HIND) ""
    set ::Data::rawmapdata(HIND) [list "ROT=1" "Primary=Gun"]
    set ::Data::weapons(0) "Gun"
    set ::Data::rawmapdata(Gun) {Projectile=InvisProj}
    set ::Data::projectiles(0) "InvisProj"
    set ::Data::rawmapdata(InvisProj) {Inviso=yes}
    setup_index
    ::Checks::validate_rot_aircraft
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: ROT=2 with non-Inviso projectile — should pass (ROT >= 2)
# --------------------------------------------------------------------------
test ra-rot2 "ROT=2 is always OK" -body {
    reset_state
    set ::Data::aircraft(HIND) ""
    set ::Data::rawmapdata(HIND) [list "ROT=2" "Primary=Gun"]
    set ::Data::weapons(0) "Gun"
    set ::Data::rawmapdata(Gun) {Projectile=InvisProj}
    set ::Data::projectiles(0) "InvisProj"
    set ::Data::rawmapdata(InvisProj) {Inviso=no}
    setup_index
    ::Checks::validate_rot_aircraft
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
