#----------------------------------------------------------------------------------------------------------
# test_tubes_limit.tcl - Unit tests for checks/tubes_limit.tcl
# Tests: [Tubes] section 127-entry limit detection
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
source [file join $script_dir "checks" "tubes_limit.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::rawmapdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

# --------------------------------------------------------------------------
# Test 1: No Tubes section — should pass
# --------------------------------------------------------------------------
test tl-no-tubes "No Tubes section is OK" -body {
    reset_state
    ::Checks::validate_tubes_limit
    expr {$::Logging::error_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Tubes with 10 entries — should pass
# --------------------------------------------------------------------------
test tl-under "Under limit is OK" -body {
    reset_state
    set lines {}
    for {set i 0} {$i < 10} {incr i} {
        lappend lines "$i=1,1,0,1,1,0"
    }
    set ::Data::rawmapdata(Tubes) $lines
    ::Checks::validate_tubes_limit
    expr {$::Logging::error_count == 0 && $::Logging::warning_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Tubes with 128 entries — should error
# --------------------------------------------------------------------------
test tl-over "Over limit errors" -body {
    reset_state
    set lines {}
    for {set i 0} {$i < 128} {incr i} {
        lappend lines "$i=1,1,0,1,1,0"
    }
    set ::Data::rawmapdata(Tubes) $lines
    ::Checks::validate_tubes_limit
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: Tubes with 127 entries — should warn (approaching limit, not error)
# --------------------------------------------------------------------------
test tl-exact "Exactly 127 warns but no error" -body {
    reset_state
    set lines {}
    for {set i 0} {$i < 127} {incr i} {
        lappend lines "$i=1,1,0,1,1,0"
    }
    set ::Data::rawmapdata(Tubes) $lines
    ::Checks::validate_tubes_limit
    expr {$::Logging::error_count == 0 && $::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Tubes with 110 entries — should warn (approaching limit)
# --------------------------------------------------------------------------
test tl-approaching "Approaching limit warns" -body {
    reset_state
    set lines {}
    for {set i 0} {$i < 110} {incr i} {
        lappend lines "$i=1,1,0,1,1,0"
    }
    set ::Data::rawmapdata(Tubes) $lines
    ::Checks::validate_tubes_limit
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 6: syntactically invalid tube entries warn (B20)
# --------------------------------------------------------------------------
test tl-invalid-syntax "Invalid tube entry warns without error" -body {
    reset_state
    set ::Data::rawmapdata(Tubes) {
        0=1,1,0,1,1,0
        1=Entry
        2=0,1,0,1,1,0
        3=1,1,9,1,1,0
    }
    ::Checks::validate_tubes_limit
    expr {$::Logging::error_count == 0 && $::Logging::warning_count == 3}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
