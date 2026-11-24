#----------------------------------------------------------------------------------------------------------
# test_trigger_integrity.tcl - Unit tests for validators/trigger_integrity.tcl
# Tests: validate_triggers_integrity (BFS reachability)
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir map_parser.tcl]
source [file join $script_dir validators.tcl]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::triggers
    array unset ::Data::actions
    array unset ::Data::events
    array unset ::Data::tags
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
}

# --------------------------------------------------------------------------
# Test 1: Reachable trigger - no error
# --------------------------------------------------------------------------
test ti-reachable "reachable trigger produces no error" -body {
    reset_state
    # Trigger T1 is enabled (field 3 = 0)
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Triggers) {T1=Player,0,0,0,0,0}
    # Tag references T1 (no spaces in group name to avoid list splitting)
    set ::Data::rawmapdata(Tags) {Tag1=0,Grp0,T1}
    ::Validators::validate_triggers_integrity
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Unreachable trigger - error
# --------------------------------------------------------------------------
test ti-unreachable "unreachable trigger produces error" -body {
    reset_state
    # Trigger T1 is disabled (field 3 = 1)
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Triggers) {T1=Player,0,0,1,0,0}
    # Tag references T1
    set ::Data::rawmapdata(Tags) {Tag1=0,Grp0,T1}
    ::Validators::validate_triggers_integrity
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Disabled trigger enabled by another trigger - reachable
# --------------------------------------------------------------------------
test ti-enabled-by-action "disabled trigger enabled via action 53 is reachable" -body {
    reset_state
    # T1 is enabled (initial), T2 is disabled
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::triggers(T2) "Trigger Two"
    set ::Data::rawmapdata(Triggers) {
        T1=Player,0,0,0,0,0
        T2=Player,0,0,1,0,0
    }
    # T1 has action 53 that enables T2 (target is string trigger ID)
    # Format: count,act1,field,target,... (each action is 8 fields)
    set ::Data::actions(T1) "1,53,0,T2"
    # Tag references T2
    set ::Data::rawmapdata(Tags) {Tag1=0,Grp0,T2}
    ::Validators::validate_triggers_integrity
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: No tags - no errors
# --------------------------------------------------------------------------
test ti-no-tags "no tags means no errors" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Triggers) {T1=Player,0,0,0,0,0}
    ::Validators::validate_triggers_integrity
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Empty state - no errors
# --------------------------------------------------------------------------
test ti-empty "empty state produces no errors" -body {
    reset_state
    ::Validators::validate_triggers_integrity
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 6: Tag with no matching trigger - skipped
# --------------------------------------------------------------------------
test ti-tag-no-trigger "tag with no matching trigger is skipped" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Triggers) {T1=Player,0,0,0,0,0}
    # Tag references non-existent trigger
    set ::Data::rawmapdata(Tags) {Tag1=0,Grp0,T99}
    ::Validators::validate_triggers_integrity
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 7: Multiple triggers chain - all reachable
# --------------------------------------------------------------------------
test ti-chain "chain of enabled triggers all reachable" -body {
    reset_state
    set ::Data::triggers(T1) "T1"
    set ::Data::triggers(T2) "T2"
    set ::Data::triggers(T3) "T3"
    set ::Data::rawmapdata(Triggers) {
        T1=Player,0,0,0,0,0
        T2=Player,0,0,1,0,0
        T3=Player,0,0,1,0,0
    }
    # T1 enables T2, T2 enables T3
    set ::Data::actions(T1) "1,53,0,T2"
    set ::Data::actions(T2) "1,53,0,T3"
    set ::Data::rawmapdata(Tags) {
        Tag1=0,Grp0,T3
    }
    ::Validators::validate_triggers_integrity
    expr {$::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 8: Chain broken - T3 unreachable
# --------------------------------------------------------------------------
test ti-chain-broken "broken chain produces error" -body {
    reset_state
    set ::Data::triggers(T1) "T1"
    set ::Data::triggers(T2) "T2"
    set ::Data::triggers(T3) "T3"
    set ::Data::rawmapdata(Triggers) {
        T1=Player,0,0,0,0,0
        T2=Player,0,0,1,0,0
        T3=Player,0,0,1,0,0
    }
    # T1 enables T2, but T2 does NOT enable T3
    set ::Data::actions(T1) "1,53,0,T2"
    # T3 is disabled and never enabled
    set ::Data::rawmapdata(Tags) {
        Tag1=0,Grp0,T3
    }
    ::Validators::validate_triggers_integrity
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
