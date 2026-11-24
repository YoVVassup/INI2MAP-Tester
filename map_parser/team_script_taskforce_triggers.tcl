#----------------------------------------------------------------------------------------------------------
# map_parser/team_script_taskforce_triggers.tcl - Processing TeamTypes, ScriptTypes, TaskForces, Triggers, Events, Actions, Tags
# Contains:
#   - process_teamtypes, process_scripttypes, process_taskforces
#   - process_triggers, process_events, process_actions, process_tags
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

namespace eval ::MapParser {
    # Guard against double loading
    if {[info exists ::MapParser::team_script_loaded]} { return }
    variable team_script_loaded 1
}

# --- process_teamtypes ---
# Register TeamTypes defined in the map's [TeamTypes] section.
proc ::MapParser::process_teamtypes {} {
    if {![info exists ::Data::rawmapdata(TeamTypes)]} return
    foreach curline $::Data::rawmapdata(TeamTypes) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set tag [lindex $kv 1]
        if {![info exists ::Data::teamtypes($tag)]} {set ::Data::teamtypes($tag) ""}
    }
    unset ::Data::rawmapdata(TeamTypes)
}

# --- process_scripttypes ---
# Register ScriptTypes defined in the map's [ScriptTypes] section.
proc ::MapParser::process_scripttypes {} {
    if {![info exists ::Data::rawmapdata(ScriptTypes)]} return
    foreach curline $::Data::rawmapdata(ScriptTypes) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set tag [lindex $kv 1]
        if {![info exists ::Data::scripts($tag)]} {set ::Data::scripts($tag) ""}
    }
    unset ::Data::rawmapdata(ScriptTypes)
}

# --- process_taskforces ---
# Register TaskForce definitions from the map's [TaskForces] section.
proc ::MapParser::process_taskforces {} {
    if {![info exists ::Data::rawmapdata(TaskForces)]} return
    foreach curline $::Data::rawmapdata(TaskForces) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set tag [lindex $kv 1]
        if {![info exists ::Data::taskforces($tag)]} {set ::Data::taskforces($tag) ""}
    }
    unset ::Data::rawmapdata(TaskForces)
}

# --- process_triggers ---
# Parse trigger definitions and resolve attached-trigger links from the [Triggers] section.
proc ::MapParser::process_triggers {} {
    if {![info exists ::Data::rawmapdata(Triggers)]} return
    foreach curline $::Data::rawmapdata(Triggers) {
        set cc [string first "=" $curline]
        set pfx [string trim [string range $curline 0 [expr {$cc - 1}]]]
        if {![info exists ::Data::triggers($pfx)]} {
            set valpart [string trim [string range $curline [expr {$cc + 1}] end]]
            set tag [split [string range $curline [expr {$cc + 1}] end] ","]
            set att [lindex $tag 1]
            set trig [lindex $tag 2]
            if {$trig eq ""} {
                ::Logging::error "Trigger \"$pfx\" has missing name"
                set trig $pfx
            }
            # B8: fewer than 8 fields = malformed trigger (WAE ParseTrigger).
            # Warn and keep parsing instead of skipping the trigger entirely.
            if {$valpart ne "" && [llength $tag] < 8} {
                ::Logging::warning "Trigger \"$pfx\" has missing values (got [llength $tag], expected 8+)"
            }
            # B7: the owner (field 0) must be a known house type / country
            set owner [lindex $tag 0]
            if {$owner ne "" && ![info exists ::Data::countries($owner)]} {
                ::Logging::warning "Trigger \"$trig\" has a nonexistent HouseType as its owner: $owner"
            }
            set ::Data::triggers($pfx) $trig
            if {$att eq "<none>"} {
                # nothing
            } elseif {$att eq ""} {
                ::Logging::error "Trigger \"$trig\" has blank attached Trigger, should be: <none>"
            } else {
                set ::Data::attached($att) $pfx
            }
        }
    }
    if {[info exists ::Data::attached]} {
        foreach {att trig} [array get ::Data::attached] {
            if {![info exists ::Data::triggers($att)]} {
                if {[info exists ::Data::triggers($trig)]} {
                    ::Logging::error "Trigger \"$::Data::triggers($trig)\" has invalid attached Trigger: $att"
                } else {
                    ::Logging::error "Trigger has invalid attached Trigger: $att"
                }
            }
        }
        array unset ::Data::attached
    }
    # NOTE: rawmapdata(Triggers) is intentionally kept: validators/trigger_integrity.tcl
    # reads the initial-disabled flag (field 4) from these raw lines.
}

# --- process_events ---
# Parse event entries for each trigger, validating event codes and parameter counts.
proc ::MapParser::process_events {} {
    if {![info exists ::Data::rawmapdata(Events)]} return
    foreach curline $::Data::rawmapdata(Events) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set pfx [string trim [lindex $kv 0]]
        # Parse and store even when the trigger is undeclared:
        # validators/report_unused_extended.tcl reports such entries as
        # "undeclared Trigger" (skipping here made that check dead).
        if {![info exists ::Data::triggers($pfx)]} {
            ::Logging::error "Event \"$pfx\" has no associated Trigger"
        }
        set values [split [lindex $kv 1] ","]
        set evnum [lindex $values 0]
        if {![string is integer $evnum]} {
            ::Logging::error "Event \"$pfx\" has non-integer event count: $evnum"
            continue
        }
        set params [lrange $values 1 end]
        set current_index 0
        set event_list {}
        set processed_params 0
        for {set i 0} {$i < $evnum} {incr i} {
            set code [lindex $params $current_index]
            if {$code eq ""} {
                ::Logging::error "Event \"$pfx\": unexpected end of data while reading code for event $i"
                break
            }
            if {![string is integer -strict $code]} {
                ::Logging::error "Event \"$pfx\": non-numeric event code: $code"
                break
            }
            incr current_index
            incr processed_params
            if {$code < 60} {
                set param_count 2
            } elseif {$code == 60 || $code == 61} {
                set param_count 3
            } elseif {$code == 77 || $code == 78 || $code == 80 || $code == 81 || $code == 82 || $code == 86} {
                set param_count 3
            } elseif {[::MapParser::is_phobos_event_code $code]} {
                # Phobos events read P1=2 plus two real parameters (P2, P3);
                # the remaining codes - including the 603 gap - keep two and
                # fall through to the "unknown code" warning below.
                set param_count 3
            } else {
                set param_count 2
                if {$code > 88} {
                    ::Logging::warning "Event \"$pfx\": unknown event code $code, assuming 2 parameters"
                }
            }
            set event_params {}
            for {set j 0} {$j < $param_count} {incr j} {
                set pval [lindex $params $current_index]
                if {$pval eq ""} {
                    ::Logging::error "Event \"$pfx\": missing parameter $j for event code $code"
                    set pval "0"
                }
                lappend event_params $pval
                incr current_index
                incr processed_params
            }
            lappend event_list [concat [list $code] $event_params]
        }
        set total_params [llength $params]
        if {$processed_params != $total_params} {
            ::Logging::error "Event \"$pfx\": declares $evnum events, but has $total_params parameters (expected [expr $processed_params]). Mismatch may cause incorrect parsing."
        }
        set ::Data::events($pfx) $event_list
    }
    unset ::Data::rawmapdata(Events)
}

# --- process_actions ---
# Parse action entries for each trigger, validating action count and parameter structure.
proc ::MapParser::process_actions {} {
    if {![info exists ::Data::rawmapdata(Actions)]} return
    foreach curline $::Data::rawmapdata(Actions) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set pfx [string trim [lindex $kv 0]]
        # Store even when the trigger is undeclared - see process_events above.
        if {![info exists ::Data::triggers($pfx)]} {
            ::Logging::error "Action \"$pfx\" has no associated Trigger"
        }
        set value [lindex $kv 1]
        set ::Data::actions($pfx) $value

        # Check number of actions
        set fields [split $value ","]
        set num [lindex $fields 0]
        if {![string is integer -strict $num]} {
            ::Logging::error "Action \"$pfx\" has non-integer action count: $num"
            continue
        }
        set expected_len [expr {1 + $num * 8}]
        set real_len [llength $fields]
        if {$real_len != $expected_len} {
            ::Logging::error "Action \"$pfx\" declares $num actions, but has $real_len parameters (expected $expected_len). Last action(s) may be ignored."
        }
        # B9: more than 18 actions - the game's parsing buffer is limited
        # (WAE maxActionCount / WarnOfTooManyTriggerActions)
        if {$num > 18} {
            set tname $pfx
            if {[info exists ::Data::triggers($pfx)]} { set tname $::Data::triggers($pfx) }
            ::Logging::notice "Trigger '$tname' has more than 18 actions! This can cause the game to crash! Consider splitting it up to multiple triggers."
        }
    }
    unset ::Data::rawmapdata(Actions)
}

# --- process_tags ---
# Parse Tag definitions from the [Tags] section and link tags to their triggers.
proc ::MapParser::process_tags {} {
    if {![info exists ::Data::rawmapdata(Tags)]} return
    foreach curline $::Data::rawmapdata(Tags) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        foreach {pfx val} $kv { break }
        # Remove surrounding quotes if present
        set val [string trim $val "\""]
        set fields [split $val ","]
        if {[llength $fields] < 3} {
            ::Logging::error "Tag \"$pfx\" has invalid format: $val"
            continue
        }
        set rep [string trim [lindex $fields 0]]
        set name [string trim [lindex $fields 1]]
        set trig [string trim [lindex $fields 2]]
        if {![info exists ::Data::triggers($trig)]} {
            ::Logging::error "Tag \"$pfx\" has invalid attached Trigger: $trig"
        }
        if {![string is integer -strict $rep] || $rep < 0 || $rep > 2} {
            ::Logging::error "Tag \"$pfx\" has invalid repeating range: $rep"
        }
        set ::Data::tags($pfx) $name
    }
    # NOTE: rawmapdata(Tags) is intentionally kept: validators/trigger_integrity.tcl
    # builds the tag -> trigger map from these raw lines.
}