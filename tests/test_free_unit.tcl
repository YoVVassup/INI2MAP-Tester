package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks free_unit.tcl]

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

test fu-expensive "FreeUnit costs more than building warns" -body {
    reset_state
    set ::Data::buildings(BARR) ""
    set ::Data::rawmapdata(BARR) {FreeUnit=E1 Cost=500}
    set ::Data::infantry(E1) ""
    set ::Data::rawmapdata(E1) {Cost=600}
    setup_index
    ::Checks::validate_free_unit
    expr {$::Logging::warning_count > 0}
} -result 1

test fu-invalid "FreeUnit refers to unknown type warns" -body {
    reset_state
    set ::Data::buildings(BARR) ""
    set ::Data::rawmapdata(BARR) {FreeUnit=BOGUS Cost=1000}
    setup_index
    ::Checks::validate_free_unit
    expr {$::Logging::warning_count > 0}
} -result 1

test fu-lowbonus "UnitsCostBonus <= 0.01 warns" -body {
    reset_state
    set ::Data::buildings(BARR) ""
    set ::Data::rawmapdata(BARR) {UnitsCostBonus=0.005}
    setup_index
    ::Checks::validate_free_unit
    expr {$::Logging::warning_count > 0}
} -result 1

reset_state
cleanupTests
