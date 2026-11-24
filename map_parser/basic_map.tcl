#----------------------------------------------------------------------------------------------------------
# map_parser/basic_map.tcl - Processing [Basic] and [Map] sections
# Contains:
#   - process_basic: handles Basic section (IgnoreGlobalAITriggers, HomeCell, NewINIFormat, etc.)
#   - process_map: handles Map section (Size, Theater) and sets map bounds
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

namespace eval ::MapParser {
    # Guard against double loading
    if {[info exists ::MapParser::basic_map_loaded]} { return }
    variable basic_map_loaded 1
}

# --- process_basic ---
# Parse the [Basic] section for global settings like HomeCell, NewINIFormat, and movie references.
proc ::MapParser::process_basic {} {
    set ::Data::mpsonly 0
    if {![info exists ::Data::rawmapdata(Basic)]} return
    foreach curline $::Data::rawmapdata(Basic) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        foreach {pfx moop} $kv { break }
        switch -- $pfx {
            "IgnoreGlobalAITriggers" {
                if {[string equal "yes" $moop]} {set ::Data::ignoreglobals 1}
            }
            "HomeCell" - "AltHomeCell" {
                set nom [::MapParser::num2wp $moop]
                set ::Data::waypoints($nom) 1
            }
            "NewINIFormat" {
                if {$moop == 4} {set ::Data::newini 1}
            }
            "MultiplayerOnly" {
                if {$moop == 1} {set ::Data::mismap 1}
                # B24: WAE IsLikelyMultiplayer reads Basic.MultiplayerOnly as a
                # boolean (yes/true/1), independent of the mismap flag above.
                if {[string is true -strict [string trim $moop]]} {set ::Data::mpsonly 1}
            }
            "NumberStartingPoints" {
                set ::Data::mismap 0
            }
            "Player" {
                # B6: kept for check_basic_player (runs right after process_houses)
                set ::Data::basicplayer(current) $moop
            }
            "Intro" - "Brief" - "Action" - "Win" - "Lose" - "PostScore" {
                if {![info exists ::Data::movies($moop)]} {
                    ::Logging::warning "\[Basic\] $pfx refers to invalid movie: $moop"
                }
            }
            "Theme" {
                if {![info exists ::Data::themes_by_name($moop)]} {
                    ::Logging::warning "\[Basic\] Theme refers to invalid music theme: $moop"
                }
            }
        }
    }
    unset ::Data::rawmapdata(Basic)
}

# --- check_basic_player ---
# Validate [Basic] Player= against the house list (WAE MapIssueChecker:
# PlayerHouseNotFound / PlayerHouseNotPlayerControlled).
# Called right after process_houses so the per-house sections are still live
# (process_house_data unsets them later).
proc ::MapParser::check_basic_player {} {
    if {![info exists ::Data::basicplayer(current)]} return
    set player [string trim $::Data::basicplayer(current)]
    if {$player eq ""} return
    # "<none>"/"None" are explicit no-ops
    if {[string equal -nocase $player "<none>"] || [string equal -nocase $player "none"]} return
    if {![info exists ::Data::houses($player)]} {
        ::Logging::notice "A nonexistent house has been specified in \[Basic\] Player= ."
        return
    }
    set pc ""
    if {[info exists ::Data::rawmapdata($player)]} {
        foreach curline $::Data::rawmapdata($player) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            if {[lindex $kv 0] eq "PlayerControl"} {
                set pc [string trim [lindex $kv 1]]
                break
            }
        }
    }
    set truthy [expr {[string equal -nocase $pc "yes"] || [string equal -nocase $pc "true"] || $pc eq "1"}]
    if {!$truthy} {
        ::Logging::notice "The human player's house does not have the \"Player-Controlled\" flag checked."
    }
}

# --- process_map ---
# Parse the [Map] section for Size and Theater, then compute map bounds.
proc ::MapParser::process_map {} {
    if {![info exists ::Data::rawmapdata(Map)]} return
    set msize "1,1,1,1"
    foreach curline $::Data::rawmapdata(Map) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        foreach {pfx val} $kv { break }
        switch -- $pfx {
            "Size" {set msize $val}
            "Theater" {
                set ::Data::theme [string toupper $val]
                switch -- $::Data::theme {
                    "SNOW" - "TEMPERATE" - "URBAN" - "DESERT" - "NEWURBAN" - "LUNAR" {
                        # Valid theater, keep it
                    }
                    default {
                        unset ::Data::theme
                    }
                }
            }
        }
    }
    ::MapParser::mapbounds $msize
    # NOTE: rawmapdata(Map) is intentionally kept: Checks::validate_map
    # (checks/map.tcl) parses Size/LocalSize/Theater from these raw lines.
}