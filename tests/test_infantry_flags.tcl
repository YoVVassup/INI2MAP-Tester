package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks infantry_flags.tcl]

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
    array unset ::Data::superweapons
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test if-agent-assaulter "Agent+Assaulter errors" -body {
    reset_state
    set ::Data::infantry(SPY) ""
    set ::Data::rawmapdata(SPY) {Agent=yes Assaulter=yes}
    setup_index
    ::Checks::validate_infantry_flags
    expr {$::Logging::error_count > 0}
} -result 1

test if-assaulter-noc4 "Assaulter+C4=no warns" -body {
    reset_state
    set ::Data::infantry(SPY) ""
    set ::Data::rawmapdata(SPY) {Assaulter=yes C4=no}
    setup_index
    ::Checks::validate_infantry_flags
    expr {$::Logging::warning_count > 0}
} -result 1

test if-clean "No conflicting flags" -body {
    reset_state
    set ::Data::infantry(E1) ""
    set ::Data::rawmapdata(E1) {Agent=no Assaulter=no Engineer=no C4=no IvanBomb=no}
    setup_index
    ::Checks::validate_infantry_flags
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

reset_state
cleanupTests
