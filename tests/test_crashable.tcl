package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks crashable.tcl]

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
    set ::Data::gamemode "yr"
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test crash-jj "Jumpjet with Crashable=no warns in YR" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::infantry(DEF) ""
    set ::Data::rawmapdata(DEF) {Crashable=no Locomotor="{92612C46-F71F-11d1-AC9F-006008055BB5}"}
    setup_index
    ::Checks::validate_crashable
    expr {$::Logging::warning_count > 0}
} -result 1

test crash-jj-ares "Jumpjet with Crashable=no notices in Ares" -body {
    reset_state
    set ::Data::gamemode "ares"
    set ::Data::infantry(DEF) ""
    set ::Data::rawmapdata(DEF) {Crashable=no Locomotor="{92612C46-F71F-11d1-AC9F-006008055BB5}"}
    setup_index
    ::Checks::validate_crashable
    expr {$::Logging::notice_count > 0}
} -result 1

test crash-hover "Hover with Crashable=no warns" -body {
    reset_state
    set ::Data::vehicles(HOVER) ""
    set ::Data::rawmapdata(HOVER) {Crashable=no Locomotor="{4A582742-9839-11d1-B709-00A024DDAFD1}"}
    setup_index
    ::Checks::validate_crashable
    expr {$::Logging::warning_count > 0}
} -result 1

test crash-clean "Crashable=yes no warning" -body {
    reset_state
    set ::Data::vehicles(HOVER) ""
    set ::Data::rawmapdata(HOVER) {Crashable=yes Locomotor="{4A582742-9839-11d1-B709-00A024DDAFD1}"}
    setup_index
    ::Checks::validate_crashable
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
