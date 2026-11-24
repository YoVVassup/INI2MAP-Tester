#----------------------------------------------------------------------------------------------------------
# test_requires_stolen_tech.tcl - Unit tests for checks/requires_stolen_tech.tcl
# Tests: RequiresStolen*Tech flags with AI build detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "requires_stolen_tech.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
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

# --------------------------------------------------------------------------
# Test 1: RequiresStolenAlliedTech=yes on non-building — should warn
# --------------------------------------------------------------------------
test rst-infantry "Stolen tech on infantry warns" -body {
    reset_state
    set ::Data::infantry(GHOST) ""
    set ::Data::rawmapdata(GHOST) {RequiresStolenAlliedTech=yes}
    setup_index
    ::Checks::validate_requires_stolen_tech
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: RequiresStolenSovietTech=yes on building with AIBuildThis — should warn
# --------------------------------------------------------------------------
test rst-ai-build "Stolen tech building with AIBuildThis warns" -body {
    reset_state
    set ::Data::buildings(SECRET) ""
    set ::Data::rawmapdata(SECRET) [list "RequiresStolenSovietTech=yes" "AIBuildThis=yes"]
    setup_index
    ::Checks::validate_requires_stolen_tech
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: No stolen tech flags — should pass
# --------------------------------------------------------------------------
test rst-none "No stolen tech flags is OK" -body {
    reset_state
    set ::Data::infantry(GI) ""
    set ::Data::rawmapdata(GI) {Primary=M60}
    setup_index
    ::Checks::validate_requires_stolen_tech
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
