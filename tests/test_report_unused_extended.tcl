#----------------------------------------------------------------------------------------------------------
# test_report_unused_extended.tcl - Unit tests for validators/report_unused_extended.tcl
# Tests: report_unused_extended (undeclared triggers, teams, taskforces, scripts)
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir utils.tcl]
source [file join $script_dir map_parser.tcl]
source [file join $script_dir validators.tcl]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::triggers
    array unset ::Data::events
    array unset ::Data::actions
    array unset ::Data::teamtypes
    array unset ::Data::taskforces
    array unset ::Data::scripts
    array unset ::Data::local_aitriggers
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
}

proc has_notice {pattern} {
    foreach msg $::Data::maperr {
        if {[string match $pattern $msg]} { return 1 }
    }
    return 0
}

# --------------------------------------------------------------------------
# Test 1: No undeclared resources - no output
# --------------------------------------------------------------------------
test rue-none "no undeclared resources produces no output" -body {
    reset_state
    ::Validators::report_unused_extended
    expr {$::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Undeclared trigger reported
# --------------------------------------------------------------------------
test rue-undeclared-trigger "undeclared trigger is reported" -body {
    reset_state
    # Trigger referenced in events but not declared
    set ::Data::events(T99) "1,0"
    ::Validators::report_unused_extended
    has_notice "NOTICE -> undeclared Trigger: T99*"
} -result 1

# --------------------------------------------------------------------------
# Test 3: Declared trigger not reported
# --------------------------------------------------------------------------
test rue-declared-trigger "declared trigger is not reported" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::events(T1) "1,0"
    ::Validators::report_unused_extended
    expr {![has_notice "NOTICE -> undeclared Trigger: T1*"]}
} -result 1

# --------------------------------------------------------------------------
# Test 4: Undeclared trigger via actions
# --------------------------------------------------------------------------
test rue-undeclared-trigger-action "undeclared trigger via actions is reported" -body {
    reset_state
    set ::Data::actions(T99) "1,0,0,0"
    ::Validators::report_unused_extended
    has_notice "NOTICE -> undeclared Trigger: T99*"
} -result 1

# --------------------------------------------------------------------------
# Test 5: Undeclared taskforce reported
# --------------------------------------------------------------------------
test rue-undeclared-taskforce "undeclared taskforce is reported" -body {
    reset_state
    set ::Data::teamtypes(TT1) "Team One"
    set ::Data::rawmapdata(TT1) {TaskForce=TF99}
    set ::Data::taskforces(dummy) "x"
    ::Validators::report_unused_extended
    has_notice "NOTICE -> undeclared TaskForce: TF99*"
} -result 1

# --------------------------------------------------------------------------
# Test 6: Undeclared script reported
# --------------------------------------------------------------------------
test rue-undeclared-script "undeclared script is reported" -body {
    reset_state
    set ::Data::teamtypes(TT1) "Team One"
    set ::Data::rawmapdata(TT1) {Script=S99}
    set ::Data::scripts(dummy) "x"
    ::Validators::report_unused_extended
    has_notice "NOTICE -> undeclared Script: S99*"
} -result 1

# --------------------------------------------------------------------------
# Test 7: Summary shown when undeclared exist
# --------------------------------------------------------------------------
test rue-summary "summary is shown when undeclared exist" -body {
    reset_state
    set ::Data::events(T99) "1,0"
    ::Validators::report_unused_extended
    has_notice "NOTICE -> === Undeclared Resources Summary ===*"
} -result 1

# --------------------------------------------------------------------------
# Test 8: Undeclared teamtype from AI trigger
# --------------------------------------------------------------------------
test rue-undeclared-team "undeclared teamtype from AI trigger is reported" -body {
    reset_state
    set ::Data::local_aitriggers(AIT1) "AI Trigger 1"
    set ::Data::rawmapdata(AITriggerTypes) {AIT1=name,TT99,0,0,0,0,0,0,0,0,0,0,0,0,<none>}
    set ::Data::teamtypes(dummy) "x"
    ::Validators::report_unused_extended
    has_notice "NOTICE -> undeclared TeamType: TT99*"
} -result 1

# --------------------------------------------------------------------------
# Test 9: Multiple undeclared triggers deduplicated
# --------------------------------------------------------------------------
test rue-dedup "duplicate undeclared triggers are deduplicated" -body {
    reset_state
    # Same trigger referenced in both events and actions
    set ::Data::events(T99) "1,0"
    set ::Data::actions(T99) "1,0,0,0"
    ::Validators::report_unused_extended
    # Should only appear once
    set count 0
    foreach msg $::Data::maperr {
        if {[string match "NOTICE -> undeclared Trigger: T99*" $msg]} { incr count }
    }
    expr {$count == 1}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
