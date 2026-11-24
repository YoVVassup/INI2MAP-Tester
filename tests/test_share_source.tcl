#----------------------------------------------------------------------------------------------------------
# test_share_source.tcl - Unit tests for checks/share_source.tcl
# Tests: ShareSource referencing redefined TechnoType in map data
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "share_source.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: ShareSource references redefined TechnoType — should warn
# --------------------------------------------------------------------------
test ss-redefined "ShareSource redefined in map warns" -body {
    reset_state
    set ::Data::rulesdata(VoxelAnims) {ShareSource=DECOY}
    set ::Data::rulesdata(VehicleTypes) [list "0=DECOY"]
    set ::Data::rawmapdata(VehicleTypes) [list "0=DECOY"]
    setup_index
    ::Checks::validate_share_source
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: ShareSource references valid TechnoType — should pass
# --------------------------------------------------------------------------
test ss-valid "ShareSource with valid TechnoType is OK" -body {
    reset_state
    set ::Data::rulesdata(VoxelAnims) {ShareSource=HIND}
    set ::Data::rulesdata(AircraftTypes) [list "0=HIND"]
    setup_index
    ::Checks::validate_share_source
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: No ShareSource set — should pass
# --------------------------------------------------------------------------
test ss-none "No ShareSource is OK" -body {
    reset_state
    set ::Data::rulesdata(VoxelAnims) {SomeOther=1}
    setup_index
    ::Checks::validate_share_source
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
