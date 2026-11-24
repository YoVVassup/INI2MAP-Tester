#----------------------------------------------------------------------------------------------------------
# test_verses_map_override.tcl - Unit tests for checks/verses_map_override.tcl
# Tests: Verses override in map INI detection
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
source [file join $script_dir "checks" "verses_map_override.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::rawmapdata
    set ::Data::gamemode "yr"
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

# --------------------------------------------------------------------------
# Test 1: Verses override in YR — should notice
# --------------------------------------------------------------------------
test vmo-yr "Verses override in YR notices" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::rawmapdata(SOMEUNIT) {Verses=100%,0%,0%,100%,100%,100%,100%,100%,100%,100%}
    ::Checks::validate_verses_map_override
    expr {$::Logging::notice_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Verses override in Ares — should notice (different message)
# --------------------------------------------------------------------------
test vmo-ares "Verses override in Ares notices" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::rawmapdata(SOMEUNIT) {Verses=100%,0%,0%,100%,100%,100%,100%,100%,100%,100%}
    ::Checks::validate_verses_map_override
    expr {$::Logging::notice_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: No Verses — should pass
# --------------------------------------------------------------------------
test vmo-none "No Verses is OK" -body {
    reset_state
    set ::Data::rawmapdata(SOMEUNIT) {Strength=1000}
    ::Checks::validate_verses_map_override
    expr {$::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Empty rawmapdata — should pass
# --------------------------------------------------------------------------
test vmo-empty "Empty rawmapdata is OK" -body {
    reset_state
    ::Checks::validate_verses_map_override
    expr {$::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
