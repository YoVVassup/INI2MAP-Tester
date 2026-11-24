package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks dig.tcl]

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

test dig-missing "Dig references missing animation warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::rawmapdata(AudioVisual) {Dig=DigAnim}
    setup_index
    ::Checks::validate_dig
    expr {$::Logging::warning_count > 0}
} -result 1

test dig-ok "Dig references existing animation OK" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::anims(DigAnim) ""
    set ::Data::rawmapdata(AudioVisual) {Dig=DigAnim}
    setup_index
    ::Checks::validate_dig
    expr {$::Logging::warning_count == 0}
} -result 1

test dig-empty "No Dig set" -body {
    reset_state
    set ::Data::gamemode "yr"
    setup_index
    ::Checks::validate_dig
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
