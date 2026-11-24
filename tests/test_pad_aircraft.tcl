#----------------------------------------------------------------------------------------------------------
# test_pad_aircraft.tcl - Unit tests for checks/pad_aircraft.tcl
# Tests: PadAircraft entries with valid Dock buildings
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "pad_aircraft.tcl"]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::aircraft
    array unset ::Data::buildings
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: PadAircraft references nonexistent aircraft — should warn
# --------------------------------------------------------------------------
test pa-missing-aircraft "PadAircraft references nonexistent aircraft" -body {
    reset_state
    set ::Data::rawmapdata(General) {PadAircraft=NDDE}
    set ::Data::buildings(HPAD) ""
    set ::Data::rawmapdata(HPAD) {Helipad=yes}
    set ::Data::aircraft(HIND) ""
    setup_index
    ::Checks::validate_pad_aircraft
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: PadAircraft aircraft has no Dock — should warn
# --------------------------------------------------------------------------
test pa-no-dock "PadAircraft aircraft has no Dock" -body {
    reset_state
    set ::Data::rawmapdata(General) {PadAircraft=HIND}
    set ::Data::aircraft(HIND) ""
    set ::Data::rawmapdata(HIND) {}
    set ::Data::buildings(HPAD) ""
    set ::Data::rawmapdata(HPAD) {Helipad=yes}
    setup_index
    ::Checks::validate_pad_aircraft
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: PadAircraft with valid Dock building — should pass
# --------------------------------------------------------------------------
test pa-valid "PadAircraft with valid Dock is OK" -body {
    reset_state
    set ::Data::rawmapdata(General) {PadAircraft=HIND}
    set ::Data::aircraft(HIND) ""
    set ::Data::rawmapdata(HIND) {Dock=HPAD}
    set ::Data::buildings(HPAD) ""
    set ::Data::rawmapdata(HPAD) {Helipad=yes}
    setup_index
    ::Checks::validate_pad_aircraft
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
