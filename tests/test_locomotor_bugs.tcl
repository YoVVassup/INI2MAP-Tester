#----------------------------------------------------------------------------------------------------------
# test_locomotor_bugs.tcl - Unit tests for checks/locomotor_bugs.tcl
# Tests: Various Locomotor combination bug detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

# --------------------------------------------------------------------------
# Source required modules
# --------------------------------------------------------------------------
set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "locomotor_bugs.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::rawmapdata
    set ::Data::gamemode "yr"
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --- Hover tests ---

# --------------------------------------------------------------------------
# Test 1: Hover + IsSimpleDeployer + DeployToLand in YR — should warn
# --------------------------------------------------------------------------
test lb-hover "Hover+Deployer+DeployLand warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(ASSAULT) ""
    set ::Data::rawmapdata(ASSAULT) {Locomotor={4A582742-9839-11d1-B709-00A024DDAFD1} IsSimpleDeployer=yes DeployToLand=yes}
    setup_index
    ::Checks::validate_locomotor_bugs
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Hover + IsSimpleDeployer in Phobos — should pass (fixed)
# --------------------------------------------------------------------------
test lb-hover-phobos "Hover+Deployer in Phobos OK" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::vehicles(ASSAULT) ""
    set ::Data::rawmapdata(ASSAULT) {Locomotor={4A582742-9839-11d1-B709-00A024DDAFD1} IsSimpleDeployer=yes DeployToLand=yes}
    setup_index
    ::Checks::validate_locomotor_bugs
    expr {$::Logging::warning_count == 0}
} -result 1

# --- Tunnel tests ---

# --------------------------------------------------------------------------
# Test 3: Tunnel + InfantryType — should error
# --------------------------------------------------------------------------
test lb-tunnel-infantry "Tunnel+Infantry errors" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(TUNNEL) ""
    set ::Data::rawmapdata(TUNNEL) {Locomotor={4A582743-9839-11d1-B709-00A024DDAFD1}}
    setup_index
    ::Checks::validate_locomotor_bugs
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: Tunnel + VehicleType — should pass (only infantry crashes)
# --------------------------------------------------------------------------
test lb-tunnel-vehicle "Tunnel+Vehicle is OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(MINE) ""
    set ::Data::rawmapdata(MINE) {Locomotor={4A582743-9839-11d1-B709-00A024DDAFD1}}
    setup_index
    ::Checks::validate_locomotor_bugs
    expr {$::Logging::error_count == 0}
} -result 1

# --- Jumpjet tests ---

# --------------------------------------------------------------------------
# Test 5: Jumpjet + Harvester in YR — should warn
# --------------------------------------------------------------------------
test lb-jumpjet-harv "Jumpjet+Harvester warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(CRYS) ""
    set ::Data::rawmapdata(CRYS) {Locomotor={92612C46-F71F-11d1-AC9F-006008055BB5} Harvester=yes}
    setup_index
    ::Checks::validate_locomotor_bugs
    expr {$::Logging::warning_count > 0}
} -result 1

# --- Rocket tests ---

# --------------------------------------------------------------------------
# Test 6: Rocket + Teleporter VehicleType — should warn
# --------------------------------------------------------------------------
test lb-rocket-tele "Rocket+Teleporter warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(CHRONO) ""
    set ::Data::rawmapdata(CHRONO) {Locomotor={B7B49766-E576-11d3-9BD9-00104B972FE8} Teleporter=yes}
    setup_index
    ::Checks::validate_locomotor_bugs
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
