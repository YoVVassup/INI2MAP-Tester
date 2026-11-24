package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks fraidycat.tcl]

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

test fc-conflict "Fraidycat+Fearless+Slaved warns" -body {
    reset_state
    set ::Data::infantry(SLAVE) ""
    set ::Data::rawmapdata(SLAVE) {Fraidycat=yes Fearless=yes Slaved=yes}
    setup_index
    ::Checks::validate_fraidycat
    expr {$::Logging::warning_count > 0}
} -result 1

test fc-noslaved "Fraidycat+Fearless without Slaved OK" -body {
    reset_state
    set ::Data::infantry(SLAVE) ""
    set ::Data::rawmapdata(SLAVE) {Fraidycat=yes Fearless=yes Slaved=no}
    setup_index
    ::Checks::validate_fraidycat
    expr {$::Logging::warning_count == 0}
} -result 1

test fc-nofraidycat "Fearless+Slaved without Fraidycat OK" -body {
    reset_state
    set ::Data::infantry(SLAVE) ""
    set ::Data::rawmapdata(SLAVE) {Fraidycat=no Fearless=yes Slaved=yes}
    setup_index
    ::Checks::validate_fraidycat
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
