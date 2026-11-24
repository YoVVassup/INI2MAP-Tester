#----------------------------------------------------------------------------------------------------------
# test_wind_effect_particles.tcl - Unit tests for checks/wind_effect_particles.tcl
# Tests: WindEffect > 10 crash detection
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
source [file join $script_dir "checks" "wind_effect_particles.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::particlesys
    array unset ::Data::rawmapdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: WindEffect=15 — should error
# --------------------------------------------------------------------------
test wep-over "WindEffect>10 errors" -body {
    reset_state
    set ::Data::particlesys(0) "Fire"
    set ::Data::rawmapdata(Fire) {WindEffect=15}
    setup_index
    ::Checks::validate_wind_effect_particles
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: WindEffect=10 — should pass
# --------------------------------------------------------------------------
test wep-exact "WindEffect=10 is OK" -body {
    reset_state
    set ::Data::particlesys(0) "Fire"
    set ::Data::rawmapdata(Fire) {WindEffect=10}
    setup_index
    ::Checks::validate_wind_effect_particles
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: WindEffect=5 — should pass
# --------------------------------------------------------------------------
test wep-ok "WindEffect=5 is OK" -body {
    reset_state
    set ::Data::particlesys(0) "Fire"
    set ::Data::rawmapdata(Fire) {WindEffect=5}
    setup_index
    ::Checks::validate_wind_effect_particles
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No WindEffect — should pass
# --------------------------------------------------------------------------
test wep-none "No WindEffect is OK" -body {
    reset_state
    set ::Data::particlesys(0) "Fire"
    set ::Data::rawmapdata(Fire) {Damage=10}
    setup_index
    ::Checks::validate_wind_effect_particles
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
