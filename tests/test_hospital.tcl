package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir utils.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks hospital.tcl]

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
    array unset ::Data::houses
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test hosp-ai "Hospital+Factory on AI house warns" -body {
    reset_state
    set ::Data::buildings(HOSP) ""
    set ::Data::rawmapdata(HOSP) {Hospital=yes Factory=InfantryType}
    set ::Data::houses(AI) ""
    set ::Data::rawmapdata(Structures) {0=AI,HOSP,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    set ::Data::rawmapdata(Houses) {0=AI PlayerControl=no}
    setup_index
    ::Checks::validate_hospital
    expr {$::Logging::warning_count > 0}
} -result 1

test hosp-nofactory "Hospital without Factory OK" -body {
    reset_state
    set ::Data::buildings(HOSP) ""
    set ::Data::rawmapdata(HOSP) {Hospital=yes}
    set ::Data::houses(H1) ""
    set ::Data::rawmapdata(Structures) {0=H1,HOSP,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    set ::Data::rawmapdata(Houses) {0=H1 PlayerControl=yes}
    setup_index
    ::Checks::validate_hospital
    expr {$::Logging::warning_count == 0}
} -result 1

test hosp-nohosp "Building without Hospital no warning" -body {
    reset_state
    set ::Data::buildings(BARR) ""
    set ::Data::rawmapdata(BARR) {Factory=InfantryType}
    set ::Data::houses(H1) ""
    set ::Data::rawmapdata(Structures) {0=H1,BARR,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    set ::Data::rawmapdata(Houses) {0=H1 PlayerControl=yes}
    setup_index
    ::Checks::validate_hospital
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
