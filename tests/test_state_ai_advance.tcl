package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks state_ai_advance.tcl]

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
    array unset ::Data::rulesdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test sai-valid-value "StateAIAdvance=1 (default) no warn" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::rulesdata(Particles) {StateAIAdvance=1}
    setup_index
    ::Checks::validate_state_ai_advance
    expr {$::Logging::warning_count == 0 && $::Logging::notice_count == 0}
} -result 1

test sai-zero-crash "StateAIAdvance=0 warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::rulesdata(Particles) {StateAIAdvance=0}
    setup_index
    ::Checks::validate_state_ai_advance
    expr {$::Logging::warning_count > 0}
} -result 1

test sai-large-value "StateAIAdvance=200 notices" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::rulesdata(Particles) {StateAIAdvance=200}
    setup_index
    ::Checks::validate_state_ai_advance
    expr {$::Logging::notice_count > 0}
} -result 1

reset_state
cleanupTests
