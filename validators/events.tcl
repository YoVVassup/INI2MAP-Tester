#----------------------------------------------------------------------------------------------------------
# validators_events.tcl - Event validation for INI2MAP Tester
# Contains:
#   - validate_events procedure with full event code validation
#   - Uses helper procedures and logging from validators_core.tcl
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Post-validation of Events
# --------------------------------------------------------------------------
# --- validate_events ---
# Validates all event codes and their parameters for triggers.
proc ::Validators::validate_events {} {
    foreach {pfx acts} [array get ::Data::events] {
        # Events may exist for a trigger missing from [Triggers] (kept on
        # purpose so report_unused_extended can flag it): fall back to the raw
        # id instead of reading a non-existent array element.
        set trig_name $pfx
        if {[info exists ::Data::triggers($pfx)]} {
            set trig_name $::Data::triggers($pfx)
        }
        set condie 0
        foreach line $acts {
            set act1 [lindex $line 0]
            if {![::Validators::validate_event_code $trig_name "event: $condie" $act1]} {
                incr condie
                continue
            }

            # ---------------- Phobos trigger events (codes >= 500) ----------------
            # Only reachable in phobos mode: every other mode rejects these codes
            # through validate_event_code above. Phobos events are stored as
            # {code, 2, P2, P3} - WAE writes P1=2 so the game reads a third
            # parameter; anything else means the [Events] line is malformed.
            if {$act1 >= 500} {
                if {$::Data::strictra2 == 1} {
                    ::Logging::error "strict RA2 handling mode: Trigger \"$trig_name\" (event: $condie) is NOT available in RA2: $act1"
                    incr condie
                    continue
                }
                if {[lindex $line 1] ne "2"} {
                    ::Logging::error "Trigger \"$trig_name\" (event: $condie) Phobos event $act1 must be written with P1=2 (got: [lindex $line 1])"
                    incr condie
                    continue
                }
                set p2 [lindex $line 2]
                set p3 [lindex $line 3]
                # P2 is always the compared VariableIndex, its local/global scope
                # follows the code group; P3 is a number, a local variable or a
                # global variable depending on the group.
                switch -glob -- $act1 {
                    50[0-5] {
                        ::Validators::_phobos_scope_var $trig_name "event: $condie" $p2 0
                        ::Validators::_phobos_int $trig_name "event: $condie" $p3 "Param"
                    }
                    50[6-9] - 51[01] {
                        ::Validators::_phobos_scope_var $trig_name "event: $condie" $p2 1
                        ::Validators::_phobos_int $trig_name "event: $condie" $p3 "Param"
                    }
                    51[2-7] {
                        ::Validators::_phobos_scope_var $trig_name "event: $condie" $p2 0
                        ::Validators::_phobos_scope_var $trig_name "event: $condie" $p3 0
                    }
                    51[89] - 52[0-3] {
                        ::Validators::_phobos_scope_var $trig_name "event: $condie" $p2 1
                        ::Validators::_phobos_scope_var $trig_name "event: $condie" $p3 0
                    }
                    52[4-9] {
                        ::Validators::_phobos_scope_var $trig_name "event: $condie" $p2 0
                        ::Validators::_phobos_scope_var $trig_name "event: $condie" $p3 1
                    }
                    53[0-5] {
                        ::Validators::_phobos_scope_var $trig_name "event: $condie" $p2 1
                        ::Validators::_phobos_scope_var $trig_name "event: $condie" $p3 1
                    }
                    600 {
                        # Shield broken: documented as 600,2,0,0 - both are dummies.
                        ::Validators::_phobos_int $trig_name "event: $condie" $p2 "Param"
                        ::Validators::_phobos_int $trig_name "event: $condie" $p3 "Param"
                    }
                    60[12] {
                        # House owns / doesn't own a TechnoType (P2 house, P3 techno).
                        ::Validators::_phobos_house $trig_name "event: $condie" $p2 {}
                        ::Validators::validate_technotype $trig_name "event: $condie" $p3
                    }
                    604 {
                        ::Validators::_phobos_house $trig_name "event: $condie" $p2 {-1 -2}
                        ::Validators::validate_technotype $trig_name "event: $condie" $p3
                    }
                    605 {
                        ::Validators::_phobos_house $trig_name "event: $condie" $p2 {-1 -2}
                        ::Validators::_phobos_int_range $trig_name "event: $condie" $p3 "AITargetTypes index" 0 2147483647
                    }
                    606 {
                        # AttachEffect attaching: documented as 606,2,0,[AttachEffectType].
                        ::Validators::_phobos_int $trig_name "event: $condie" $p2 "Param"
                        set ae_found 0
                        if {[info exists ::Data::attacheffects]} {
                            foreach {aeIdx aeName} [array get ::Data::attacheffects] {
                                if {[string equal -nocase $aeName $p3]} {
                                    set ae_found 1
                                    break
                                }
                            }
                        }
                        if {!$ae_found} {
                            ::Logging::error "Trigger \"$trig_name\" (event: $condie) refers to invalid AttachEffectType: $p3"
                        }
                    }
                }
                # Fall through to the classic switch below: no pattern there
                # matches a Phobos code, so it ends up in default {}.
            }
            
            # Event parameter type groups:
            # - Country index / House          (param 2)
            # - BuildingType / VehicleType / InfantryType / AircraftType index  (param 2)
            # - TeamType index                 (param 2)
            # - Variable index (global/local)  (param 2)
            # - Waypoint index                 (param 2)
            # - TechnoType index               (param 3)
            # - SuperWeapon index              (param 2 or 3)
            # - Special checks (Elapsed Time 0, Destroyed, Entered, etc.)
            switch -- $act1 {
                1 - 3 - 24 - 44 {
                    set countryIdx [lindex $line 2]
                    if {[string is integer -strict $countryIdx] && $countryIdx == -1} {
                        ::Logging::notice "Trigger \"$trig_name\" (event: $condie) refers to \"Any\" Country index: $countryIdx"
                    } else {
                        ::Validators::validate_country_index $trig_name "event: $condie" $countryIdx
                    }
                }
                5 - 30 - 53 - 55 - 56 {
                    set countryIdx [lindex $line 2]
                    ::Validators::validate_country_index $trig_name "event: $condie" $countryIdx
                }
                19 - 32 {
                    set bldgIdx [lindex $line 2]
                    if {![info exists ::Data::bidx($bldgIdx)]} {
                        ::Logging::error "Trigger \"$trig_name\" (event: $condie) refers to invalid BuildingType: $bldgIdx"
                    } elseif {$act1 == 32} {
                        # B24: Building Exists setup (WAE MapIssueChecker)
                        ::Validators::validate_building_exists $pfx $trig_name "event: $condie" $bldgIdx
                    }
                }
                20 {
                    set vehIdx [lindex $line 2]
                    if {![info exists ::Data::uidx($vehIdx)]} {
                        ::Logging::error "Trigger \"$trig_name\" (event: $condie) refers to invalid VehicleType: $vehIdx"
                    }
                }
                21 - 33 - 54 {
                    set infIdx [lindex $line 2]
                    if {![info exists ::Data::iidx($infIdx)]} {
                        ::Logging::error "Trigger \"$trig_name\" (event: $condie) refers to invalid InfantryType: $infIdx"
                    }
                }
                22 {
                    set airIdx [lindex $line 2]
                    if {![info exists ::Data::aidx($airIdx)]} {
                        ::Logging::error "Trigger \"$trig_name\" (event: $condie) refers to invalid AircraftType: $airIdx"
                    }
                }
                23 {
                    set teamIdx [lindex $line 2]
                    ::Validators::validate_teamtype $trig_name "event: $condie" $teamIdx
                }
                27 - 28 {
                    set varIdx [lindex $line 2]
                    ::Validators::validate_global_var $trig_name "event: $condie" $varIdx
                }
                34 {
                    set wpIdx [lindex $line 2]
                    ::Validators::validate_waypoint $trig_name "event: $condie" $wpIdx
                }
                36 - 37 {
                    set varIdx [lindex $line 2]
                    ::Validators::validate_local_var $trig_name "event: $condie" $varIdx
                }
                57 {
                    set bldgIdx [lindex $line 2]
                    if {![info exists ::Data::bidx($bldgIdx)]} {
                        ::Logging::error "Trigger \"$trig_name\" (event: $condie) refers to invalid BuildingType: $bldgIdx"
                    } else {
                        set bldgName $::Data::bidx($bldgIdx)
                        if {![info exists ::Data::ubldg($bldgName)]} {
                            ::Logging::warning "Trigger \"$trig_name\" (event: $condie) refers to BuildingType not on map: $bldgName"
                        }
                    }
                }
                60 - 61 {
                    if {$::Data::strictra2 == 1} {
                        ::Logging::error "strict RA2 handling mode: Trigger \"$trig_name\" (event: $condie) is NOT available in RA2: $act1"
                        incr condie
                        continue
                    }
                    set technoIdx [lindex $line 3]
                    if {![info exists ::Data::allunits($technoIdx)] && ![info exists ::Data::buildings($technoIdx)]} {
                        ::Logging::error "Trigger \"$trig_name\" (event: $condie) refers to invalid TechnoType: $technoIdx"
                    }
                }
                63 - 65 - 68 - 70 - 72 - 74 - 84 - 85 - 87 - 88 {
                    set houseIdx [lindex $line 2]
                    if {[string is integer -strict $houseIdx] && $houseIdx >= 0} {
                        if {$houseIdx >= $::Data::countrycnt && ![info exists ::Data::changeidx($houseIdx)] && ![info exists ::Data::mphouses($houseIdx)]} {
                            ::Logging::error "Trigger \"$trig_name\" (event: $condie) refers to invalid Country index: $houseIdx"
                        }
                    }
                }
                75 - 76 {
                    set swIdx [lindex $line 2]
                    ::Validators::validate_superweapon $trig_name "event: $condie" $swIdx
                }
                77 - 78 {
                    set wpIdx [lindex $line 2]
                    set swIdx [lindex $line 3]
                    ::Validators::validate_waypoint $trig_name "event: $condie" $wpIdx
                    ::Validators::validate_superweapon $trig_name "event: $condie" $swIdx
                }
                80 {
                    set techIdx [lindex $line 3]
                    ::Validators::validate_technotype $trig_name "event: $condie" $techIdx
                }
                81 - 82 - 86 {
                    set count [lindex $line 2]
                    set techIdx [lindex $line 3]
                    if {![string is integer -strict $count]} {
                        ::Logging::error "Trigger \"$trig_name\" (event: $condie) has non-integer count: $count"
                    }
                    ::Validators::validate_technotype $trig_name "event: $condie" $techIdx
                }
                default {}
            }
            incr condie
        }
    }
}

# --------------------------------------------------------------------------
# B24: Building Exists event setup (WAE MapIssueChecker)
# --------------------------------------------------------------------------
# --- validate_building_exists ---
# Reimplementation of the WAE MapIssueChecker block "Check for triggers in SP that have a
# Building Exists event but the house belongs to an AI that doesn't ever build
# or deploy a unit into the building" (Misc/MapIssueChecker.cs). Reports a
# notice when the trigger's AI house can never obtain the building: no
# preplaced structure, no base node, and no unit that deploys into it
# (neither preplaced nor inside a TeamType task force of that house).
#   trig_id     trigger INI id (key of the [Events]/[Triggers] line)
#   trig_name   trigger display name (for messages)
#   cond        event context, e.g. "event: 0"
#   bldgIdx     building index (event parameter P2)
proc ::Validators::validate_building_exists {trig_id trig_name cond bldgIdx} {
    # Gate: WAE Map.IsLikelyMultiplayer - on a multiplayer map everything is
    # buildable, so the whole block is skipped.
    if {$::Data::mpsonly || $::Data::housecnt > 50} return

    # Trigger owner = field 0 of the [Triggers] line (WAE Trigger.ParseTrigger).
    # An owner that is not a known HouseType falls back to "Neutral"
    # (WAE MapLoader.ReadTriggers); a trigger without a [Triggers] line is
    # already reported by process_events and takes no part in this check.
    set have 0
    set owner ""
    if {[info exists ::Data::rawmapdata(Triggers)]} {
        foreach tline $::Data::rawmapdata(Triggers) {
            set eq [string first "=" $tline]
            if {$eq == -1} continue
            if {[string trim [string range $tline 0 [expr {$eq - 1}]]] ne $trig_id} continue
            set owner [lindex [split [string range $tline [expr {$eq + 1}] end] ","] 0]
            set have 1
            break
        }
    }
    if {!$have} return
    if {![info exists ::Data::countries($owner)]} {
        if {![info exists ::Data::countries(Neutral)]} return
        set owner "Neutral"
    }

    # The trigger's house = first [Houses] entry whose Country= matches the
    # owner (WAE map.Houses.Find(h => h.HouseType == trigger.HouseType));
    # no match -> silent (the invalid-owner check reports it, B7).
    set hsec ""
    foreach hs $::Data::houselist {
        if {[info exists ::Data::house_country($hs)] && $::Data::house_country($hs) eq $owner} {
            set hsec $hs
            break
        }
    }
    if {$hsec eq ""} return
    # Player-controlled houses are driven by the mappers - only AI houses
    # (WAE house.PlayerControl) take part in this check.
    if {[info exists ::Data::house_playerctl($hsec)] && $::Data::house_playerctl($hsec)} return

    set bldgName $::Data::bidx($bldgIdx)

    # 1) Preplaced structure of that building type owned by that house
    # (WAE map.Structures.Exists(... ObjectType.Index == buildingIndex ...)).
    if {[info exists ::Data::rawmapdata(Structures)]} {
        foreach sline $::Data::rawmapdata(Structures) {
            set kv [::util::_parse_keyval $sline]
            if {$kv eq ""} continue
            set sfields [split [lindex $kv 1] ","]
            if {[string trim [lindex $sfields 1]] eq $bldgName &&
                [string trim [lindex $sfields 0]] eq $hsec} {
                return
            }
        }
    }

    # 2) Base node: the AI house plans to build it itself (WAE
    # house.BaseNodes, read from the D3 keys by process_house_data).
    if {[info exists ::Data::house_basenodes($hsec)] &&
        [lsearch -exact $::Data::house_basenodes($hsec) $bldgName] >= 0} {
        return
    }

    # 3) Unit types that deploy into the building (WAE Rules.UnitTypes with
    # DeploysInto == building: rules + map [VehicleTypes]). ::Data::vehicles
    # also contains map [AircraftTypes] entries - excluded via ::Data::aidx.
    set deployers {}
    array set airnames {}
    foreach {ai an} [array get ::Data::aidx] { set airnames($an) 1 }
    foreach vname [array names ::Data::vehicles] {
        if {[info exists airnames($vname)]} continue
        if {[::MapParser::get_parse_property $vname "DeploysInto"] eq $bldgName} {
            lappend deployers $vname
        }
    }
    array unset airnames
    if {[llength $deployers] > 0} {
        # 3a) Preplaced deployer unit of that house (WAE map.Units.Exists).
        if {[info exists ::Data::house_units($hsec)]} {
            foreach utype $::Data::house_units($hsec) {
                if {[lsearch -exact $deployers $utype] >= 0} return
            }
        }
        # 3b) TeamType of that house whose TaskForce contains a deployer.
        # House= is compared without parent resolution (WAE compares
        # teamType.HouseType == house.HouseType - both plain ININames).
        foreach team [array names ::Data::teamtypes] {
            if {![info exists ::Data::rawmapdata($team)]} continue
            set thouse ""
            set ttf ""
            foreach tline $::Data::rawmapdata($team) {
                set kv [::util::_parse_keyval $tline]
                if {$kv eq ""} continue
                switch -- [string trim [lindex $kv 0]] {
                    "House"     { set thouse [string trim [lindex $kv 1]] }
                    "TaskForce" { set ttf [string trim [lindex $kv 1]] }
                }
            }
            if {$thouse ne $owner || $ttf eq ""} continue
            # TaskForce = map [TaskForces] first, then the rules ones
            # (WAE map.TaskForces.Concat(map.Rules.TaskForces)).
            set tfsec {}
            if {[info exists ::Data::taskforces($ttf)]} {
                if {[info exists ::Data::rawmapdata($ttf)]} {
                    set tfsec $::Data::rawmapdata($ttf)
                }
            } elseif {[info exists ::Data::rulesdata(TaskForces)] &&
                      [lsearch -exact $::Data::rulesdata(TaskForces) $ttf] >= 0 &&
                      [info exists ::Data::rulesdata($ttf)]} {
                set tfsec $::Data::rulesdata($ttf)
            }
            if {$tfsec eq {}} continue
            foreach fline $tfsec {
                set kv [::util::_parse_keyval $fline]
                if {$kv eq ""} continue
                # "N=count,Type" entries only (Name=/Group= are skipped)
                if {![string is integer -strict [string trim [lindex $kv 0]]]} continue
                set ftype [string trim [lindex [split [lindex $kv 1] ","] 1]]
                if {$ftype ne "" && [lsearch -exact $deployers $ftype] >= 0} {
                    return
                }
            }
        }
    }

    # Nothing can ever provide the building: the trigger will never spring.
    set disp [::MapParser::get_parse_property $bldgName "Name"]
    if {$disp eq ""} { set disp $bldgName }
    ::Logging::notice "Trigger \"$trig_name\" ($cond) checks Building Exists for building $bldgIdx ($disp), but house '$hsec' has no preplaced structure, no base node and no deploying unit for it, so the condition can never become true. Set the correct house, or give that house the unit through a TeamType."
}