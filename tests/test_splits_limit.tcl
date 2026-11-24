package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks splits_limit.tcl]

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
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test spl-no-splits "Projectile without Splits" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::projectiles(0) "NormProj"
    set ::Data::rawmapdata(NormProj) {Splits=no}
    setup_index
    ::Checks::validate_splits_limit
    expr {$::Logging::notice_count == 0}
} -result 1

test spl-vanilla-warns "Splits=yes in vanilla YR warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::projectiles(0) "SplitProj"
    set ::Data::rawmapdata(SplitProj) {Splits=yes}
    setup_index
    ::Checks::validate_splits_limit
    expr {$::Logging::notice_count > 0}
} -result 1

test spl-ares-no-warn "Splits=yes in Ares mode no warn" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::projectiles(0) "SplitProj"
    set ::Data::rawmapdata(SplitProj) {Splits=yes}
    setup_index
    ::Checks::validate_splits_limit
    expr {$::Logging::notice_count == 0}
} -result 1

reset_state
cleanupTests
