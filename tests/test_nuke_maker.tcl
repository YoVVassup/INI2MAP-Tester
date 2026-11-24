#----------------------------------------------------------------------------------------------------------
# test_nuke_maker.tcl - Unit tests for checks/nuke_maker.tcl
# Tests: NukeMaker warhead flag conflict with ShrapnelWeapon/AirburstWeapon
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "nuke_maker.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::weapons
    array unset ::Data::warheads
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
# Test 1: No NukeMaker warheads — should pass
# --------------------------------------------------------------------------
test nm-no-nukemaker "No NukeMaker warheads" -body {
    reset_state
    set ::Data::warheads(0) "Fire"
    set ::Data::rawmapdata(Fire) {NukeMaker=no}
    setup_index
    ::Checks::validate_nuke_maker
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: NukeMaker=yes warhead + ShrapnelWeapon on projectile — should warn
# --------------------------------------------------------------------------
test nm-shrapnel-conflict "NukeMaker + ShrapnelWeapon warns" -body {
    reset_state
    set ::Data::warheads(0) "Nuke"
    set ::Data::rawmapdata(Nuke) {NukeMaker=yes}
    set ::Data::weapons(0) "NukeGun"
    set ::Data::rawmapdata(NukeGun) {Warhead=Nuke}
    set ::Data::rawmapdata(NukeGun) [list "Warhead=Nuke" "Projectile=Invis"]
    set ::Data::projectiles(0) "Invis"
    set ::Data::rawmapdata(Invis) {ShrapnelWeapon=Shrapnel}
    setup_index
    ::Checks::validate_nuke_maker
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: NukeMaker weapon as ShrapnelWeapon sub-weapon in YR — should warn
# --------------------------------------------------------------------------
test nm-shrapnel-subweapon "NukeMaker as sub-weapon warns in YR" -body {
    reset_state
    set ::Data::warheads(0) "Nuke"
    set ::Data::rawmapdata(Nuke) {NukeMaker=yes}
    set ::Data::weapons(0) "Master"
    set ::Data::rawmapdata(Master) {ShrapnelWeapon=SubNuke}
    set ::Data::weapons(1) "SubNuke"
    set ::Data::rawmapdata(SubNuke) {Warhead=Nuke}
    setup_index
    ::Checks::validate_nuke_maker
    expr {$::Logging::warning_count > 0}
} -result 1

reset_state
cleanupTests
