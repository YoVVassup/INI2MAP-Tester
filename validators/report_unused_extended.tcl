#----------------------------------------------------------------------------------------------------------
# validators/report_unused_extended.tcl - Extended unused resource reporting for INI2MAP Tester
# Contains:
#   - report_unused_extended procedure
#   - Reports undeclared resources (used but not declared in type lists)
#   - Complements report_unused.tcl which covers teamtypes, taskforces, scripts, waypoints, variables
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[namespace exists ::Validators] && [info exists ::Validators::report_unused_extended_loaded]} { return }
if {![namespace exists ::Validators]} {
    namespace eval ::Validators {}
}
set ::Validators::report_unused_extended_loaded 1

# --------------------------------------------------------------------------
# Extended unused resource reporting
# --------------------------------------------------------------------------
# --- report_unused_extended ---
# Reports undeclared resources that are used on the map but not declared in type lists.
proc ::Validators::report_unused_extended {} {
    # 1. Undeclared Triggers (referenced in events/actions but not in [Triggers])
    set undeclared_triggers [dict create]
    if {[info exists ::Data::events]} {
        foreach trig_id [array names ::Data::events] {
            if {![info exists ::Data::triggers($trig_id)]} {
                dict set undeclared_triggers $trig_id 1
            }
        }
    }
    if {[info exists ::Data::actions]} {
        foreach trig_id [array names ::Data::actions] {
            if {![info exists ::Data::triggers($trig_id)]} {
                dict set undeclared_triggers $trig_id 1
            }
        }
    }
    foreach trig_id [lsort [dict keys $undeclared_triggers]] {
        ::Logging::notice "undeclared Trigger: $trig_id (referenced in events/actions but not declared in \[Triggers\])"
    }

    # 2. Undeclared TeamTypes (referenced by AI triggers but not in [TeamTypes])
    set undeclared_teams [dict create]
    if {[info exists ::Data::local_aitriggers]} {
        foreach aitrig [array names ::Data::local_aitriggers] {
            if {![info exists ::Data::rawmapdata(AITriggerTypes)]} continue
            foreach curline $::Data::rawmapdata(AITriggerTypes) {
                set kv [::util::_parse_keyval $curline]
                if {$kv eq ""} continue
                set id [string trim [lindex $kv 0]]
                if {$id ne $aitrig} continue
                set values [split [lindex $kv 1] ","]
                set tt1 [lindex $values 1]
                set tt2 [lindex $values 14]
                if {$tt1 ne "" && ![info exists ::Data::teamtypes($tt1)]} {
                    dict set undeclared_teams $tt1 1
                }
                if {$tt2 ne "<none>" && $tt2 ne "" && ![info exists ::Data::teamtypes($tt2)]} {
                    dict set undeclared_teams $tt2 1
                }
                break
            }
        }
    }
    foreach team_id [lsort [dict keys $undeclared_teams]] {
        ::Logging::notice "undeclared TeamType: $team_id (referenced by AI trigger but not declared in \[TeamTypes\])"
    }

    # 3. Undeclared TaskForces (referenced by team types but not in [TaskForces])
    set undeclared_tfs [dict create]
    if {[info exists ::Data::teamtypes]} {
        foreach team [array names ::Data::teamtypes] {
            if {![info exists ::Data::rawmapdata($team)]} continue
            foreach curline $::Data::rawmapdata($team) {
                set kv [::util::_parse_keyval $curline]
                if {$kv eq ""} continue
                set pfx [string trim [lindex $kv 0]]
                if {$pfx eq "TaskForce"} {
                    set tf [string trim [lindex $kv 1]]
                    if {$tf ne "" && ![info exists ::Data::taskforces($tf)]} {
                        dict set undeclared_tfs $tf 1
                    }
                }
            }
        }
    }
    foreach tf [lsort [dict keys $undeclared_tfs]] {
        ::Logging::notice "undeclared TaskForce: $tf (referenced by TeamType but not declared in \[TaskForces\])"
    }

    # 4. Undeclared Scripts (referenced by team types but not in [ScriptTypes])
    set undeclared_scripts [dict create]
    if {[info exists ::Data::teamtypes]} {
        foreach team [array names ::Data::teamtypes] {
            if {![info exists ::Data::rawmapdata($team)]} continue
            foreach curline $::Data::rawmapdata($team) {
                set kv [::util::_parse_keyval $curline]
                if {$kv eq ""} continue
                set pfx [string trim [lindex $kv 0]]
                if {$pfx eq "Script"} {
                    set script [string trim [lindex $kv 1]]
                    if {$script ne "" && ![info exists ::Data::scripts($script)]} {
                        dict set undeclared_scripts $script 1
                    }
                }
            }
        }
    }
    foreach script [lsort [dict keys $undeclared_scripts]] {
        ::Logging::notice "undeclared Script: $script (referenced by TeamType but not declared in \[ScriptTypes\])"
    }

    # 5. Summary
    set total_undeclared [expr {[dict size $undeclared_triggers] + [dict size $undeclared_teams] + [dict size $undeclared_tfs] + [dict size $undeclared_scripts]}]
    if {$total_undeclared > 0} {
        ::Logging::notice "=== Undeclared Resources Summary ==="
        ::Logging::notice "  Undeclared Triggers: [dict size $undeclared_triggers]"
        ::Logging::notice "  Undeclared TeamTypes: [dict size $undeclared_teams]"
        ::Logging::notice "  Undeclared TaskForces: [dict size $undeclared_tfs]"
        ::Logging::notice "  Undeclared Scripts: [dict size $undeclared_scripts]"
    }
}
