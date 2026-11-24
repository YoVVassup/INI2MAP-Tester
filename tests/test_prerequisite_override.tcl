#----------------------------------------------------------------------------------------------------------
# test_prerequisite_override.tcl - Unit tests for checks/prerequisite_override.tcl
# Tests: PrerequisiteOverride multi-value detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

# --------------------------------------------------------------------------
# Source required modules
# --------------------------------------------------------------------------
set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "prerequisite_override.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::buildings
    array unset ::Data::rawmapdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Helper: set rawmapdata as single line (simulates file read)
# --------------------------------------------------------------------------
proc set_raw {section line} {
    set ::Data::rawmapdata($section) [list $line]
}

# --------------------------------------------------------------------------
# Test 1: No PrerequisiteOverride — should pass
# --------------------------------------------------------------------------
test po-none "No PrerequisiteOverride set" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set_raw TANK {Prerequisite=GDFACT}
    setup_index
    ::Checks::validate_prerequisite_override
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Single PrerequisiteOverride — should pass
# --------------------------------------------------------------------------
test po-single "Single PrerequisiteOverride is OK" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set_raw TANK {PrerequisiteOverride=GDFACT}
    setup_index
    ::Checks::validate_prerequisite_override
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Multiple PrerequisiteOverride — should warn
# --------------------------------------------------------------------------
test po-multiple "Multiple PrerequisiteOverride warns" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set_raw TANK "PrerequisiteOverride=GDFACT,GDFACTB"
    setup_index
    ::Checks::validate_prerequisite_override
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: PrerequisiteOverride with spaces — should warn
# --------------------------------------------------------------------------
test po-spaces "PrerequisiteOverride with spaces warns" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set ::Data::rawmapdata(TANK) [list "PrerequisiteOverride=GDFACT , GDFACTB"]
    setup_index
    ::Checks::validate_prerequisite_override
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Empty PrerequisiteOverride — should pass
# --------------------------------------------------------------------------
test po-empty "Empty PrerequisiteOverride is OK" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set_raw TANK {PrerequisiteOverride=}
    setup_index
    ::Checks::validate_prerequisite_override
    expr {$::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 6: Multiple TechnoTypes, one bad — 1 warning
# --------------------------------------------------------------------------
test po-mixed "Only one bad PrerequisiteOverride" -body {
    reset_state
    set ::Data::vehicles(TANK) ""
    set_raw TANK {PrerequisiteOverride=GDFACT}
    set ::Data::vehicles(TANK2) ""
    set_raw TANK2 "PrerequisiteOverride=GDFACT,GDFACTB"
    setup_index
    ::Checks::validate_prerequisite_override
    expr {$::Logging::warning_count == 1}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
