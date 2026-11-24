#----------------------------------------------------------------------------------------------------------
# test_next_particle.tcl - Unit tests for checks/next_particle.tcl
# Tests: NextParticle + BehavesLike=Smoke conflict detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "next_particle.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::particles
    array unset ::Data::particlesys
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
# Test 1: No NextParticle set — should pass
# --------------------------------------------------------------------------
test np-no-next "No NextParticle set" -body {
    reset_state
    set ::Data::particles(0) "Smoke1"
    set_raw Smoke1 {BehavesLike=Smoke}
    setup_index
    ::Checks::validate_next_particle
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: NextParticle + BehavesLike=Smoke — should warn
# --------------------------------------------------------------------------
test np-smoke-conflict "NextParticle + BehavesLike=Smoke warns" -body {
    reset_state
    set ::Data::particles(0) "Smoke1"
    set ::Data::rawmapdata(Smoke1) [list "NextParticle=Smoke2" "BehavesLike=Smoke"]
    setup_index
    ::Checks::validate_next_particle
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: NextParticle without BehavesLike=Smoke — should pass
# --------------------------------------------------------------------------
test np-different-behavior "NextParticle with non-Smoke BehavesLike is OK" -body {
    reset_state
    set ::Data::particles(0) "Flame1"
    set ::Data::rawmapdata(Flame1) [list "NextParticle=Flame2" "BehavesLike=Fire"]
    setup_index
    ::Checks::validate_next_particle
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
