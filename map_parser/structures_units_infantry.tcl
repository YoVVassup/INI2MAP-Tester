#----------------------------------------------------------------------------------------------------------
# map_parser/structures_units_infantry.tcl - Processing placed objects
# Contains:
#   - process_structures (buildings)
#   - process_aircraft (placed aircraft)
#   - process_units (vehicles)
#   - process_infantry
#   - process_smudge
#   - process_terrain
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

namespace eval ::MapParser {
    # Guard against double loading
    if {[info exists ::MapParser::structures_units_loaded]} { return }
    variable structures_units_loaded 1
}

# --- get_parse_property ---
# Read a property value for a type section during parse_map.
# Raw map section overrides the rules section (same precedence as
# Checks::_find_property). Checks::get_cached_property is unavailable here
# because Checks::build_index only runs later (in run_all).
proc ::MapParser::get_parse_property {section key} {
    foreach src {rawmapdata rulesdata} {
        if {[info exists ::Data::${src}($section)]} {
            foreach line [set ::Data::${src}($section)] {
                set eq [string first "=" $line]
                if {$eq == -1} continue
                set k [string trim [string range $line 0 [expr {$eq-1}]]]
                if {$k eq $key} {
                    return [string trim [string range $line [expr {$eq+1}] end]]
                }
            }
        }
    }
    return ""
}

# --- process_structures ---
# Parse and validate placed building entries from the [Structures] section.
proc ::MapParser::process_structures {} {
    if {![info exists ::Data::rawmapdata(Structures)]} return
    foreach curline $::Data::rawmapdata(Structures) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set line [split [lindex $kv 1] ","]
        set lcnt [llength $line]
        if {$lcnt < 17} {
            ::Logging::error "Structure declaration (index: $pfx) has missing values (got $lcnt, expected 17+)"
            continue
        }
        foreach {house tag j0 j1 j2 j3 att} $line {break}
        if {$tag eq "" || $house eq ""} {
            ::Logging::error "Structure declaration (index: $pfx) has one or more blank values"
            continue
        } elseif {![string is integer -strict $j1] || ![string is integer -strict $j2]} {
            ::Logging::error "Structure declaration (index: $pfx) has non-numeric coordinate values"
            continue
        }
        if {![info exists ::Data::buildings($tag)]} {
            ::Logging::error "placed Structure \"$tag\" (coords: $j1,$j2) not defined"
        } else {
            set ::Data::uhouse($house) ""
        }
        if {![info exists ::Data::houses($house)]} {
            ::Logging::error "placed Structure \"$tag\" (coords: $j1,$j2) has invalid House: $house"
        }
        set ::Data::ubldg($tag) ""
        if {$att ne "None" && ![info exists ::Data::tags($att)]} {
            ::Logging::error "placed Structure \"$tag\" (coords: $j1,$j2) has invalid attached Tag: $att"
        }
        if {$att ne "None" && $att ne ""} {
            set ::Data::tagobjects($att) ""
        }
        # B18: applied upgrades must exist and match the building (WAE
        # MapLoader.ReadBuildings upgrade validation)
        set upgradeCount [lindex $line 10]
        if {[string is integer -strict $upgradeCount] && $upgradeCount > 0} {
            set applied 0
            foreach upg [list [lindex $line 12] [lindex $line 13] [lindex $line 14]] {
                set lu [string tolower [string trim $upg]]
                if {$lu eq "" || $lu eq "<none>" || $lu eq "none"} continue
                if {![info exists ::Data::buildings($upg)]} {
                    ::Logging::warning "Invalid building upgrade specified for building $tag: $upg"
                    continue
                }
                set pusb [::MapParser::get_parse_property $upg "PowersUpBuilding"]
                if {$pusb eq "" || ![string equal -nocase $pusb $tag]} {
                    ::Logging::warning "Building $tag has an upgrade $upg, but $upg does not specify $tag in its PowersUpBuilding= key. Skipping adding upgrade to map."
                    continue
                }
                set maxupg [::MapParser::get_parse_property $tag "Upgrades"]
                if {![string is integer -strict $maxupg]} { set maxupg 0 }
                if {$applied >= $maxupg} {
                    ::Logging::warning "Building $tag at $j1,$j2 has more upgrades ([expr {$applied + 1}]) than specified by its Upgrades= value ($maxupg) in Rules. Skipping adding one or more of the building's upgrades."
                    break
                }
                incr applied
            }
        }
        if {![::MapParser::locatrix $j1 $j2]} {
            ::Logging::error "placed Structure \"$tag\" (coords: $j1,$j2) falls outside usable map area"
        }
        if {[info exists ::Data::artery($tag)]} {
            if {$::Data::artery($tag) eq "1x1"} {
                set locat "$j1,$j2"
                if {[info exists ::Data::foundry($locat)]} {
                    ::Logging::warning "placed Structure \"$tag\" (coords: $locat) has overlap with: $::Data::foundry($locat)"
                } else {
                    set ::Data::foundry($locat) $tag
                }
                continue
            }
            set foundation [split $::Data::artery($tag) "x"]
            if {[llength $foundation] != 2 || ![string is integer -strict [lindex $foundation 0]] || ![string is integer -strict [lindex $foundation 1]]} {
                ::Logging::error "Structure \"$tag\" has invalid foundation format: $::Data::artery($tag)"
                continue
            }
            set letgo 1
            for {set fx 0} {$fx < [lindex $foundation 0]} {incr fx} {
                for {set fy 0} {$fy < [lindex $foundation 1]} {incr fy} {
                    set locat "[expr {$j1 + $fx}],[expr {$j2 + $fy}]"
                    if {[info exists ::Data::foundry($locat)]} {
                        if {$letgo} {
                            ::Logging::warning "placed Structure \"$tag\" (coords: $j1,$j2) has overlap with: $::Data::foundry($locat)"
                            set letgo 0
                        }
                        set ::Data::foundry($locat) $tag
                    } else {
                        set ::Data::foundry($locat) $tag
                    }
                }
            }
        }
    }
    # NOTE: rawmapdata(Structures) is intentionally kept: checks/hospital.tcl,
    # checks/laser_fence_post.tcl, checks/powers_unit.tcl,
    # checks/secret_lab_bonus_count.tcl iterate the placed structures from it.
}

# --- process_aircraft ---
# Parse and validate placed aircraft entries from the [Aircraft] section.
# Mirrors process_units; [Aircraft] layout (WAE MapLoader.ReadAircraft):
# INDEX=OWNER,ID,HEALTH,X,Y,FACING,MISSION,TAG,VETERANCY,GROUP,HIGH,AUTOCREATE*
proc ::MapParser::process_aircraft {} {
    if {![info exists ::Data::rawmapdata(Aircraft)]} return
    foreach curline $::Data::rawmapdata(Aircraft) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set line [split [lindex $kv 1] ","]
        set lcnt [llength $line]
        if {$lcnt < 12} {
            ::Logging::error "Aircraft declaration (index: $pfx) has missing values (got $lcnt, expected 12+)"
            continue
        }
        foreach {house tag j0 j1 j2 j3 ustate att vet} $line {break}
        if {$tag eq "" || $house eq ""} {
            ::Logging::error "Aircraft declaration (index: $pfx) has one or more blank values"
            continue
        } elseif {![string is integer -strict $j1] || ![string is integer -strict $j2]} {
            ::Logging::error "Aircraft declaration (index: $pfx) has non-numeric coordinate values"
            continue
        }
        if {![info exists ::Data::aircraft($tag)]} {
            ::Logging::error "placed Aircraft \"$tag\" (coords: $j1,$j2) not defined"
        } else {
            set ::Data::uhouse($house) ""
        }
        if {![info exists ::Data::houses($house)]} {
            ::Logging::error "placed Aircraft \"$tag\" (coords: $j1,$j2) has invalid House: $house"
        }
        if {$att ne "None" && ![info exists ::Data::tags($att)]} {
            ::Logging::error "placed Aircraft \"$tag\" (coords: $j1,$j2) has invalid attached Tag: $att"
        }
        if {$att ne "None" && $att ne ""} {
            set ::Data::tagobjects($att) ""
        }
        if {![::MapParser::locatrix $j1 $j2]} {
            ::Logging::error "placed Aircraft \"$tag\" (coords: $j1,$j2) falls outside usable map area"
        }
        if {[info exists ::Data::unitcoord($j1,$j2)]} {
            ::Logging::warning "placed Aircraft \"$tag\" (coords: $j1,$j2) has overlap with: $::Data::unitcoord($j1,$j2)"
        } else {
            set ::Data::unitcoord($j1,$j2) $tag
        }
        if {[info exists ::Data::foundry($j1,$j2)] && ![info exists ::Data::paddies($tag)]} {
            ::Logging::warning "placed Aircraft \"$tag\" (coords: $j1,$j2) has overlap with: $::Data::foundry($j1,$j2)"
        }
        if {![::MapParser::statetest $ustate $tag]} {
            ::Logging::warning "placed Aircraft \"$tag\" (coords: $j1,$j2) has potentially invalid State set: $ustate"
        }
        if {![string is integer -strict $vet]} {
            ::Logging::warning "placed Aircraft \"$tag\" (coords: $j1,$j2) has non-numeric veteran status: $vet"
        } elseif {$vet != $::Constants::VETERAN_ROOKIE && $vet != $::Constants::VETERAN_VETERAN && $vet != $::Constants::VETERAN_ELITE} {
            ::Logging::notice "placed Aircraft \"$tag\" (coords: $j1,$j2) has unknown veteran status: $vet"
        }
    }
    unset ::Data::rawmapdata(Aircraft)
}

# --- process_units ---
# Parse and validate placed vehicle entries from the [Units] section.
proc ::MapParser::process_units {} {
    if {![info exists ::Data::rawmapdata(Units)]} return
    set followlist {}
    foreach curline $::Data::rawmapdata(Units) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set line [split [lindex $kv 1] ","]
        set lcnt [llength $line]
        if {$lcnt < 14} {
            ::Logging::error "Unit declaration (index: $pfx) has missing values (got $lcnt, expected 14+)"
            continue
        }
        foreach {house tag j0 j1 j2 j3 ustate att vet} $line {break}
        if {$tag eq "" || $house eq ""} {
            ::Logging::error "Unit declaration (index: $pfx) has one or more blank values"
            continue
        } elseif {![string is integer -strict $j1] || ![string is integer -strict $j2]} {
            ::Logging::error "Unit declaration (index: $pfx) has non-numeric coordinate values"
            continue
        }
        # B24: preplaced unit types per house for the WAE event-32 deployer
        # branch (rawmapdata(Units) is unset at the end of this proc).
        lappend ::Data::house_units($house) $tag
        if {![info exists ::Data::vehicles($tag)]} {
            ::Logging::error "placed Unit \"$tag\" (coords: $j1,$j2) not defined"
        } else {
            set ::Data::uhouse($house) ""
        }
        if {![info exists ::Data::houses($house)]} {
            ::Logging::error "placed Unit \"$tag\" (coords: $j1,$j2) has invalid House: $house"
        }
        if {$att ne "None" && ![info exists ::Data::tags($att)]} {
            ::Logging::error "placed Unit \"$tag\" (coords: $j1,$j2) has invalid attached Tag: $att"
        }
        if {$att ne "None" && $att ne ""} {
            set ::Data::tagobjects($att) ""
        }
        if {![::MapParser::locatrix $j1 $j2]} {
            ::Logging::error "placed Unit \"$tag\" (coords: $j1,$j2) falls outside usable map area"
        }
        if {[info exists ::Data::unitcoord($j1,$j2)]} {
            ::Logging::warning "placed Unit \"$tag\" (coords: $j1,$j2) has overlap with: $::Data::unitcoord($j1,$j2)"
        } else {
            set ::Data::unitcoord($j1,$j2) $tag
        }
        if {[info exists ::Data::foundry($j1,$j2)] && ![info exists ::Data::paddies($tag)]} {
            ::Logging::warning "placed Unit \"$tag\" (coords: $j1,$j2) has overlap with: $::Data::foundry($j1,$j2)"
        }
        if {![::MapParser::statetest $ustate $tag]} {
            ::Logging::warning "placed Unit \"$tag\" (coords: $j1,$j2) has potentially invalid State set: $ustate"
        }
        if {![string is integer -strict $vet]} {
            ::Logging::warning "placed Unit \"$tag\" (coords: $j1,$j2) has non-numeric veteran status: $vet"
        } elseif {$vet != $::Constants::VETERAN_ROOKIE && $vet != $::Constants::VETERAN_VETERAN && $vet != $::Constants::VETERAN_ELITE} {
            ::Logging::notice "placed Unit \"$tag\" (coords: $j1,$j2) has unknown veteran status: $vet"
        }
        # FOLLOWS_INDEX is validated after the loop (needs the full unit list)
        lappend followlist [list $pfx $tag $j1 $j2 [lindex $line 11]]
    }

    # --- B16: FOLLOWS_INDEX checks (WAE MapIssueChecker) ---
    # Field 11 references another unit by its section index (our pfx key).
    array set unitinfo {}
    foreach rec $followlist {
        lassign $rec uf utag ux uy ufol
        set unitinfo($uf) [list $utag $ux $uy]
    }
    array set followed {}
    foreach rec $followlist {
        lassign $rec uf utag ux uy ufol
        if {![string is integer -strict $ufol]} continue
        if {$ufol < -1} {
            ::Logging::notice "Unit \"$utag\" at $ux,$uy has a follower ID below -1. It is unknown how the game reacts to this."
            continue
        }
        if {[string equal $ufol $uf]} {
            ::Logging::notice "Unit \"$utag\" at $ux,$uy follows itself! This can cause the game to crash or freeze!"
            continue
        }
        if {![info exists unitinfo($ufol)]} continue
        if {[info exists followed($ufol)]} {
            lassign $unitinfo($ufol) ttag tx ty
            ::Logging::notice "Multiple units are configured to make unit $ttag at $tx,$ty to follow them! This can cause strange behaviour in the game. $utag at $ux,$uy is one of the followed units."
        } else {
            set followed($ufol) 1
        }
    }
    catch {array unset unitinfo}
    catch {array unset followed}
    unset ::Data::rawmapdata(Units)
}

# --- process_infantry ---
# Parse and validate placed infantry entries from the [Infantry] section.
proc ::MapParser::process_infantry {} {
    if {![info exists ::Data::rawmapdata(Infantry)]} return
    foreach curline $::Data::rawmapdata(Infantry) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set line [split [lindex $kv 1] ","]
        set lcnt [llength $line]
        if {$lcnt < 14} {
            ::Logging::error "Infantry declaration (index: $pfx) has missing values (got $lcnt, expected 14+)"
            continue
        }
        foreach {house tag j0 j1 j2 j3 ustate j4 att vet} $line {break}
        if {$tag eq "" || $house eq ""} {
            ::Logging::error "Infantry declaration (index: $pfx) has one or more blank values"
            continue
        } elseif {![string is integer -strict $j1] || ![string is integer -strict $j2]} {
            ::Logging::error "Infantry declaration (index: $pfx) has non-numeric coordinate values"
            continue
        }
        if {![info exists ::Data::infantry($tag)]} {
            ::Logging::error "placed Infantry \"$tag\" (coords: $j1,$j2) not defined"
        } else {
            set ::Data::uhouse($house) ""
        }
        if {![info exists ::Data::houses($house)]} {
            ::Logging::error "placed Infantry \"$tag\" (coords: $j1,$j2) has invalid House: $house"
        }
        if {$att ne "None" && ![info exists ::Data::tags($att)]} {
            ::Logging::error "placed Infantry \"$tag\" (coords: $j1,$j2) has invalid attached Tag: $att"
        }
        if {$att ne "None" && $att ne ""} {
            set ::Data::tagobjects($att) ""
        }
        if {![::MapParser::locatrix $j1 $j2]} {
            ::Logging::error "placed Infantry \"$tag\" (coords: $j1,$j2) falls outside usable map area"
        }
        if {[info exists ::Data::unitcoord($j1,$j2)]} {
            ::Logging::warning "placed Infantry \"$tag\" (coords: $j1,$j2) has overlap with: $::Data::unitcoord($j1,$j2)"
        }
        if {[info exists ::Data::foundry($j1,$j2)]} {
            ::Logging::warning "placed Infantry \"$tag\" (coords: $j1,$j2) has overlap with: $::Data::foundry($j1,$j2)"
        }
        if {![string is integer -strict $j3]} {
            ::Logging::error "placed Infantry \"$tag\" (coords: $j1,$j2) has non-numeric sub-cell position: $j3"
        } elseif {$j3 < $::Constants::MIN_SUBCELL || $j3 > $::Constants::MAX_SUBCELL} {
            ::Logging::warning "placed Infantry \"$tag\" (coords: $j1,$j2) has invalid sub-cell position: $j3"
        } elseif {$j3 == 4} {
            ::Logging::notice "placed Infantry \"$tag\" (coords: $j1,$j2) has sub-cell position invisible in FA2: $j3"
        }
        # B17: only one infantry may occupy a sub-cell (WAE
        # MapLoader.ReadInfantry MultipleInfantryOnSameSubCell)
        if {[string is integer -strict $j3] &&
            $j3 >= $::Constants::MIN_SUBCELL && $j3 <= $::Constants::MAX_SUBCELL &&
            [::MapParser::locatrix $j1 $j2]} {
            set sckey "$j1,$j2,$j3"
            if {[info exists ::Data::infsubcell($sckey)]} {
                ::Logging::warning "placed Infantry \"$tag\" (coords: $j1,$j2) has multiple infantry on the same sub-cell $j3 (also: $::Data::infsubcell($sckey))"
            } else {
                set ::Data::infsubcell($sckey) $tag
            }
        }
        if {![::MapParser::statetest $ustate $tag]} {
            ::Logging::warning "placed Infantry \"$tag\" (coords: $j1,$j2) has potentially invalid State set: $ustate"
        }
        if {![string is integer -strict $vet]} {
            ::Logging::warning "placed Infantry \"$tag\" (coords: $j1,$j2) has non-numeric veteran status: $vet"
        } elseif {$vet != $::Constants::VETERAN_ROOKIE && $vet != $::Constants::VETERAN_VETERAN && $vet != $::Constants::VETERAN_ELITE} {
            ::Logging::notice "placed Infantry \"$tag\" (coords: $j1,$j2) has unknown veteran status: $vet"
        }
    }
    unset ::Data::rawmapdata(Infantry)
}

# --- process_smudge ---
# Parse and validate placed smudge entries from the [Smudge] section.
proc ::MapParser::process_smudge {} {
    if {![info exists ::Data::rawmapdata(Smudge)]} return
    foreach curline $::Data::rawmapdata(Smudge) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set values [split [lindex $kv 1] ","]
        if {[llength $values] < 4} {
            ::Logging::error "Smudge entry has insufficient fields: [lindex $kv 1]"
            continue
        }
        foreach {tag j0 j1 j2} $values {break}
        if {![info exists ::Data::smudges($tag)]} {
            ::Logging::error "placed Smudge \"$tag\" (coords: $j1,$j2) not defined"
        }
        # B21: smudge must fall inside the usable map area (WAE
        # MapLoader.ReadSmudges.SmudgeOutOfBounds). [Smudge] = TYPE,X,Y,0
        if {[string is integer -strict $j0] && [string is integer -strict $j1] &&
            ![::MapParser::locatrix $j0 $j1]} {
            ::Logging::warning "placed Smudge \"$tag\" (coords: $j0,$j1) falls outside usable map area"
        }
    }
    unset ::Data::rawmapdata(Smudge)
}

# --- process_terrain ---
# Parse and validate placed terrain objects from the [Terrain] section.
proc ::MapParser::process_terrain {} {
    if {![info exists ::Data::rawmapdata(Terrain)]} return
    foreach curline $::Data::rawmapdata(Terrain) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set coords [lindex $kv 0]
        set type [lindex $kv 1]
        if {$::Data::newini} {
            set newk [scan $coords %d]
            # scan gives "" for a non-numeric key; skip the bounds check
            # instead of crashing expr (which aborts the whole map parse)
            if {[string is integer -strict $newk]} {
                set ny [expr {$newk / 1000}]
                set nx [expr {$newk % 1000}]
                if {![::MapParser::locatrix $nx $ny]} {
                    ::Logging::warning "placed Terrain \"$type\" (index: $coords) falls outside usable map area"
                }
            }
        }
        if {![info exists ::Data::terrains($type)]} {
            ::Logging::error "placed Terrain \"$type\" (index: $coords) not defined"
        }
    }
    unset ::Data::rawmapdata(Terrain)
}