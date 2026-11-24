#----------------------------------------------------------------------------------------------------------
# test_temporal_particle.tcl - Unit tests for checks/temporal_particle.tcl
# Tests: Temporal=yes + Particle detection
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
source [file join $script_dir "checks" "temporal_particle.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::warheads
    array unset ::Data::weapons
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
# Test 1: No Temporal warheads — should pass
# --------------------------------------------------------------------------
test tp-no-temporal "No Temporal warheads" -body {
    reset_state
    set ::Data::warheads(0) "Fire"
    set ::Data::rawmapdata(Fire) {Temporal=no}
    setup_index
    ::Checks::validate_temporal_particle
    expr {$::Logging::notice_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Temporal=yes warhead, no weapons — notice only
# --------------------------------------------------------------------------
test tp-temporal-no-weapons "Temporal=yes, no weapons using it" -body {
    reset_state
    set ::Data::warheads(0) "Time"
    set ::Data::rawmapdata(Time) {Temporal=yes}
    setup_index
    ::Checks::validate_temporal_particle
    expr {$::Logging::notice_count == 1 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Temporal=yes + weapon with Particle — warning
# --------------------------------------------------------------------------
test tp-temporal-with-particle "Temporal=yes weapon has Particle" -body {
    reset_state
    set ::Data::warheads(0) "Time"
    set ::Data::rawmapdata(Time) {Temporal=yes}
    set ::Data::weapons(0) "ChronoBeam"
    set ::Data::rawmapdata(ChronoBeam) {Warhead=Time Particle=ChronoParticle}
    setup_index
    ::Checks::validate_temporal_particle
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: Temporal=yes + weapon without Particle — notice only
# --------------------------------------------------------------------------
test tp-temporal-no-particle "Temporal=yes weapon has no Particle" -body {
    reset_state
    set ::Data::warheads(0) "Time"
    set ::Data::rawmapdata(Time) {Temporal=yes}
    set ::Data::weapons(0) "ChronoBeam"
    set ::Data::rawmapdata(ChronoBeam) {Warhead=Time}
    setup_index
    ::Checks::validate_temporal_particle
    expr {$::Logging::notice_count == 1 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Non-temporal weapon with Particle — should pass
# --------------------------------------------------------------------------
test tp-non-temporal-particle "Non-temporal weapon with Particle is OK" -body {
    reset_state
    set ::Data::warheads(0) "Fire"
    set ::Data::rawmapdata(Fire) {Temporal=no}
    set ::Data::weapons(0) "FlameGun"
    set ::Data::rawmapdata(FlameGun) {Warhead=Fire Particle=FlameParticle}
    setup_index
    ::Checks::validate_temporal_particle
    expr {$::Logging::notice_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 6: Two temporal warheads, one with particle weapon — 2 notices + 1 warning
# --------------------------------------------------------------------------
test tp-mixed "Two temporal warheads, one particle conflict" -body {
    reset_state
    set ::Data::warheads(0) "Time"
    set ::Data::rawmapdata(Time) {Temporal=yes}
    set ::Data::warheads(1) "Chrono"
    set ::Data::rawmapdata(Chrono) {Temporal=yes}
    set ::Data::weapons(0) "ChronoBeam"
    set ::Data::rawmapdata(ChronoBeam) {Warhead=Time Particle=ChronoParticle}
    setup_index
    ::Checks::validate_temporal_particle
    expr {$::Logging::notice_count == 2 && $::Logging::warning_count == 1}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
