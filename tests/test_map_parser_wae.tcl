#----------------------------------------------------------------------------------------------------------
# test_map_parser_wae.tcl - Unit tests for the WAE MapLoader / MapIssueChecker reimplementation
# Tests:
#   - process_aircraft            (C1  - new [Aircraft] handling)
#   - check_basic_player          (B6  - [Basic] Player= house / PlayerControl)
#   - process_triggers            (B7  - nonexistent owner, B8 - fewer than 8 fields)
#   - process_actions             (B9  - more than 18 actions)
#   - validate_scripts            (B10 - script with more than 50 actions)
#   - process_houses              (B12 - duplicate house, B13 - Allies=, B14 - no Country=)
#   - process_aitrigger_types     (B15 - AITriggerTypes field count)
#   - process_units               (B16 - FOLLOWS_INDEX)
#   - process_infantry            (B17 - multiple infantry on the same sub-cell)
#   - process_structures          (B18 - applied upgrades)
#   - process_variablenames       (B19 - local variable index / duplicate / syntax)
#   - process_smudge              (B21 - smudge outside the usable map area)
#   - process_waypoints           (B22 - waypoint index / coordinate syntax)
#   - process_celltags            (tagcelltags collection for the C2 checks)
#   - validate_actions / _validate_action_fixed_p1 (B23 - fixed action P1,
#     WAE TriggerFix reimplemented against the modenc Actions_(maps)/RA2YR table)
#   - validate_building_exists     (B24 - WAE event 32 "Building Exists"
#     setup: multiplayer gate, AI house, preplaced structure / base node /
#     deployer unit / TeamType task force)
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

# --------------------------------------------------------------------------
# Source required modules (same order as check_load.tcl)
# --------------------------------------------------------------------------
set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir utils.tcl]
source [file join $script_dir map_parser.tcl]
source [file join $script_dir validators.tcl]
source [file join $script_dir checks.tcl]

# --------------------------------------------------------------------------
# Helper: reset all state touched by the tested procedures
# --------------------------------------------------------------------------
proc reset_state {} {
    foreach arr {
        rawmapdata rulesdata houses countries changeidx aircraft vehicles buildings
        infantry smudges tags triggers events actions teamtypes scripts taskforces
        waypoints wpcoords variables globalvars uvars uglobal infsubcell
        tagobjects tagcelltags unitcoord foundry uhouse ubldg uteam utask uscript
        basicplayer local_aitriggers aitriggertypes allobjects artery paddies
        corner mphouses parent attached bidx iidx uidx aidx allunits terrains
        harvy terrain_foundation ianims anims attacheffects superweapons
        house_country house_playerctl house_basenodes house_units
    } {
        catch {array unset ::Data::${arr}}
    }
    set ::Data::newini 0
    set ::Data::mhouses 0
    set ::Data::countrycnt 0
    set ::Data::strictra2 0
    set ::Data::mismap 0
    set ::Data::mpsonly 0
    set ::Data::housecnt 0
    set ::Data::houselist {}
    set ::Data::maspect 0
    set ::Data::gamemode "ares"
    set ::Data::paranoid 1
    set ::Data::animlog ""
    set ::Data::ignoreglobals 0
    set ::Data::logproc ::Logging::logputs_impl
    set ::Data::maperr {}
    ::Logging::reset_counts
}

# Build an [Actions] value with N actions of "jump to line 1" (code 6, param 1).
# Code 6 with a non-zero parameter does not trigger any additional check.
proc mk_actions {n} {
    set val $n
    for {set i 0} {$i < $n} {incr i} { append val ",6,0,0,0,0,0,0,0" }
    return $val
}

# Run the [Basic] -> [Houses] -> Player= validation sequence
proc run_b6 {} {
    ::MapParser::process_basic
    ::MapParser::process_houses
    ::MapParser::check_basic_player
}

# --------------------------------------------------------------------------
# C1: process_aircraft (new [Aircraft] section handling)
# --------------------------------------------------------------------------
test c1-ac-ok "valid Aircraft entry parses without findings" -body {
    reset_state
    set ::Data::aircraft(AIRCRAFT1) ""
    set ::Data::houses(Eng) ""
    set ::Data::rawmapdata(Aircraft) [list "0=Eng,AIRCRAFT1,100,8,5,0,Guard,None,0,0,0,0"]
    ::MapParser::process_aircraft
    expr {$::Logging::error_count == 0 &&
          $::Logging::warning_count == 0 &&
          $::Logging::notice_count == 0 &&
          [info exists ::Data::unitcoord(8,5)] &&
          ![info exists ::Data::rawmapdata(Aircraft)]}
} -result 1

test c1-ac-missing "Aircraft entry with too few fields errors" -body {
    reset_state
    set ::Data::aircraft(AIRCRAFT1) ""
    set ::Data::houses(Eng) ""
    set ::Data::rawmapdata(Aircraft) [list "0=Eng,AIRCRAFT1"]
    ::MapParser::process_aircraft
    expr {$::Logging::error_count == 1 && $::Logging::warning_count == 0}
} -result 1

test c1-ac-undefined "Aircraft of an undefined type errors" -body {
    reset_state
    set ::Data::houses(Eng) ""
    set ::Data::rawmapdata(Aircraft) [list "0=Eng,NOPE,100,8,5,0,Guard,None,0,0,0,0"]
    ::MapParser::process_aircraft
    expr {$::Logging::error_count == 1 && $::Logging::warning_count == 0}
} -result 1

test c1-ac-bad-vet "Aircraft with an unknown veteran status notices" -body {
    reset_state
    set ::Data::aircraft(AIRCRAFT1) ""
    set ::Data::houses(Eng) ""
    set ::Data::rawmapdata(Aircraft) [list "0=Eng,AIRCRAFT1,100,8,5,0,Guard,None,5,0,0,0"]
    ::MapParser::process_aircraft
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test c1-ac-tag-object "Aircraft with an attached Tag registers the object" -body {
    reset_state
    set ::Data::aircraft(AIRCRAFT1) ""
    set ::Data::houses(Eng) ""
    set ::Data::tags(Tag1) "My Tag"
    set ::Data::rawmapdata(Aircraft) [list "0=Eng,AIRCRAFT1,100,8,5,0,Guard,Tag1,0,0,0,0"]
    ::MapParser::process_aircraft
    expr {$::Logging::error_count == 0 && [info exists ::Data::tagobjects(Tag1)]}
} -result 1

test c1-units-tag-object "Unit with an attached Tag registers the object" -body {
    reset_state
    set ::Data::vehicles(HARV) ""
    set ::Data::houses(Eng) ""
    set ::Data::tags(Tag1) "My Tag"
    set ::Data::rawmapdata(Units) [list "0=Eng,HARV,100,8,5,0,Guard,Tag1,0,0,0,-1,0,0"]
    ::MapParser::process_units
    expr {$::Logging::error_count == 0 && [info exists ::Data::tagobjects(Tag1)]}
} -result 1

# --------------------------------------------------------------------------
# B6: [Basic] Player= house / PlayerControl flag
# --------------------------------------------------------------------------
test b6-ok "existing player house with PlayerControl=yes is silent" -body {
    reset_state
    set ::Data::rawmapdata(Basic) [list "Player=Eng"]
    set ::Data::rawmapdata(Houses) [list "0=Eng"]
    set ::Data::rawmapdata(Eng) [list "Country=England" "PlayerControl=yes"]
    set ::Data::countries(England) 0
    run_b6
    expr {$::Logging::notice_count == 0 && $::Logging::warning_count == 0 &&
          $::Logging::error_count == 0}
} -result 1

test b6-not-controlled "player house without PlayerControl notices" -body {
    reset_state
    set ::Data::rawmapdata(Basic) [list "Player=Eng"]
    set ::Data::rawmapdata(Houses) [list "0=Eng"]
    set ::Data::rawmapdata(Eng) [list "Country=England" "PlayerControl=no"]
    set ::Data::countries(England) 0
    run_b6
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b6-missing-key "player house without a PlayerControl key notices" -body {
    reset_state
    set ::Data::rawmapdata(Basic) [list "Player=Eng"]
    set ::Data::rawmapdata(Houses) [list "0=Eng"]
    set ::Data::rawmapdata(Eng) [list "Country=England"]
    set ::Data::countries(England) 0
    run_b6
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b6-nonexistent "nonexistent Player= house notices" -body {
    reset_state
    set ::Data::rawmapdata(Basic) [list "Player=Ghost"]
    set ::Data::rawmapdata(Houses) [list "0=Eng"]
    set ::Data::rawmapdata(Eng) [list "Country=England"]
    set ::Data::countries(England) 0
    run_b6
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b6-none "Player=<none> is an explicit no-op" -body {
    reset_state
    set ::Data::rawmapdata(Basic) [list "Player=<none>"]
    set ::Data::rawmapdata(Houses) [list "0=Eng"]
    set ::Data::rawmapdata(Eng) [list "Country=England"]
    set ::Data::countries(England) 0
    run_b6
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B7: trigger owner must be a known house type
# --------------------------------------------------------------------------
test b7-bad-owner "trigger with a nonexistent owner warns" -body {
    reset_state
    set ::Data::rawmapdata(Triggers) [list "T1=NoSuchHouse,<none>,Trigger One,0,1,1,1,0"]
    ::MapParser::process_triggers
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0 &&
          [info exists ::Data::triggers(T1)]}
} -result 1

test b7-ok "trigger with a known owner is silent" -body {
    reset_state
    set ::Data::countries(Player) 0
    set ::Data::rawmapdata(Triggers) [list "T1=Player,<none>,Trigger One,0,1,1,1,0"]
    ::MapParser::process_triggers
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0 &&
          [info exists ::Data::triggers(T1)]}
} -result 1

# --------------------------------------------------------------------------
# B8: trigger with fewer than 8 fields
# --------------------------------------------------------------------------
test b8-few-fields "trigger with 3 fields warns but still registers" -body {
    reset_state
    set ::Data::countries(Player) 0
    set ::Data::rawmapdata(Triggers) [list "T1=Player,<none>,T One"]
    ::MapParser::process_triggers
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0 &&
          [info exists ::Data::triggers(T1)]}
} -result 1

test b8-full-fields "trigger with 8 fields is silent" -body {
    reset_state
    set ::Data::countries(Player) 0
    set ::Data::rawmapdata(Triggers) [list "T1=Player,<none>,Trigger One,0,1,1,1,0"]
    ::MapParser::process_triggers
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B9: more than 18 trigger actions
# --------------------------------------------------------------------------
test b9-too-many-actions "19 actions produce one notice and no error" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Actions) [list "T1=[mk_actions 19]"]
    ::MapParser::process_actions
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b9-ten-actions "10 actions are silent" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Actions) [list "T1=[mk_actions 10]"]
    ::MapParser::process_actions
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B10: script with more than 50 actions
# --------------------------------------------------------------------------
test b10-script-51 "51 script actions produce one notice" -body {
    reset_state
    set ::Data::scripts(S1) ""
    set lines [list "Name=Test Script"]
    for {set i 0} {$i < 51} {incr i} { lappend lines "$i=6,1" }
    set ::Data::rawmapdata(S1) $lines
    ::Validators::validate_scripts
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b10-script-50 "50 script actions are silent" -body {
    reset_state
    set ::Data::scripts(S1) ""
    set lines [list "Name=Test Script"]
    for {set i 0} {$i < 50} {incr i} { lappend lines "$i=6,1" }
    set ::Data::rawmapdata(S1) $lines
    ::Validators::validate_scripts
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B12: duplicate house ININame
# --------------------------------------------------------------------------
test b12-duplicate-house "two houses with the same ININame notice once" -body {
    reset_state
    set ::Data::rawmapdata(Houses) [list "0=Eng" "1=Eng"]
    set ::Data::rawmapdata(Eng) [list "Country=England"]
    set ::Data::countries(England) 0
    ::MapParser::process_houses
    expr {$::Logging::notice_count == 1 && $::Logging::warning_count == 0 &&
          $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B13: Allies= referring to a nonexistent house
# --------------------------------------------------------------------------
test b13-unknown-ally "Allies= with an unknown house warns" -body {
    reset_state
    set ::Data::rawmapdata(Houses) [list "0=Eng"]
    set ::Data::rawmapdata(Eng) [list "Country=England" "Allies=Ghost"]
    set ::Data::countries(England) 0
    ::MapParser::process_houses
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b13-known-ally "Allies= with a known house is silent" -body {
    reset_state
    set ::Data::rawmapdata(Houses) [list "0=Eng" "1=Amy"]
    set ::Data::rawmapdata(Eng) [list "Country=England" "Allies=Amy"]
    set ::Data::rawmapdata(Amy) [list "Country=England"]
    set ::Data::countries(England) 0
    ::MapParser::process_houses
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0 &&
          $::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B14: house section without a Country= key
# --------------------------------------------------------------------------
test b14-no-country "house section without Country= warns" -body {
    reset_state
    set ::Data::rawmapdata(Houses) [list "0=Eng"]
    set ::Data::rawmapdata(Eng) [list "PlayerControl=yes"]
    ::MapParser::process_houses
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B15: AITriggerTypes field count (18)
# --------------------------------------------------------------------------
test b15-field-count "AITriggerType with 17 fields warns" -body {
    reset_state
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(AITriggerTypes) \
        [list "AT1=Name,TT1,<all>,5,0,<none>,0,0,0,0,0,0,0,0,<none>,1,1"]
    ::MapParser::process_aitrigger_types
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b15-exact "AITriggerType with 18 fields is silent" -body {
    reset_state
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(AITriggerTypes) \
        [list "AT1=Name,TT1,<all>,5,0,<none>,0,0,0,0,0,0,0,0,<none>,1,1,1"]
    ::MapParser::process_aitrigger_types
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B16: unit FOLLOWS_INDEX
# --------------------------------------------------------------------------
test b16-follows-self "unit following itself notices" -body {
    reset_state
    set ::Data::vehicles(HARV) ""
    set ::Data::houses(Eng) ""
    set ::Data::rawmapdata(Units) [list "0=Eng,HARV,100,8,5,0,Guard,None,0,0,0,0,0,0"]
    ::MapParser::process_units
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b16-follows-duplicate "two units followed by the same follower notice once" -body {
    reset_state
    set ::Data::vehicles(HARV) ""
    set ::Data::houses(Eng) ""
    set ::Data::rawmapdata(Units) [list \
        "0=Eng,HARV,100,8,5,0,Guard,None,0,0,0,1,0,0" \
        "1=Eng,HARV,100,9,5,0,Guard,None,0,0,0,-1,0,0" \
        "2=Eng,HARV,100,10,5,0,Guard,None,0,0,0,1,0,0"]
    ::MapParser::process_units
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b16-follows-negative "follower ID below -1 notices" -body {
    reset_state
    set ::Data::vehicles(HARV) ""
    set ::Data::houses(Eng) ""
    set ::Data::rawmapdata(Units) [list "0=Eng,HARV,100,8,5,0,Guard,None,0,0,0,-5,0,0"]
    ::MapParser::process_units
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B17: multiple infantry on the same sub-cell
# --------------------------------------------------------------------------
test b17-duplicate-subcell "two infantry on the same sub-cell warn" -body {
    reset_state
    set ::Data::infantry(GI) ""
    set ::Data::houses(Eng) ""
    set ::Data::rawmapdata(Infantry) [list \
        "0=Eng,GI,100,8,5,1,Guard,0,None,0,0,0,0,0" \
        "1=Eng,GI,100,8,5,1,Guard,0,None,0,0,0,0,0"]
    ::MapParser::process_infantry
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b17-distinct "infantry on different sub-cells are silent" -body {
    reset_state
    set ::Data::infantry(GI) ""
    set ::Data::houses(Eng) ""
    set ::Data::rawmapdata(Infantry) [list \
        "0=Eng,GI,100,8,5,1,Guard,0,None,0,0,0,0,0" \
        "1=Eng,GI,100,8,5,2,Guard,0,None,0,0,0,0,0"]
    ::MapParser::process_infantry
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B18: applied structure upgrades
# --------------------------------------------------------------------------
test b18-unknown-upgrade "upgrade type missing from rules warns" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::houses(Eng) ""
    set ::Data::rawmapdata(Structures) \
        [list "0=Eng,FACT,100,8,5,0,None,1,0,1,1,0,UPG,None,None,0,0"]
    ::MapParser::process_structures
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b18-powersup-mismatch "upgrade without a matching PowersUpBuilding warns" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::buildings(UPG) ""
    set ::Data::houses(Eng) ""
    set ::Data::rulesdata(UPG) [list "PowersUpBuilding=OTHER"]
    set ::Data::rawmapdata(Structures) \
        [list "0=Eng,FACT,100,8,5,0,None,1,0,1,1,0,UPG,None,None,0,0"]
    ::MapParser::process_structures
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b18-upgrade-count "more upgrades than Upgrades= allows warns" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::buildings(UPG) ""
    set ::Data::houses(Eng) ""
    set ::Data::rulesdata(FACT) [list "Upgrades=0"]
    set ::Data::rulesdata(UPG) [list "PowersUpBuilding=FACT"]
    set ::Data::rawmapdata(Structures) \
        [list "0=Eng,FACT,100,8,5,0,None,1,0,1,1,0,UPG,None,None,0,0"]
    ::MapParser::process_structures
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b18-ok "valid upgrade within the Upgrades= limit is silent" -body {
    reset_state
    set ::Data::buildings(FACT) ""
    set ::Data::buildings(UPG) ""
    set ::Data::houses(Eng) ""
    set ::Data::rulesdata(FACT) [list "Upgrades=2"]
    set ::Data::rulesdata(UPG) [list "PowersUpBuilding=FACT"]
    set ::Data::rawmapdata(Structures) \
        [list "0=Eng,FACT,100,8,5,0,None,1,0,1,1,0,UPG,None,None,0,0"]
    ::MapParser::process_structures
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B19: VariableNames index / duplicate / syntax
# --------------------------------------------------------------------------
test b19-invalid-index "non-integer variable index warns" -body {
    reset_state
    set ::Data::rawmapdata(VariableNames) [list "abc=Name,0"]
    ::MapParser::process_variablenames
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b19-duplicate "duplicate variable index warns" -body {
    reset_state
    set ::Data::rawmapdata(VariableNames) [list "0=Name,0" "0=Other,1"]
    ::MapParser::process_variablenames
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b19-bad-syntax "variable entry without two comma parts warns" -body {
    reset_state
    set ::Data::rawmapdata(VariableNames) [list "0=Name"]
    ::MapParser::process_variablenames
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b19-ok "valid global variable entry is silent" -body {
    reset_state
    set ::Data::rawmapdata(VariableNames) [list "0=Global.Difficulty Hard,0"]
    ::MapParser::process_variablenames
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0 &&
          [info exists ::Data::globalvars(0)] &&
          $::Data::globalvars(0) eq "Difficulty Hard" &&
          ![info exists ::Data::variables(0)]}
} -result 1

# --------------------------------------------------------------------------
# B21: smudge outside the usable map area
# --------------------------------------------------------------------------
test b21-outside "smudge outside the playable area warns" -body {
    reset_state
    array set ::Data::corner {trx 10 tly 10 blx 0 bry 0 brx 10 bly 10}
    set ::Data::maspect 0
    set ::Data::smudges(SCORCH) ""
    set ::Data::rawmapdata(Smudge) [list "0=SCORCH,2,2,0"]
    ::MapParser::process_smudge
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b21-inside "smudge inside the playable area is silent" -body {
    reset_state
    array set ::Data::corner {trx 10 tly 10 blx 0 bry 0 brx 10 bly 10}
    set ::Data::maspect 0
    set ::Data::smudges(SCORCH) ""
    set ::Data::rawmapdata(Smudge) [list "0=SCORCH,8,5,0"]
    ::MapParser::process_smudge
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B22: waypoint index and coordinate syntax.
# The numeric range is owned by num2wp() (errors: wp >= 702 in every mode,
# wp > 25 in strict RA2); B22 reports only what num2wp() accepts silently.
test b22-yr-index-ok "YR-valid indices 101..200 do not warn (FP regression)" -body {
    reset_state
    set ::Data::newini 1
    set ::Data::rawmapdata(Waypoints) [list "101=12345" "200=12345"]
    ::MapParser::process_waypoints
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0 &&
          [info exists ::Data::wpcoords(101)] && [info exists ::Data::wpcoords(200)]}
} -result 1

test b22-yr-max-index "last valid YR index (701) is silent" -body {
    reset_state
    set ::Data::newini 1
    set ::Data::rawmapdata(Waypoints) [list "701=12345"]
    ::MapParser::process_waypoints
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0 &&
          [info exists ::Data::wpcoords(701)]}
} -result 1

test b22-yr-over-limit "index beyond the YR limit is num2wp's error, no warning" -body {
    reset_state
    set ::Data::newini 1
    set ::Data::rawmapdata(Waypoints) [list "702=12345"]
    ::MapParser::process_waypoints
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 1}
} -result 1

test b22-ra2-over-limit "index above the RA2 limit errors in strict RA2" -body {
    reset_state
    set ::Data::newini 1
    set ::Data::strictra2 1
    set ::Data::rawmapdata(Waypoints) [list "101=12345"]
    ::MapParser::process_waypoints
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 1}
} -result 1

test b22-nonint-index "non-integer waypoint index warns" -body {
    reset_state
    set ::Data::newini 1
    set ::Data::rawmapdata(Waypoints) [list "abc=12345"]
    ::MapParser::process_waypoints
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b22-negative-index "negative waypoint index warns (num2wp maps it to A)" -body {
    reset_state
    set ::Data::newini 1
    set ::Data::rawmapdata(Waypoints) [list "-5=12345"]
    ::MapParser::process_waypoints
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0}
} -result 1

test b22-bad-coord "waypoint with an invalid coordinate string warns" -body {
    reset_state
    set ::Data::newini 1
    set ::Data::rawmapdata(Waypoints) [list "5=abc"]
    ::MapParser::process_waypoints
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0 &&
          ![info exists ::Data::wpcoords(5)]}
} -result 1

test b22-ok "valid waypoint index and coordinates are silent" -body {
    reset_state
    set ::Data::newini 1
    set ::Data::rawmapdata(Waypoints) [list "5=12345"]
    ::MapParser::process_waypoints
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0 &&
          [info exists ::Data::wpcoords(5)] && $::Data::wpcoords(5) eq "345,12"}
} -result 1

# --------------------------------------------------------------------------
# CellTags: tagcelltags collection (input for the C2 event-attachment checks)
# --------------------------------------------------------------------------
test celltags-collected "valid CellTag registers the tag for C2" -body {
    reset_state
    set ::Data::tags(Tag1) "My Tag"
    set ::Data::rawmapdata(CellTags) [list "85=Tag1"]
    ::MapParser::process_celltags
    expr {$::Logging::error_count == 0 && $::Logging::warning_count == 0 &&
          [info exists ::Data::tagcelltags(Tag1)]}
} -result 1

# --------------------------------------------------------------------------
# Phobos events / actions / scripts (official Phobos documentation)
# --------------------------------------------------------------------------
test phobos-is-param3 "is_phobos_event_code matches only 3-parameter codes" -body {
    list [::MapParser::is_phobos_event_code 500] \
         [::MapParser::is_phobos_event_code 606] \
         [::MapParser::is_phobos_event_code 603] \
         [::MapParser::is_phobos_event_code 8]
} -result {1 1 0 0}

test phobos-ev-parse "Phobos event line parses as code + three parameters" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Events) [list "T1=1,500,2,0,42"]
    ::MapParser::process_events
    expr {$::Logging::error_count == 0 && $::Logging::warning_count == 0 &&
          $::Data::events(T1) eq [list [list 500 2 0 42]]}
} -result 1

test phobos-ev-mixed "classic and Phobos events share one Events line" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Events) [list "T1=2,8,0,0,500,2,7,42"]
    ::MapParser::process_events
    expr {$::Logging::error_count == 0 && $::Logging::warning_count == 0 &&
          $::Data::events(T1) eq [list [list 8 0 0] [list 500 2 7 42]]}
} -result 1

test phobos-ev-missing "truncated Phobos event reports the missing parameter" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Events) [list "T1=1,500,2,0,"]
    ::MapParser::process_events
    expr {$::Logging::error_count == 1 && $::Logging::warning_count == 0}
} -result 1

test phobos-ev-gap "event 603 assumes 2 parameters and warns" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Events) [list "T1=1,603,2,0"]
    ::MapParser::process_events
    expr {$::Logging::warning_count == 1 && $::Logging::error_count == 0 &&
          $::Data::events(T1) eq [list [list 603 2 0]]}
} -result 1

test phobos-ev-p1-wrong "Phobos event written without P1=2 errors" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::events(T1) [list [list 500 1 0 42]]
    ::Validators::validate_events
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-ev-ok "valid Phobos variable comparison is silent" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::variables(0) "Var0"
    set ::Data::events(T1) [list [list 500 2 0 42]]
    ::Validators::validate_events
    expr {$::Logging::error_count == 0}
} -result 1

test phobos-ev-undef-var "comparison against an undefined local variable errors" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::variables(0) "Var0"
    set ::Data::events(T1) [list [list 500 2 99 42]]
    ::Validators::validate_events
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-ev-601-ok "event 601 accepts a house and a known TechnoType" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::countrycnt 10
    set ::Data::buildings(GATE) ""
    set ::Data::events(T1) [list [list 601 2 0 "GATE"]]
    ::Validators::validate_events
    expr {$::Logging::error_count == 0}
} -result 1

test phobos-ev-601-bad "event 601 rejects a bad house and a bad TechnoType" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::countrycnt 10
    set ::Data::events(T1) [list [list 601 2 99 "NOPE"]]
    ::Validators::validate_events
    expr {$::Logging::error_count == 2}
} -result 1

test phobos-ev-606-ok "event 606 matches the AttachEffectType case-insensitively" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::attacheffects(0) "TestEffect"
    set ::Data::events(T1) [list [list 606 2 0 "testeffect"]]
    ::Validators::validate_events
    expr {$::Logging::error_count == 0}
} -result 1

test phobos-ev-606-bad "event 606 rejects an unknown AttachEffectType" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::attacheffects(0) "TestEffect"
    set ::Data::events(T1) [list [list 606 2 0 "NOPE"]]
    ::Validators::validate_events
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-ev-603-bad "the 603 gap is rejected by validate_events" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::events(T1) [list [list 603 2 0]]
    ::Validators::validate_events
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-ev-strict "strict RA2 rejects Phobos events" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::strictra2 1
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::events(T1) [list [list 500 2 0 42]]
    ::Validators::validate_events
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-act-501-bad-op "action 501 rejects an Operation outside 0-11" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::globalvars(0) "GVar0"
    set ::Data::actions(T1) "1,501,0,0,99,0,1,0,A"
    ::Validators::validate_actions
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-act-501-ok "valid action 501 is silent" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::globalvars(0) "GVar0"
    set ::Data::actions(T1) "1,501,0,0,0,0,1,0,A"
    ::Validators::validate_actions
    expr {$::Logging::error_count == 0}
} -result 1

test phobos-act-600-crate "action 600 rejects a powerup index above 18" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::actions(T1) "1,600,0,1,99,0,0,0,A"
    ::Validators::validate_actions
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-act-511-building "action 511 rejects an unknown BuildingType" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::countrycnt 10
    set ::Data::waypoints(WP) 0
    set ::Data::actions(T1) "1,511,-10,BADNAME,0,0,0,0,WP"
    ::Validators::validate_actions
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-act-511-all "action 511 accepts <All> as the BuildingType" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::countrycnt 10
    set ::Data::waypoints(WP) 0
    set ::Data::actions(T1) "1,511,-10,<All>,0,0,0,0,WP"
    ::Validators::validate_actions
    expr {$::Logging::error_count == 0}
} -result 1

test phobos-act-strict "strict RA2 rejects Phobos actions" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::strictra2 1
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::actions(T1) "1,501,0,0,0,0,0,0,A"
    ::Validators::validate_actions
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-scr-16003-bad "script 16003 rejects a chance above 100" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::scripts(S1) ""
    set ::Data::rawmapdata(S1) [list "0=16003,150"]
    ::Validators::validate_scripts
    expr {$::Logging::error_count == 1 && $::Logging::notice_count == 0}
} -result 1

test phobos-scr-16003-ok "script 16003 accepts a chance of 50" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::scripts(S1) ""
    set ::Data::rawmapdata(S1) [list "0=16003,50"]
    ::Validators::validate_scripts
    expr {$::Logging::error_count == 0}
} -result 1

test phobos-scr-18000-ok "packed script 18000 with a known variable is silent" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::scripts(S1) ""
    set ::Data::variables(5) "Var5"
    set ::Data::rawmapdata(S1) [list "0=18000,327685"]
    ::Validators::validate_scripts
    expr {$::Logging::error_count == 0}
} -result 1

test phobos-scr-18000-bad-low "packed script 18000 with an unknown variable errors" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::scripts(S1) ""
    set ::Data::rawmapdata(S1) [list "0=18000,0"]
    ::Validators::validate_scripts
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-scr-18024-bad-high "packed script 18024 with an unknown local variable errors" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::scripts(S1) ""
    set ::Data::variables(5) "Var5"
    set ::Data::rawmapdata(S1) [list "0=18024,6488069"]
    ::Validators::validate_scripts
    expr {$::Logging::error_count == 1}
} -result 1

test phobos-scr-18048-ok "packed script 18048 with a known global variable is silent" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::scripts(S1) ""
    set ::Data::variables(5) "Var5"
    set ::Data::globalvars(7) "GVar7"
    set ::Data::rawmapdata(S1) [list "0=18048,458757"]
    ::Validators::validate_scripts
    expr {$::Logging::error_count == 0}
} -result 1

test phobos-scr-strict "strict RA2 rejects Phobos script actions" -body {
    reset_state
    set ::Data::gamemode "phobos"
    set ::Data::strictra2 1
    set ::Data::scripts(S1) ""
    set ::Data::rawmapdata(S1) [list "0=16003,50"]
    ::Validators::validate_scripts
    expr {$::Logging::error_count == 1}
} -result 1

# --------------------------------------------------------------------------
# B23: _validate_action_fixed_p1 (WAE TriggerFix, P1 column from modenc)
# --------------------------------------------------------------------------
test b23-fixed-p1-bad "Enable Trigger with P1=0 (documented 2) is flagged" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::triggers(T2) "Target Trigger"
    set ::Data::actions(T1) "1,53,0,T2,0,0,0,0,A"
    ::Validators::validate_actions
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b23-fixed-p1-ok "Enable Trigger with the documented P1=2 is silent" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::triggers(T2) "Target Trigger"
    set ::Data::actions(T1) "1,53,2,T2,0,0,0,0,A"
    ::Validators::validate_actions
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b23-fixed-p1-modenc-11 "Text Trigger accepts the documented P1=4 (WAE demands 0)" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::actions(T1) "1,11,4,SomeCSFLabel,0,0,0,0,A"
    ::Validators::validate_actions
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b23-fixed-p1-101-wae-bogus "action 101 expects P1=0, not WAE's FlashTeam value 4" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::waypoints(WP) 0
    set ::Data::actions(T1) "1,101,4,WP,0,0,0,0,A"
    ::Validators::validate_actions
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b23-fixed-p1-105-modenc "Talk Bubble expects modenc's P1=5, not WAE's 4" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::teamtypes(TEAM1) ""
    set ::Data::actions(T1) "1,105,4,TEAM1,0,0,0,0,0"
    ::Validators::validate_actions
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b23-fixed-p1-105-ok "Talk Bubble with modenc's P1=5 is silent" -body {
    reset_state
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::teamtypes(TEAM1) ""
    set ::Data::actions(T1) "1,105,5,TEAM1,0,0,0,0,0"
    ::Validators::validate_actions
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# B24: validate_building_exists (WAE event 32 "Building Exists" setup)
# Common state: one AI house AIH (country England), trigger T1 owned by
# England with a single Building Exists event for building index 5 (TENT).
# Default expectation: nothing provides the building -> one notice.
# --------------------------------------------------------------------------
proc b24_setup {} {
    reset_state
    set ::Data::bidx(5) "TENT"
    set ::Data::countries(England) 0
    set ::Data::countries(Neutral) 12
    set ::Data::triggers(T1) "Trigger One"
    set ::Data::rawmapdata(Triggers) [list "T1=England,<none>,Trigger One,0,1,1,1,0"]
    set ::Data::events(T1) [list [list 32 0 5]]
    set ::Data::houselist [list "AIH"]
    set ::Data::house_country(AIH) "England"
    set ::Data::house_playerctl(AIH) 0
    set ::Data::house_basenodes(AIH) {}
}

test b24-notice "Building Exists with no way to obtain the building notices" -body {
    b24_setup
    ::Validators::validate_events
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b24-skip-mpsonly "MultiplayerOnly=yes skips the whole check" -body {
    b24_setup
    set ::Data::mpsonly 1
    ::Validators::validate_events
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b24-skip-housecount "more than 50 houses skips the whole check" -body {
    b24_setup
    set ::Data::housecnt 51
    ::Validators::validate_events
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b24-skip-playercontrol "a PlayerControl house is never checked" -body {
    b24_setup
    set ::Data::house_playerctl(AIH) 1
    ::Validators::validate_events
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b24-skip-no-house "no house with the trigger owner country is silent" -body {
    b24_setup
    set ::Data::house_country(AIH) "France"
    ::Validators::validate_events
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b24-owner-neutral-fallback "unknown owner falls back to the Neutral house" -body {
    b24_setup
    set ::Data::rawmapdata(Triggers) [list "T1=Ghost,<none>,Trigger One,0,1,1,1,0"]
    set ::Data::house_country(AIH) "Neutral"
    ::Validators::validate_events
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b24-owner-no-neutral "unknown owner with no Neutral house is silent" -body {
    b24_setup
    set ::Data::rawmapdata(Triggers) [list "T1=Ghost,<none>,Trigger One,0,1,1,1,0"]
    array unset ::Data::countries Neutral
    ::Validators::validate_events
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b24-preplaced "a preplaced structure of that house satisfies the event" -body {
    b24_setup
    set ::Data::rawmapdata(Structures) \
        [list "0=AIH,TENT,100,8,5,0,None,1,0,1,1,0,None,None,None,0,0"]
    ::Validators::validate_events
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b24-preplaced-other-house "a preplaced structure of another house does not count" -body {
    b24_setup
    set ::Data::rawmapdata(Structures) \
        [list "0=OtherH,TENT,100,8,5,0,None,1,0,1,1,0,None,None,None,0,0"]
    ::Validators::validate_events
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b24-base-node "a base node for the building satisfies the event" -body {
    b24_setup
    set ::Data::house_basenodes(AIH) [list "TENT" "POWR"]
    ::Validators::validate_events
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b24-deployer-unit "a preplaced unit with DeploysInto satisfies the event" -body {
    b24_setup
    set ::Data::vehicles(ACV) ""
    set ::Data::rulesdata(ACV) [list "DeploysInto=TENT"]
    set ::Data::house_units(AIH) [list "ACV"]
    ::Validators::validate_events
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b24-deployer-teamtype "a TeamType task force with the deployer satisfies the event" -body {
    b24_setup
    set ::Data::vehicles(ACV) ""
    set ::Data::rulesdata(ACV) [list "DeploysInto=TENT"]
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) [list "Name=Assault" "House=England" "TaskForce=TF1"]
    set ::Data::taskforces(TF1) ""
    set ::Data::rawmapdata(TF1) [list "Name=Strike Force" "0=1,ACV"]
    ::Validators::validate_events
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b24-deployer-rules-taskforce "a rules TaskForce resolves like a map one" -body {
    b24_setup
    set ::Data::vehicles(ACV) ""
    set ::Data::rulesdata(ACV) [list "DeploysInto=TENT"]
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) [list "House=England" "TaskForce=TF1"]
    set ::Data::rulesdata(TaskForces) [list "TF1"]
    set ::Data::rulesdata(TF1) [list "0=1,ACV"]
    ::Validators::validate_events
    expr {$::Logging::notice_count == 0 && $::Logging::error_count == 0}
} -result 1

test b24-teamtype-other-house "a TeamType of another house does not count" -body {
    b24_setup
    set ::Data::vehicles(ACV) ""
    set ::Data::rulesdata(ACV) [list "DeploysInto=TENT"]
    set ::Data::teamtypes(TT1) ""
    set ::Data::rawmapdata(TT1) [list "House=France" "TaskForce=TF1"]
    set ::Data::taskforces(TF1) ""
    set ::Data::rawmapdata(TF1) [list "0=1,ACV"]
    ::Validators::validate_events
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b24-aircraft-not-deployer "a map AircraftTypes entry is not a deployer" -body {
    b24_setup
    set ::Data::vehicles(HELI) ""
    set ::Data::aidx(3) "HELI"
    set ::Data::rulesdata(HELI) [list "DeploysInto=TENT"]
    ::Validators::validate_events
    expr {$::Logging::notice_count == 1 && $::Logging::error_count == 0}
} -result 1

test b24-invalid-index "an unknown building index errors without a notice" -body {
    b24_setup
    set ::Data::events(T1) [list [list 32 0 99]]
    ::Validators::validate_events
    expr {$::Logging::error_count == 1 && $::Logging::notice_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
