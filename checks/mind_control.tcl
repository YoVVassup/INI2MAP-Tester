# checks/mind_control.tcl
# Validates MindControl warhead usage and warns about CellSpread incompatibility,
#   primary/secondary mismatch crashes, DeploysInto ownership bugs, and
#   OccupyWeapon bunker conflicts (some issues fixed in Ares/Phobos)
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Helper: check if a weapon uses a mind-control warhead (defined at namespace scope)
# Uses the prebuilt weapon->warhead map ::Checks::_mc_wep_wh (see validate_mind_control)
proc _uses_mc_warhead {wep_name} {
    upvar mc_warheads mc_warheads
    if {![info exists ::Checks::_mc_wep_wh($wep_name)]} { return 0 }
    set wh $::Checks::_mc_wep_wh($wep_name)
    if {$wh eq ""} { return 0 }
    return [info exists mc_warheads($wh)]
}

proc ::Checks::validate_mind_control {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::weapons weapons
    upvar ::Data::warheads warheads
    upvar ::Data::buildings buildings
    upvar ::Data::vehicles vehicles
    upvar ::Data::infantry infantry
    upvar ::Data::aircraft aircraft

    if {![info exists weapons] || ![info exists warheads]} {
        return
    }

    set is_ares [expr {$gamemode eq "ares" || $gamemode eq "phobos"}]

    # Collect warheads with MindControl=yes
    array set mc_warheads {}
    foreach {idx wh_name} [array get warheads] {
        if {[::Checks::is_true [::Checks::get_cached_property $wh_name "MindControl"]]} {
            set mc_warheads($wh_name) 1
        }
    }

    if {[array size mc_warheads] == 0} {
        return
    }

    # Prebuild weapon -> warhead map (one pass instead of a Warhead lookup
    # per weapon in every section below)
    array set ::Checks::_mc_wep_wh {}
    foreach {idx wep_name} [array get weapons] {
        set ::Checks::_mc_wep_wh($wep_name) [::Checks::get_cached_property $wep_name "Warhead"]
    }
    array set ::Checks::_mc_wh_weps {}
    foreach {wep_name wh} [array get ::Checks::_mc_wep_wh] {
        if {$wh eq ""} continue
        lappend ::Checks::_mc_wh_weps($wh) $wep_name
    }

    # ---- 1. CellSpread and Sub-weapons ----
    foreach {idx wh_name} [array get warheads] {
        if {![info exists mc_warheads($wh_name)]} continue

        set cell_spread [::Checks::get_cached_property $wh_name "CellSpread"]
        if {$cell_spread ne "" && $cell_spread != 0} {
            ::Logging::warning "Warhead \"$wh_name\" has MindControl=yes and CellSpread=$cell_spread. MindControl warheads do not support CellSpread; effect will be single-target only."
        }

        # Check all weapons that use this warhead for sub-weapons
        if {![info exists ::Checks::_mc_wh_weps($wh_name)]} continue
        foreach wep_name $::Checks::_mc_wh_weps($wh_name) {
            foreach sub {ShrapnelWeapon AirburstWeapon} {
                set val [::Checks::get_cached_property $wep_name $sub]
                if {$val ne ""} {
                    ::Logging::warning "Weapon \"$wep_name\" uses MindControl warhead \"$wh_name\" and has $sub=$val. MindControl warheads are incompatible with sub-weapons; the sub-weapon may not work correctly."
                }
            }
        }
    }

    # ---- 2. Primary vs Secondary MindControl mismatch ----
    # Infantry
    if {[info exists infantry]} {
        foreach name [array names infantry] {
            set primary [::Checks::get_cached_property $name "Primary"]
            set secondary [::Checks::get_cached_property $name "Secondary"]
            set elite_secondary [::Checks::get_cached_property $name "EliteSecondary"]

            if {$primary eq ""} {
                if {($secondary ne "" && [::Checks::_uses_mc_warhead $secondary]) ||
                    ($elite_secondary ne "" && [::Checks::_uses_mc_warhead $elite_secondary])} {
                    if {!$is_ares} {
                        ::Logging::warning "Infantry \"$name\" has no Primary weapon, but has a Secondary/EliteSecondary weapon with MindControl=yes. This will cause a crash in game."
                    }
                }
                continue
            }

            set primary_mc [::Checks::_uses_mc_warhead $primary]
            foreach wep [list $secondary $elite_secondary] {
                if {$wep eq ""} continue
                if {[::Checks::_uses_mc_warhead $wep] && !$primary_mc} {
                    if {!$is_ares} {
                        ::Logging::warning "Infantry \"$name\" has Secondary/Elite weapon \"$wep\" with MindControl=yes, but Primary weapon \"$primary\" does not have a MindControl warhead. This will cause a crash in game."
                    }
                }
            }
        }
    }

    # Vehicles
    if {[info exists vehicles]} {
        foreach name [array names vehicles] {
            set primary [::Checks::get_cached_property $name "Primary"]
            set secondary [::Checks::get_cached_property $name "Secondary"]
            set elite_secondary [::Checks::get_cached_property $name "EliteSecondary"]

            if {$primary eq ""} {
                if {($secondary ne "" && [::Checks::_uses_mc_warhead $secondary]) ||
                    ($elite_secondary ne "" && [::Checks::_uses_mc_warhead $elite_secondary])} {
                    if {!$is_ares} {
                        ::Logging::warning "Vehicle \"$name\" has no Primary weapon, but has a Secondary/EliteSecondary weapon with MindControl=yes. This will cause a crash in game."
                    }
                }
                continue
            }

            set primary_mc [::Checks::_uses_mc_warhead $primary]
            foreach wep [list $secondary $elite_secondary] {
                if {$wep eq ""} continue
                if {[::Checks::_uses_mc_warhead $wep] && !$primary_mc} {
                    if {!$is_ares} {
                        ::Logging::warning "Vehicle \"$name\" has Secondary/Elite weapon \"$wep\" with MindControl=yes, but Primary weapon \"$primary\" does not have a MindControl warhead. This will cause a crash in game."
                    }
                }
            }
        }
    }

    # Aircraft
    if {[info exists aircraft]} {
        foreach name [array names aircraft] {
            set primary [::Checks::get_cached_property $name "Primary"]
            set secondary [::Checks::get_cached_property $name "Secondary"]
            set elite_secondary [::Checks::get_cached_property $name "EliteSecondary"]

            if {$primary eq ""} {
                if {($secondary ne "" && [::Checks::_uses_mc_warhead $secondary]) ||
                    ($elite_secondary ne "" && [::Checks::_uses_mc_warhead $elite_secondary])} {
                    if {!$is_ares} {
                        ::Logging::warning "Aircraft \"$name\" has no Primary weapon, but has a Secondary/EliteSecondary weapon with MindControl=yes. This will cause a crash in game."
                    }
                }
                continue
            }

            set primary_mc [::Checks::_uses_mc_warhead $primary]
            foreach wep [list $secondary $elite_secondary] {
                if {$wep eq ""} continue
                if {[::Checks::_uses_mc_warhead $wep] && !$primary_mc} {
                    if {!$is_ares} {
                        ::Logging::warning "Aircraft \"$name\" has Secondary/Elite weapon \"$wep\" with MindControl=yes, but Primary weapon \"$primary\" does not have a MindControl warhead. This will cause a crash in game."
                    }
                }
            }
        }
    }

    # Buildings
    if {[info exists buildings]} {
        foreach name [array names buildings] {
            set primary [::Checks::get_cached_property $name "Primary"]
            set secondary [::Checks::get_cached_property $name "Secondary"]
            set elite_secondary [::Checks::get_cached_property $name "EliteSecondary"]

            if {$primary eq ""} {
                if {($secondary ne "" && [::Checks::_uses_mc_warhead $secondary]) ||
                    ($elite_secondary ne "" && [::Checks::_uses_mc_warhead $elite_secondary])} {
                    if {!$is_ares} {
                        ::Logging::warning "Building \"$name\" has no Primary weapon, but has a Secondary/EliteSecondary weapon with MindControl=yes. This will cause a crash in game."
                    }
                }
                continue
            }

            set primary_mc [::Checks::_uses_mc_warhead $primary]
            foreach wep [list $secondary $elite_secondary] {
                if {$wep eq ""} continue
                if {[::Checks::_uses_mc_warhead $wep] && !$primary_mc} {
                    if {!$is_ares} {
                        ::Logging::warning "Building \"$name\" has Secondary/Elite weapon \"$wep\" with MindControl=yes, but Primary weapon \"$primary\" does not have a MindControl warhead. This will cause a crash in game."
                    }
                }
            }
        }
    }

    # ---- 3. OccupyWeapon MindControl in bunkers ----
    if {[info exists infantry] && [info exists buildings]} {
        foreach inf [array names infantry] {
            set occupy [::Checks::get_cached_property $inf "OccupyWeapon"]
            if {$occupy eq ""} continue
            if {![::Checks::_uses_mc_warhead $occupy]} continue
            foreach bldg [array names buildings] {
                if {![::Checks::is_true [::Checks::get_cached_property $bldg "Bunker"]]} continue
                set primary_bldg [::Checks::get_cached_property $bldg "Primary"]
                if {![::Checks::_uses_mc_warhead $primary_bldg]} {
                    if {!$is_ares} {
                        ::Logging::warning "Bunker building \"$bldg\" has Primary weapon without MindControl, but occupant \"$inf\" has OccupyWeapon=\"$occupy\" with MindControl=yes. This may cause crashes or broken mind-control links."
                    }
                }
            }
        }
    }

    # ---- 4. MindControl + DeploysInto/UndeploysInto ----
    foreach {type_name arr_name} [list Vehicle vehicles Infantry infantry] {
        upvar 0 $arr_name arr
        if {![info exists arr]} continue
        foreach name [array names arr] {
            set deploys_into [::Checks::get_cached_property $name "DeploysInto"]
            set undeploys_into [::Checks::get_cached_property $name "UndeploysInto"]
            if {$deploys_into eq "" && $undeploys_into eq ""} continue
            set primary [::Checks::get_cached_property $name "Primary"]
            if {$primary ne "" && [::Checks::_uses_mc_warhead $primary]} {
                if {!$is_ares} {
                    ::Logging::warning "$type_name \"$name\" has MindControl weapon and DeploysInto/UndeploysInto. Deploying may permanently change ownership (e.g., MCV becomes Construction Yard for the mind-controller)."
                }
            }
        }
    }
}

::Checks::register_check "validate_mind_control"