#----------------------------------------------------------------------------------------------------------
# test_trigger_integrity_wae.tcl - Unit tests for the WAE MapIssueChecker reimplementation
# Tests: validate_triggers_integrity additions - B1 (0 events/actions),
#        B2 (disabled never enabled), B3 (enabled never disabled),
#        B4 (self-enable), B5 (linked-trigger cycle), B11 (difficulty
#        mismatch) and C2 (event attachment: 1 / 31 / object-specific)
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
    array unset ::Data::teamtypes
    array unset ::Data::globalvars
    array unset ::Data::tagobjects
    array unset ::Data::tagcelltags
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
}

# Append a trigger definition (8 fields: HOUSE,LINKED,NAME,DISABLED,EASY,NORMAL,HARD,REPEATING)
proc mktrig {id name {disabled 0} {easy 1} {normal 1} {hard 1} {linked "<none>"}} {
    set ::Data::triggers($id) $name
    lappend ::Data::rawmapdata(Triggers) "$id=Player,$linked,$name,$disabled,$easy,$normal,$hard,0"
}

proc mk_events {id code {p1 0} {p2 0}} {
    set ::Data::events($id) [list [list $code $p1 $p2]]
}

# --------------------------------------------------------------------------
# B1: triggers with 0 events / 0 actions
# --------------------------------------------------------------------------
test tiw-b1-no-events "trigger without events notices once" -body {
    reset_state
    mktrig T1 "Trigger One"
    set ::Data::actions(T1) "1,6,0,0"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test tiw-b1-no-actions "trigger without actions notices once" -body {
    reset_state
    mktrig T1 "Trigger One"
    mk_events T1 6
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B2: disabled triggers never enabled by another trigger
# --------------------------------------------------------------------------
test tiw-b2-disabled "disabled + never enabled notices" -body {
    reset_state
    mktrig T1 "Trigger One" 1
    mk_events T1 6
    set ::Data::actions(T1) "1,6,0,0"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test tiw-b2-debug "DEBUG in the name suppresses the notice" -body {
    reset_state
    mktrig T1 "DEBUG Trigger" 1
    mk_events T1 6
    set ::Data::actions(T1) "1,6,0,0"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0}
} -result 1

test tiw-b2-obsolete "OBSOLETE in the name suppresses the notice" -body {
    reset_state
    mktrig T1 "Old OBSOLETE Trigger" 1
    mk_events T1 6
    set ::Data::actions(T1) "1,6,0,0"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0}
} -result 1

test tiw-b2-reveal "RevealAll action suppresses the notice" -body {
    reset_state
    mktrig T1 "Trigger One" 1
    mk_events T1 6
    set ::Data::actions(T1) "1,16,0,0"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0}
} -result 1

test tiw-b2-enabled "disabled trigger enabled by another is silent" -body {
    reset_state
    mktrig T1 "Trigger One"
    mktrig T2 "Trigger Two" 1
    mk_events T1 6
    mk_events T2 6
    set ::Data::actions(T1) "1,53,0,T2"
    set ::Data::actions(T2) "1,6,0,0"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B3: triggers enabled by another trigger but never disabled
# --------------------------------------------------------------------------
test tiw-b3-enabled-never-disabled "enabled by other + never disabled notices" -body {
    reset_state
    mktrig T1 "Trigger One"
    mktrig T2 "Trigger Two"
    mk_events T1 6
    mk_events T2 6
    set ::Data::actions(T1) "1,53,0,T2"
    set ::Data::actions(T2) "1,6,0,0"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test tiw-b3-disabled-by-action "disable action (54) suppresses the notice" -body {
    reset_state
    mktrig T1 "Trigger One"
    mktrig T2 "Trigger Two"
    mk_events T1 6
    mk_events T2 6
    set ::Data::actions(T1) "1,53,0,T2"
    set ::Data::actions(T2) "1,54,0,T2"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B4: triggers enabling themselves
# --------------------------------------------------------------------------
test tiw-b4-self-enable "self-enable notices once" -body {
    reset_state
    mktrig T1 "Trigger One"
    mk_events T1 6
    set ::Data::actions(T1) "1,53,0,T1"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B5: triggers attached to themselves through the linked-trigger chain
# --------------------------------------------------------------------------
test tiw-b5-cycle "two-trigger link cycle notices twice" -body {
    reset_state
    mktrig T1 "Trigger One" 0 1 1 1 "T2"
    mktrig T2 "Trigger Two" 0 1 1 1 "T1"
    mk_events T1 6
    mk_events T2 6
    set ::Data::actions(T1) "1,6,0,0"
    set ::Data::actions(T2) "1,6,0,0"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 2 && $::Logging::error_count == 0}
} -result 1

test tiw-b5-no-cycle "valid linked chain is silent" -body {
    reset_state
    mktrig T1 "Trigger One" 0 1 1 1 "T2"
    mktrig T2 "Trigger Two" 0 1 1 1 "<none>"
    mk_events T1 6
    mk_events T2 6
    set ::Data::actions(T1) "1,6,0,0"
    set ::Data::actions(T2) "1,6,0,0"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B11: difficulty mismatches on enable/disable
# --------------------------------------------------------------------------
test tiw-b11-enable-mismatch "hard trigger enabling medium trigger notices" -body {
    reset_state
    mktrig T1 "Trigger One" 0 0 0 1
    mktrig T2 "Trigger Two" 0 0 1 0
    mk_events T1 6
    mk_events T2 6
    set ::Data::actions(T1) "1,53,0,T2"
    set ::Data::actions(T2) "1,54,0,T2"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test tiw-b11-same "matching difficulties are silent" -body {
    reset_state
    mktrig T1 "Trigger One" 0 0 0 1
    mktrig T2 "Trigger Two" 0 0 0 1
    mk_events T1 6
    mk_events T2 6
    set ::Data::actions(T1) "1,53,0,T2"
    set ::Data::actions(T2) "1,54,0,T2"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0}
} -result 1

test tiw-b11-global "difficulty via event-27 globals detects mismatch" -body {
    reset_state
    # WAE only uses the event-27 fallback when all three difficulty globals exist
    set ::Data::globalvars(0) "Difficulty Hard"
    set ::Data::globalvars(1) "Difficulty Medium"
    set ::Data::globalvars(2) "Difficulty Easy"
    mktrig T1 "Trigger One"
    mktrig T2 "Trigger Two"
    mk_events T1 27 0 0
    mk_events T2 27 0 1
    set ::Data::actions(T1) "1,53,0,T2"
    set ::Data::actions(T2) "1,54,0,T2"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# C2: event attachment checks
# --------------------------------------------------------------------------
test tiw-c2-entered-unattached "event 1 without any attachment notices" -body {
    reset_state
    mktrig T1 "Trigger One"
    mk_events T1 1
    set ::Data::actions(T1) "1,6,0,0"
    lappend ::Data::rawmapdata(Tags) "Tag1=0,Grp0,T1"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test tiw-c2-entered-object "event 1 attached to an object is silent" -body {
    reset_state
    mktrig T1 "Trigger One"
    mk_events T1 1
    set ::Data::actions(T1) "1,6,0,0"
    lappend ::Data::rawmapdata(Tags) "Tag1=0,Grp0,T1"
    set ::Data::tagobjects(Tag1) ""
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0}
} -result 1

test tiw-c2-entered-celltag "event 1 attached to a celltag is silent" -body {
    reset_state
    mktrig T1 "Trigger One"
    mk_events T1 1
    set ::Data::actions(T1) "1,6,0,0"
    lappend ::Data::rawmapdata(Tags) "Tag1=0,Grp0,T1"
    set ::Data::tagcelltags(Tag1) ""
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0}
} -result 1

test tiw-c2-bridge-no-celltag "event 31 without celltag notices" -body {
    reset_state
    mktrig T1 "Trigger One"
    mk_events T1 31
    set ::Data::actions(T1) "1,6,0,0"
    lappend ::Data::rawmapdata(Tags) "Tag1=0,Grp0,T1"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test tiw-c2-bridge-celltag "event 31 with celltag is silent" -body {
    reset_state
    mktrig T1 "Trigger One"
    mk_events T1 31
    set ::Data::actions(T1) "1,6,0,0"
    lappend ::Data::rawmapdata(Tags) "Tag1=0,Grp0,T1"
    set ::Data::tagcelltags(Tag1) ""
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0}
} -result 1

test tiw-c2-object-team "object event attached through TeamType is silent" -body {
    reset_state
    mktrig T1 "Trigger One"
    mk_events T1 6
    set ::Data::actions(T1) "1,6,0,0"
    lappend ::Data::rawmapdata(Tags) "Tag1=0,Grp0,T1"
    set ::Data::teamtypes(TT1) ""
    lappend ::Data::rawmapdata(TT1) "Name=Team One"
    lappend ::Data::rawmapdata(TT1) "Tag=Tag1"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0}
} -result 1

test tiw-c2-object-unattached "object event without attachment notices once" -body {
    reset_state
    mktrig T1 "Trigger One"
    mk_events T1 6
    set ::Data::actions(T1) "1,6,0,0"
    lappend ::Data::rawmapdata(Tags) "Tag1=0,Grp0,T1"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test tiw-c2-object-linked "object event linked from another trigger is silent" -body {
    reset_state
    mktrig T1 "Trigger One"
    mktrig T2 "Trigger Two" 0 1 1 1 "T1"
    mk_events T1 6
    mk_events T2 6
    set ::Data::actions(T1) "1,6,0,0"
    set ::Data::actions(T2) "1,6,0,0"
    lappend ::Data::rawmapdata(Tags) "Tag1=0,Grp0,T1"
    ::Validators::validate_triggers_integrity
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
