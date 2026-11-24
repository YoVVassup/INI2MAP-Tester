#----------------------------------------------------------------------------------------------------------
# validators_trigger_integrity.tcl - Trigger integrity validation for INI2MAP Tester
# Contains:
#   - validate_triggers_integrity procedure
#   - BFS-based reachability analysis for triggers (action 53 enables)
#   - Checks that tags reference only reachable triggers
#   - WAE MapIssueChecker reimplementation: 0 events/actions, disabled-never-enabled,
#     enabled-never-disabled, self-enable, linked-trigger cycles, difficulty
#     mismatches and event-attachment checks (events 1/31/object-specific)
#   - Uses helper procedures and logging from validators_core.tcl
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Resolve a trigger's difficulty level (WAE MapIssueChecker.GetTriggerDifficulty)
#   trig   - trigger ID
#   fields - raw [Triggers] value fields of that trigger
# Returns "Hard"/"Medium"/"Easy" or "" when the difficulty is not determinable.
# --------------------------------------------------------------------------
proc ::Validators::_trigger_difficulty {trig fields} {
    set easy 1
    set normal 1
    set hard 1
    # [Triggers] fields: 0=HOUSE 1=LINKED 2=NAME 3=DISABLED 4=EASY 5=NORMAL 6=HARD
    # Missing fields default to enabled (WAE ParseTrigger semantics)
    foreach {slot idx} {easy 4 normal 5 hard 6} {
        set v [string trim [lindex $fields $idx]]
        if {$v eq ""} continue
        set lv [string tolower $v]
        if {$lv eq "0" || $lv eq "no" || $lv eq "false" || $lv eq "off"} {
            set $slot 0
        }
    }

    if {$hard && !$normal && !$easy} { return "Hard" }
    if {$normal && !$hard && !$easy} { return "Medium" }
    if {$easy && !$hard && !$normal} { return "Easy" }

    # Older TS-engine / multiplayer missions define the difficulty with globals
    # set through event 27 (GlobalSet) instead of the EASY/NORMAL/HARD fields.
    set hi -1
    set mi -1
    set ei -1
    foreach {gidx gname} [array get ::Data::globalvars] {
        if {![string is integer -strict $gidx]} continue
        if {$gname eq "Difficulty Hard"} {
            set hi $gidx
        } elseif {$gname eq "Difficulty Medium"} {
            set mi $gidx
        } elseif {$gname eq "Difficulty Easy"} {
            set ei $gidx
        }
    }
    if {$hi > -1 && $mi > -1 && $ei > -1 && [info exists ::Data::events($trig)]} {
        foreach ev $::Data::events($trig) {
            if {![string equal [lindex $ev 0] "27"]} continue
            set p2 [lindex $ev 2]
            if {![string is integer -strict $p2]} continue
            if {$p2 == $hi} { return "Hard" }
            if {$p2 == $mi} { return "Medium" }
            if {$p2 == $ei} { return "Easy" }
        }
    }
    return ""
}

# --------------------------------------------------------------------------
# Trigger integrity validation (iterative BFS)
# --------------------------------------------------------------------------
# --- validate_triggers_integrity ---
# Validates trigger integrity using BFS to find unreachable triggers.
proc ::Validators::validate_triggers_integrity {} {
    array set tag_to_trigger {}
    if {[info exists ::Data::rawmapdata(Tags)]} {
        foreach line $::Data::rawmapdata(Tags) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set tid [string trim [string range $line 0 [expr {$eq-1}]]]
            set rest [split [string range $line [expr {$eq+1}] end] ","]
            set trig [lindex $rest 2]
            if {[info exists ::Data::triggers($trig)]} {
                set tag_to_trigger($tid) $trig
            }
        }
    }

    # Inverted tag -> trigger map grouped by trigger (for event-attachment checks)
    array set trig_tags {}
    foreach {tid tt} [array get tag_to_trigger] {
        lappend trig_tags($tt) $tid
    }

    array set initial_disabled {}
    array set trig_fields {}
    array set trig_linked {}
    if {[info exists ::Data::rawmapdata(Triggers)]} {
        foreach line $::Data::rawmapdata(Triggers) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set trig_id [string trim [string range $line 0 [expr {$eq-1}]]]
            set fields [split [string range $line [expr {$eq+1}] end] ","]
            set trig_fields($trig_id) $fields
            if {[lindex $fields 3] == 1} {
                set initial_disabled($trig_id) 1
            }
            set lk [string trim [lindex $fields 1]]
            if {$lk ne "" && ![string equal -nocase $lk "<none>"] && ![string equal -nocase $lk "none"]} {
                set trig_linked($trig_id) $lk
            }
        }
    }

    array set enables {}
    array set enabled_by {}
    array set disabled_by {}
    array set has_reveal {}
    set pair_list {}
    foreach {trig_id act_str} [array get ::Data::actions] {
        set fields [split $act_str ","]
        set count [lindex $fields 0]
        if {![string is integer -strict $count]} continue
        # Only declared triggers may act as sources for the new checks
        set src_declared [info exists ::Data::triggers($trig_id)]
        set idx 1
        for {set i 0} {$i < $count} {incr i} {
            set act1 [lindex $fields $idx]
            set target [lindex $fields [expr {$idx+2}]]
            incr idx 8
            if {$act1 == 53} {
                if {[info exists ::Data::triggers($target)]} {
                    lappend enables($trig_id) $target
                    if {$src_declared} {
                        lappend enabled_by($target) $trig_id
                        lappend pair_list [list $trig_id $target enable]
                    }
                }
            } elseif {$act1 == 54} {
                if {$src_declared && [info exists ::Data::triggers($target)]} {
                    lappend disabled_by($target) $trig_id
                    lappend pair_list [list $trig_id $target disable]
                }
            } elseif {$act1 == 16} {
                if {$src_declared} { set has_reveal($trig_id) 1 }
            }
        }
    }

    array set reachable_set {}
    set queue {}
    foreach trig [array names ::Data::triggers] {
        if {![info exists initial_disabled($trig)]} {
            lappend queue $trig
        }
    }

    # BFS with index pointer instead of lrange (O(n) instead of O(n²))
    set qhead 0
    while {$qhead < [llength $queue]} {
        set cur [lindex $queue $qhead]
        incr qhead
        if {[info exists reachable_set($cur)]} continue
        set reachable_set($cur) 1
        if {[info exists enables($cur)]} {
            foreach target $enables($cur) {
                if {![info exists reachable_set($target)]} {
                    lappend queue $target
                }
            }
        }
    }

    foreach {tag trig} [array get tag_to_trigger] {
        if {![info exists reachable_set($trig)]} {
            ::Logging::error "Tag \"$tag\" refers to unreachable trigger $trig ($::Data::triggers($trig)). The trigger is never enabled."
        }
    }

    # --- B1: triggers with 0 events or 0 actions (WAE MapIssueChecker) ---
    foreach trig [array names ::Data::triggers] {
        set tname $::Data::triggers($trig)
        set evcount 0
        if {[info exists ::Data::events($trig)]} {
            set evcount [llength $::Data::events($trig)]
        }
        if {$evcount == 0} {
            ::Logging::notice "Trigger '$tname' has no events, so it can never fire. Add at least one event to it."
        }
        set acount 0
        if {[info exists ::Data::actions($trig)]} {
            set afields [split $::Data::actions($trig) ","]
            if {[string is integer -strict [lindex $afields 0]]} {
                set acount [lindex $afields 0]
            }
        }
        if {$acount == 0} {
            ::Logging::notice "Trigger '$tname' has no actions, so firing it would do nothing. Add at least one action to it."
        }
    }

    # --- B2: disabled triggers that are never enabled by another trigger ---
    foreach trig [array names ::Data::triggers] {
        if {![info exists initial_disabled($trig)]} continue
        # "Reveal all map" actions are usually debug-only - skip
        if {[info exists has_reveal($trig)]} continue
        set tname $::Data::triggers($trig)
        set uname [string toupper $tname]
        if {[string first "DEBUG" $uname] >= 0} continue
        if {[string first "OBSOLETE" $uname] >= 0} continue
        set enby 0
        if {[info exists enabled_by($trig)]} {
            foreach src $enabled_by($trig) {
                if {$src ne $trig} {
                    set enby 1
                    break
                }
            }
        }
        if {$enby} continue
        ::Logging::notice "Trigger \"$tname\" ($trig) starts disabled and no other trigger ever enables it, so it can never run. Enable it from somewhere, or put DEBUG or OBSOLETE in its name to silence this warning (for debug-only triggers)."
    }

    # --- B3: triggers enabled by another trigger but never disabled ---
    foreach trig [array names ::Data::triggers] {
        if {[info exists initial_disabled($trig)]} continue
        set enby 0
        if {[info exists enabled_by($trig)]} {
            foreach src $enabled_by($trig) {
                if {$src ne $trig} {
                    set enby 1
                    break
                }
            }
        }
        if {!$enby} continue
        # Disabled by itself or any other trigger counts
        if {[info exists disabled_by($trig)]} continue
        set tname $::Data::triggers($trig)
        ::Logging::notice "Trigger \"$tname\" ($trig) is switched on by another trigger, yet it is never disabled - not by default and not by any other trigger - so switching it on has no effect. Disable it somewhere first."
    }

    # --- B4: triggers enabling themselves ---
    foreach trig [array names ::Data::triggers] {
        if {![info exists enabled_by($trig)]} continue
        if {[lsearch -exact $enabled_by($trig) $trig] < 0} continue
        set tname $::Data::triggers($trig)
        ::Logging::notice "Trigger \"$tname\" ($trig) has an action for enabling itself. Is it supposed to enable something else instead?"
    }

    # --- B5: triggers attached to themselves through the linked-trigger chain ---
    foreach trig [array names ::Data::triggers] {
        if {![info exists trig_linked($trig)]} continue
        set cur $trig_linked($trig)
        set visited [dict create]
        while {$cur ne ""} {
            if {$cur eq $trig} {
                set tname $::Data::triggers($trig)
                ::Logging::notice "Trigger \"$tname\" is attached to itself (potentially through other triggers). This will cause the game to crash!"
                break
            }
            if {[dict exists $visited $cur]} break
            dict set visited $cur 1
            if {[info exists trig_linked($cur)]} {
                set cur $trig_linked($cur)
            } else {
                break
            }
        }
    }

    # --- B11: difficulty mismatches between enable/disable actions ---
    foreach triplet $pair_list {
        lassign $triplet src tgt kind
        foreach t [list $src $tgt] {
            if {![info exists diff_cache($t)]} {
                set tf {}
                if {[info exists trig_fields($t)]} { set tf $trig_fields($t) }
                set diff_cache($t) [::Validators::_trigger_difficulty $t $tf]
            }
        }
        set ds $diff_cache($src)
        set dt $diff_cache($tgt)
        if {$ds eq "" || $dt eq "" || $ds eq $dt} continue
        set sname $::Data::triggers($src)
        set tname $::Data::triggers($tgt)
        if {$kind eq "enable"} {
            ::Logging::notice "The trigger \"$sname\" has \"$ds\" as its difficulty level, but it enables a trigger \"$tname\" which has \"$dt\" as its difficulty."
        } else {
            ::Logging::notice "The trigger \"$sname\" has \"$ds\" as its difficulty level, but it disables a trigger \"$tname\" which has \"$dt\" as its difficulty."
        }
    }
    catch {array unset diff_cache}

    # --- C2: event-attachment checks (WAE MapIssueChecker) ---
    # TeamType "Tag=" values of the map's teamtypes (read while sections live)
    array set teamtag {}
    foreach tteam [array names ::Data::teamtypes] {
        if {![info exists ::Data::rawmapdata($tteam)]} continue
        foreach tline $::Data::rawmapdata($tteam) {
            set teq [string first "=" $tline]
            if {$teq == -1} continue
            set tkey [string trim [string range $tline 0 [expr {$teq-1}]]]
            if {$tkey ne "Tag"} continue
            set tval [string trim [string range $tline [expr {$teq+1}] end]]
            if {$tval ne "" && ![string equal -nocase $tval "<none>"] && ![string equal -nocase $tval "none"]} {
                set teamtag($tval) 1
            }
            break
        }
    }

    # Triggers linked FROM another trigger (field 1 of [Triggers])
    array set linked_from {}
    foreach {t lk} [array get trig_linked] {
        set linked_from($lk) 1
    }

    # Event names as listed in WAE's Events.ini
    array set ev_names {
        4 "Discovered by Player"
        6 "Attacked by Any House"
        7 "Destroyed by Any House"
        29 "Destroyed by Anything [Not Infiltrate]"
        33 "Selected by Player"
        34 "Comes Near Waypoint"
        38 "First Health (Combat Only)"
        39 "Half Health (Combat Only)"
        40 "Quarter Health (Combat Only)"
        41 "First Health (Any Source)"
        42 "Half Health (Any Source)"
        43 "Quarter Health (Any Source)"
        44 "Attacked By"
        48 "Destroyed by Anything"
    }
    set obj_events {4 6 7 29 33 34 38 39 40 41 42 43 44 48}

    foreach trig [array names ::Data::triggers] {
        if {![info exists ::Data::events($trig)]} continue
        set evlist $::Data::events($trig)
        if {[llength $evlist] == 0} continue
        if {![info exists trig_tags($trig)]} continue
        set ttags $trig_tags($trig)
        set tname $::Data::triggers($trig)

        set codes {}
        foreach ev $evlist { lappend codes [lindex $ev 0] }

        # Event 1 (Entered By): needs an object, celltag, team or linked trigger
        if {[lsearch -exact $codes 1] >= 0} {
            set att 0
            foreach tg $ttags {
                if {[info exists ::Data::tagobjects($tg)] ||
                    [info exists teamtag($tg)] ||
                    [info exists linked_from($trig)] ||
                    [info exists ::Data::tagcelltags($tg)]} {
                    set att 1
                    break
                }
            }
            if {!$att} {
                ::Logging::notice "Trigger '$tname' runs on the \"Entered by...\" event but is not attached to any object, cell or team, so nothing can ever enter it. Attach it to something."
            }
        }

        # Event 31 (Bridge Destroyed): needs a CellTag
        if {[lsearch -exact $codes 31] >= 0} {
            set att 0
            foreach tg $ttags {
                if {[info exists ::Data::tagcelltags($tg)]} {
                    set att 1
                    break
                }
            }
            if {!$att} {
                ::Logging::notice "Trigger '$tname' listens to the \"Bridge destroyed\" event without being attached to a CellTag, so the event can never arrive. Place a CellTag for this trigger."
            }
        }

        # Object-specific events: WAE reports only the first match in its list order
        set found -1
        foreach ec $obj_events {
            if {[lsearch -exact $codes $ec] >= 0} {
                set found $ec
                break
            }
        }
        if {$found >= 0} {
            set att 0
            foreach tg $ttags {
                if {[info exists ::Data::tagobjects($tg)] ||
                    [info exists teamtag($tg)] ||
                    [info exists linked_from($trig)]} {
                    set att 1
                    break
                }
            }
            if {!$att} {
                ::Logging::notice "Trigger '$tname' runs on the $ev_names($found) event but is attached to neither an object nor a team, so nothing can fire it. Attach it first."
            }
        }
    }
    catch {array unset teamtag}
    catch {array unset linked_from}
    catch {array unset trig_tags}
}
