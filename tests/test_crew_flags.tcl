package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks crew_flags.tcl]

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
    array unset ::Data::rulesdata
}

proc setup_index {} { ::Checks::build_index }

test crew-missing "Missing Engineer in General warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(E1) ""
    set ::Data::rawmapdata(General) {Technician=E1 AlliedCrew=E1 SovietCrew=E1 ThirdCrew=E1}
    setup_index
    ::Checks::validate_crew_flags
    expr {$::Logging::warning_count > 0}
} -result 1

test crew-invalid "Engineer refers to non-existent InfantryType" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(E1) ""
    set ::Data::rawmapdata(General) {Technician=E1 Engineer=BOGUS AlliedCrew=E1 SovietCrew=E1 ThirdCrew=E1}
    setup_index
    ::Checks::validate_crew_flags
    expr {$::Logging::error_count > 0}
} -result 1

test crew-ok "All crew flags defined with valid types" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(E1) ""
    set ::Data::rawmapdata(General) {Technician=E1 Engineer=E1 AlliedCrew=E1 SovietCrew=E1 ThirdCrew=E1}
    setup_index
    ::Checks::validate_crew_flags
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

reset_state
cleanupTests
