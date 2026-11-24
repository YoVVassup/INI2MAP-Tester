#----------------------------------------------------------------------------------------------------------
# validators_actions.tcl - Action validation for INI2MAP Tester
# Contains:
#   - validate_actions procedure with full action code validation
#   - _validate_action_fixed_p1: WAE TriggerFix reimplementation (fixed P1 vs modenc table)
#   - Uses helper procedures and logging from validators_core.tcl
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Post-validation of Actions (refactored)
# --------------------------------------------------------------------------
# --- validate_actions ---
# Validates all action codes and their parameters for triggers.
proc ::Validators::validate_actions {} {
    # Direct access to ::Data variables (no upvars needed)
    foreach {pfx act_str} [array get ::Data::actions] {
        # Actions may exist for a trigger missing from [Triggers] (kept on
        # purpose so report_unused_extended can flag it): fall back to the raw
        # id instead of reading a non-existent array element.
        set trig_name $pfx
        if {[info exists ::Data::triggers($pfx)]} {
            set trig_name $::Data::triggers($pfx)
        }
        set condie 0
        set curline [split $act_str ","]
        foreach {act1 act2 act3 j0 j1 j2 j3 act4} [lrange $curline 1 end] {
            if {![string is integer -strict $act1] || $act1 < 1} {
                ::Logging::error "Trigger \"$trig_name\" (action: $condie) has invalid action code: $act1 (must be a positive integer)"
                incr condie
                continue
            }
            # The mode owns the range message (ra2/yr/ares: "exceeds maximum",
            # phobos: "not defined in Phobos"). Bail out so the parameter switch
            # below never runs on a code this mode does not know.
            if {![::Validators::validate_action_code $trig_name "action: $condie" $act1]} {
                incr condie
                continue
            }
            # Phobos action codes only exist in phobos mode (every other mode
            # bailed out above), so strict RA2 has no use for them at all.
            if {$act1 >= 500 && $::Data::strictra2 == 1} {
                ::Logging::error "strict RA2 handling mode: Trigger \"$trig_name\" (action: $condie) is NOT available in RA2: $act1"
                incr condie
                continue
            }

            # Action parameter type groups:
            # - Country index      (act3)
            # - TeamType           (act3)
            # - Waypoint           (act4 or act3)
            # - Sound              (act3)
            # - Animation/VoxelAnim/Particles + Waypoint (act3 + act4)
            # - Super Weapon       (act3)
            # - Global/Local Var   (act3)
            # - TechnoType         (act3)
            # Phobos trigger actions (>= 500) share this switch; their slot
            # layout is act1=code act2=P1 act3=P2 j0=P3 j1=P4 j2=P5 j3=P6 act4=P7.
            # (No comment lines may sit between the cases below: a braced
            # switch body is parsed as a list and every stray word shifts
            # the pattern/body pairing.)
            switch -- $act1 {
                1 - 2 - 3 - 6 - 9 - 13 - 14 - 15 - 36 - 37 - 38 - 74 - 75 - 113 -
                119 - 120 - 121 - 122 - 123 - 124 - 126 - 130 - 147 {
                    ::Validators::_validate_action_country $trig_name "action: $condie" $act3
                }
                146 {
                    ::Validators::_validate_action_auxpower $trig_name "action: $condie" $act3 $act4
                }
                4 {
                    ::Validators::_validate_action_team $trig_name "action: $condie" $act3
                }
                5 {
                    if {![info exists ::Data::teamtypes($act3)]} {
                        ::Logging::error "Trigger \"$trig_name\" (action: $condie) cannot destroy invalid TeamType: $act3"
                    }
                }
                7 - 80 - 107 {
                    ::Validators::_validate_action_team_waypoint $trig_name "action: $condie" $act3 $act4
                }
                8 - 48 - 55 - 58 - 94 - 96 - 102 - 109 - 112 - 116 -
                128 - 135 - 137 - 140 {
                    ::Validators::_validate_action_waypoint $trig_name "action: $condie" $act4
                }
                10 - 100 - 117 {
                    ::Validators::_validate_action_movie $trig_name "action: $condie" $act3
                }
                12 {
                    ::Validators::_validate_action_trigger $trig_name "action: $condie" $act3
                }
                17 - 18 - 59 - 63 - 64 - 65 - 66 - 101 {
                    ::Validators::_validate_action_waypoint $trig_name "action: $condie" $act3
                }
                19 - 98 {
                    ::Validators::_validate_action_sound $trig_name "action: $condie" $act3
                }
                20 {
                    ::Validators::_validate_action_theme $trig_name "action: $condie" $act3
                }
                21 {
                    ::Validators::_validate_action_speech $trig_name "action: $condie" $act3
                }
                22 {
                    if {![info exists ::Data::triggers($act3)]} {
                        ::Logging::error "Trigger \"$trig_name\" (action: $condie) cannot force invalid Trigger: $act3"
                    }
                }
                28 - 29 {
                    ::Validators::_validate_action_global_var $trig_name "action: $condie" $act3
                }
                33 - 34 - 129 - 132 - 133 - 134 {
                    ::Validators::_validate_action_superweapon $trig_name "action: $condie" $act3 $act4 $act1
                }
                41 {
                    ::Validators::_validate_action_animation $trig_name "action: $condie" $act3 $act4
                }
                42 {
                    ::Validators::_validate_action_weapon $trig_name "action: $condie" $act3 $act4
                }
                43 {
                    ::Validators::_validate_action_voxelanim $trig_name "action: $condie" $act3 $act4
                }
                53 - 54 {
                    if {![info exists ::Data::triggers($act3)]} {
                        ::Logging::error "Trigger \"$trig_name\" (action: $condie) cannot [expr {$act1 == 53 ? "enable" : "disable"}] invalid Trigger: $act3"
                    }
                }
                56 - 57 {
                    ::Validators::_validate_action_local_var $trig_name "action: $condie" $act3
                }
                70 {
                    if {![info exists ::Data::triggers($act3)]} {
                        ::Logging::error "Trigger \"$trig_name\" (action: $condie) cannot destroy Tags with attached invalid Trigger: $act3"
                    }
                }
                88 - 89 {
                    ::Validators::_validate_action_particles $trig_name "action: $condie" $act3 $act4
                }
                90 - 95 {
                    if {$act3 != 0 && [string equal "A" $act4]} {
                        ::Logging::error "Trigger \"$trig_name\" (action: $condie) specifies Waypoint in incorrect field"
                        continue
                    }
                    ::Validators::_validate_action_waypoint $trig_name "action: $condie" $act4
                }
                99 {
                    ::Validators::_validate_action_sound $trig_name "action: $condie" $act3
                    ::Validators::_validate_action_waypoint $trig_name "action: $condie" $act4
                }
                104 {
                    if {![info exists ::Data::teamtypes($act3)]} {
                        ::Logging::error "Trigger \"$trig_name\" (action: $condie) cannot flash invalid TeamType: $act3"
                    }
                }
                105 {
                    ::Validators::_validate_action_talkbubble $trig_name "action: $condie" $act3 $act4
                }
                106 - 115 {
                    ::Validators::_validate_action_techno $trig_name "action: $condie" $act3
                }
                108 {
                    ::Validators::_validate_action_crate $trig_name "action: $condie" $act3 $act4
                }
                125 {
                    if {$::Data::strictra2 == 1} {
                        ::Logging::error "strict RA2 handling mode: Trigger \"$trig_name\" (action: $condie) is NOT available in RA2: $act1"
                    } else {
                        ::Validators::_validate_action_building $trig_name "action: $condie" $act3 $act4
                    }
                }
                118 - 127 {
                    if {$::Data::strictra2 == 1} {
                        ::Logging::error "strict RA2 handling mode: Trigger \"$trig_name\" (action: $condie) is NOT available in RA2: $act1"
                    }
                }
                131 {
                    ::Validators::_validate_action_flash_building $trig_name "action: $condie" $act3 $act4
                }
                500 {
                    # Save Game - the parameter is a CSF key, no reference.
                }
                501 {
                    # Edit Variable: 501,0,[Var],[Op],[Number],[IsGlobal],0,A
                    ::Validators::_phobos_op $trig_name "action: $condie" $j0
                    ::Validators::_phobos_scope_var $trig_name "action: $condie" $act3 $j2
                    ::Validators::_phobos_int $trig_name "action: $condie" $j1 "Number"
                }
                502 {
                    # Random number: 502,0,[Var],[Min],[Max],[IsGlobal],0,A
                    ::Validators::_phobos_scope_var $trig_name "action: $condie" $act3 $j2
                    ::Validators::_phobos_int $trig_name "action: $condie" $j0 "Min"
                    ::Validators::_phobos_int $trig_name "action: $condie" $j1 "Max"
                }
                503 {
                    # Print variable value: 503,0,[Var],[IsGlobal],0,0,0,A
                    ::Validators::_phobos_scope_var $trig_name "action: $condie" $act3 $j0
                }
                504 {
                    # Binary operation: 504,0,[Var],[Op],[OpVar],[IsGlobal],[IsOpGlobal],A
                    ::Validators::_phobos_op $trig_name "action: $condie" $j0
                    ::Validators::_phobos_scope_var $trig_name "action: $condie" $act3 $j2
                    ::Validators::_phobos_scope_var $trig_name "action: $condie" $j1 $j3
                }
                505 {
                    # Fire Super Weapon at location: SW j0, House j1, X j2, Y j3
                    ::Validators::validate_superweapon $trig_name "action: $condie" $j0
                    ::Validators::_phobos_house $trig_name "action: $condie" $j1 {-1 -2 -3}
                    ::Validators::_phobos_int_range $trig_name "action: $condie" $j2 "CoordinateX" -1 2147483647
                    ::Validators::_phobos_int_range $trig_name "action: $condie" $j3 "CoordinateY" -1 2147483647
                }
                506 {
                    # Fire Super Weapon at waypoint: SW j0, House j1, Waypoint j2
                    ::Validators::validate_superweapon $trig_name "action: $condie" $j0
                    ::Validators::_phobos_house $trig_name "action: $condie" $j1 {-1 -2 -3}
                    ::Validators::validate_waypoint $trig_name "action: $condie" $j2
                }
                510 {
                    # Toggle MCV redeployability: 510,0,0,[MCVRedeploy],0,0,0,A
                    ::Validators::_phobos_int $trig_name "action: $condie" $j0 "MCVRedeploy"
                }
                511 {
                    # Undeploy Building to Waypoint: 511,-10,[Building],[House],0,0,0,[Waypoint]
                    if {$act3 ne "<All>" && ![info exists ::Data::buildings($act3)]} {
                        ::Logging::error "Trigger \"$trig_name\" (action: $condie) refers to invalid Building: $act3"
                    }
                    ::Validators::_phobos_house $trig_name "action: $condie" $j0 {}
                    ::Validators::validate_waypoint $trig_name "action: $condie" $act4
                }
                512 {
                    # Set Follower: 512,0,0,[FollowerIndex],0,0,0,A
                    ::Validators::_phobos_int $trig_name "action: $condie" $j0 "FollowerIndex"
                }
                513 {
                    # Mission timer: type j0 (0-4), value j1, reversed flag j2
                    if {[::Validators::_phobos_int_range $trig_name "action: $condie" $j0 "MissionTimerType" 0 4]} {
                        if {$j0 == 3} {
                            ::Validators::validate_local_var $trig_name "action: $condie" $j1
                        } elseif {$j0 == 4} {
                            ::Validators::validate_global_var $trig_name "action: $condie" $j1
                        } else {
                            ::Validators::_phobos_int $trig_name "action: $condie" $j1 "BaseValue"
                        }
                    }
                    ::Validators::_phobos_int $trig_name "action: $condie" $j2 "ReverseTimer"
                }
                600 {
                    # Configure Drop Crate: behaviour act3 (-1/0/1), powerup index j0
                    if {![string is integer -strict $act3] || $act3 < -1 || $act3 > 1} {
                        ::Logging::error "Trigger \"$trig_name\" (action: $condie) has invalid DropCrate Behaviour: $act3 (must be -1, 0 or 1)"
                    }
                    ::Validators::_phobos_int_range $trig_name "action: $condie" $j0 "powerup index" 0 18
                }
                606 {
                    # Edit Hate-Value: House act3 (-1 = all), Operation j0, Number j1
                    ::Validators::_phobos_house $trig_name "action: $condie" $act3 {-1}
                    ::Validators::_phobos_op $trig_name "action: $condie" $j0
                    ::Validators::_phobos_int $trig_name "action: $condie" $j1 "Number"
                }
                607 {
                    # Clear Hate-Value: House act3 (-1 = all)
                    ::Validators::_phobos_house $trig_name "action: $condie" $act3 {-1}
                }
                608 {
                    # Set Force Enemy: House j0 (-1 removes, -2 never any)
                    ::Validators::_phobos_house $trig_name "action: $condie" $j0 {-1 -2}
                }
                609 {
                    # Set Radar Mode: j0 in 0..3
                    ::Validators::_phobos_int_range $trig_name "action: $condie" $j0 "RadarMode" 0 3
                }
                610 {
                    # Set TeamDelays: any integer, negative falls back to [General]
                    ::Validators::_phobos_int $trig_name "action: $condie" $j0 "Number"
                }
                611 {
                    # Set Next Scenario - the parameter is a map filename, no reference.
                }
                800 - 801 {
                    # Display Banner (local / global variable text): Unique ID j0,
                    # Horizontal j1, Vertical j2, VariableIndex j3
                    ::Validators::_phobos_int $trig_name "action: $condie" $j0 "Unique ID"
                    ::Validators::_phobos_int $trig_name "action: $condie" $j1 "Horizontal position"
                    ::Validators::_phobos_int $trig_name "action: $condie" $j2 "Vertical position"
                    ::Validators::_phobos_scope_var $trig_name "action: $condie" $j3 [expr {$act1 == 800 ? 0 : 1}]
                }
                802 {
                    # Delete Banner: Unique ID act3
                    ::Validators::_phobos_int $trig_name "action: $condie" $act3 "Unique ID"
                }
                default {
                    if {[string is integer -strict $act4]} {
                        ::Validators::validate_waypoint $trig_name "action: $condie" $act4
                    }
                }
            }
            incr condie
        }
    }

    ::Validators::_validate_action_fixed_p1
}

# --------------------------------------------------------------------------
# --- _validate_action_fixed_p1 ---
# Reimplementation of WAE MapLoader.TriggerFix, narrowed to the fixed-P1 check.
#   Sources: WAE src/MapEditorLibrary/Initialization/MapLoader.cs:937-1000
#            modenc Actions_(maps)/RA2YR (authoritative [Actions] reference)
# WAE rewrites action parameters its Actions.ini declares "uncustomizable"
# (P1Type=-N -> abs(N), Unused -> "0", Unused P7 -> "A"). WAE's Actions.ini
# is incomplete for RA2/YR, so the P1 column is taken from modenc instead:
#   - modenc documents 25 fixed P1 values (actions 4..132); WAE declares 10
#     of them, misses 11/19/20/21/98/99/103/104/106/107/115/125/129/131/132
#     and gets 105 wrong (WAE -4, modenc 5);
#   - WAE numbers FlashTeam as 101, while modenc - and this project's action
#     table - put 101 = Reshroud Map At and 104 = Flash Team (map data agrees:
#     all01 "104,5,<TeamType>,...,<frames>").
# With the modenc table the check is silent on sov01/TEST/all01 (0/0/0),
# while WAE's raw rules fire 164/111/156 times on them.
# Not reimplemented: WAE's Unused P2/P6/P7 branch - modenc documents those slots as
# real parameters (103/108/113/114/115 P2, 104/115 P7 duration/frames), and
# the remaining P7 values in "A"-documented slots are unexplained, so that
# branch would only add false positives. Waypoint P7s stay covered by the
# per-action cases in validate_actions.
# Level: notice - the game hardcodes P1, a wrong value does not break
# gameplay, it is a data-format deviation only.
proc ::Validators::_validate_action_fixed_p1 {} {
    # modenc Actions_(maps)/RA2YR fixed P1 values; every other vanilla
    # action (0..145) documents P1=0. Codes >= 146 (Ares/Phobos additions)
    # are not covered by that table and are skipped.
    array set fixed {
        4 1 5 1 7 1 11 4 12 2 19 7 20 8 21 6 22 2
        53 2 54 2 70 3 80 1 98 7 99 7 103 4 104 5
        105 5 106 9 107 1 115 9 125 10 129 11 131 9 132 11
    }
    foreach {pfx act_str} [array get ::Data::actions] {
        set trig_name $pfx
        if {[info exists ::Data::triggers($pfx)]} {
            set trig_name $::Data::triggers($pfx)
        }
        set fields [split $act_str ","]
        set num [lindex $fields 0]
        if {![string is integer -strict $num] || $num < 1} continue
        set pos 1
        for {set i 0} {$i < $num} {incr i} {
            # Only a complete 8-field action record exposes code and P1;
            # short lines are already reported by process_actions (B9).
            if {$pos + 7 >= [llength $fields]} break
            set code [lindex $fields $pos]
            if {[string is integer -strict $code]} {
                set code [expr {$code + 0}]
                if {$code >= 0 && $code <= 145} {
                    set want 0
                    if {[info exists fixed($code)]} {
                        set want $fixed($code)
                    }
                    set p1 [string trim [lindex $fields [expr {$pos + 1}]]]
                    if {$p1 ne $want} {
                        ::Logging::notice "Trigger \"$trig_name\" (action: $i) has invalid fixed P1 for action $code: expected $want, got \"$p1\" (WAE TriggerFix)"
                    }
                }
            }
            incr pos 8
        }
    }
}