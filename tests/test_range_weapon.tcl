#----------------------------------------------------------------------------------------------------------
# test_range_weapon.tcl - Unit tests for checks/range_weapon.tcl
# Tests: Weapon Range validation including Range=-2 and excessive range
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "range_weapon.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::weapons
    array unset ::Data::projectiles
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::buildings
    set ::Data::gamemode "yr"
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

proc set_raw {section line} {
    set ::Data::rawmapdata($section) [list $line]
}

# --------------------------------------------------------------------------
# Test 1: Range > 100 — should warn about performance
# --------------------------------------------------------------------------
test rw-excessive "Excessive Range warns" -body {
    reset_state
    set ::Data::weapons(0) "MEGA"
    set_raw MEGA {Range=200}
    setup_index
    ::Checks::validate_range_weapon
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Range=-2 on aircraft — should warn
# --------------------------------------------------------------------------
test rw-aircraft-infinite "Range=-2 on aircraft warns" -body {
    reset_state
    set ::Data::weapons(0) "INVISGUN"
    set_raw INVISGUN {Range=-2}
    set ::Data::aircraft(BADGE) ""
    set_raw BADGE {Primary=INVISGUN}
    setup_index
    ::Checks::validate_range_weapon
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Normal range weapon — should pass
# --------------------------------------------------------------------------
test rw-normal "Normal range weapon is OK" -body {
    reset_state
    set ::Data::weapons(0) "GUN"
    set_raw GUN {Range=5}
    setup_index
    ::Checks::validate_range_weapon
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
