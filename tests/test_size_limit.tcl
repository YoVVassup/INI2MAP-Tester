package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks size_limit.tcl]

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

test szl-no-issues "No SizeLimit issues" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(TestVeh) ""
    set ::Data::rawmapdata(TestVeh) {SizeLimit=1}
    setup_index
    ::Checks::validate_size_limit
    expr {$::Logging::warning_count == 0}
} -result 1

test szl-amphibious-crash "Amphibious transport with SizeLimit>2 warns" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(AmphTransport) ""
    set ::Data::rawmapdata(AmphTransport) {SizeLimit=5 SpeedType=Amphibious}
    setup_index
    ::Checks::validate_size_limit
    expr {$::Logging::warning_count > 0}
} -result 1

test szl-extreme-value "SizeLimit>1000 generates notice" -body {
    reset_state
    set ::Data::gamemode "yr"
    set ::Data::vehicles(HugeTransport) ""
    set ::Data::rawmapdata(HugeTransport) {SizeLimit=5000}
    setup_index
    ::Checks::validate_size_limit
    expr {$::Logging::notice_count > 0}
} -result 1

reset_state
cleanupTests
