#----------------------------------------------------------------------------------------------------------
# test_cloning.tcl - Unit tests for checks/cloning.tcl
# Tests: Cloning + Refinery conflict detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks cloning.tcl]

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
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: Cloning=yes + Refinery=yes — should error
# --------------------------------------------------------------------------
test cl-conflict "Cloning+Refinery errors" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(PYLE) ""
    set ::Data::rawmapdata(BuildingTypes) {0=PYLE}
    set ::Data::rawmapdata(PYLE) {Cloning=yes Refinery=yes}
    setup_index
    ::Checks::validate_cloning
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Cloning=yes without Refinery — should pass
# --------------------------------------------------------------------------
test cl-clean "Cloning without Refinery is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(PYLE) ""
    set ::Data::rawmapdata(BuildingTypes) {0=PYLE}
    set ::Data::rawmapdata(PYLE) {Cloning=yes}
    setup_index
    ::Checks::validate_cloning
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Refinery=yes without Cloning — should pass
# --------------------------------------------------------------------------
test cl-refinery "Refinery without Cloning is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::buildings(SREF) ""
    set ::Data::rawmapdata(BuildingTypes) {0=SREF}
    set ::Data::rawmapdata(SREF) {Refinery=yes}
    setup_index
    ::Checks::validate_cloning
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
