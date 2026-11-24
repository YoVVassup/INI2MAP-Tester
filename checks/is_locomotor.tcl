# checks/is_locomotor.tcl
# Validates warheads with IsLocomotor=yes for ShrapnelWeapon incompatibility, DeathWeapon failures, harvester unloading issues, Bunker secondary weapon bugs, and BalloonHover crush bugs
# Game modes: YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Helper: check if a weapon uses a locomotor warhead
proc ::Checks::_loco_uses_warhead {wep_name} {
    set wh_name [::Checks::get_cached_property $wep_name "Warhead"]
    if {$wh_name eq ""} {
        return 0
    }
    return [info exists ::Checks::_loco_wh($wh_name)]
}

proc ::Checks::validate_is_locomotor {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::warheads warheads
    upvar ::Data::weapons weapons
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings

    # IsLocomotor is not used in RA2
    if {$gamemode eq "ra2"} {
        return
    }

    set is_phobos [expr {$gamemode eq "phobos"}]

    if {![info exists warheads] || ![info exists weapons]} {
        return
    }

    # Collect all warheads with IsLocomotor=yes into temp namespace var
    array set ::Checks::_loco_wh {}
    foreach {idx wh_name} [array get warheads] {
        set is_locomotor [::Checks::get_cached_property $wh_name "IsLocomotor"]
        if {[::Checks::is_true $is_locomotor]} {
            set ::Checks::_loco_wh($wh_name) 1
        }
    }

    if {[array size ::Checks::_loco_wh] == 0} {
        return
    }

    # 1. ShrapnelWeapon is incompatible with IsLocomotor
    # 2. DeathWeapon cannot use IsLocomotor warhead
    foreach {idx wep_name} [array get weapons] {
        if {![::Checks::_loco_uses_warhead $wep_name]} {
            continue
        }

        # ShrapnelWeapon
        set shrapnel [::Checks::get_cached_property $wep_name "ShrapnelWeapon"]
        if {$shrapnel ne "" && !$is_phobos} {
            ::Logging::warning "Weapon \"$wep_name\" uses a warhead with IsLocomotor=yes and has ShrapnelWeapon=$shrapnel. ShrapnelWeapon will not be created (fixed in Phobos)."
        }
    }

    # DeathWeapon check: iterate over all techno types that have DeathWeapon
    set all_technos [list]
    if {[info exists infantry]} { foreach n [array names infantry] { lappend all_technos [list "Infantry" $n] } }
    if {[info exists vehicles]} { foreach n [array names vehicles] { lappend all_technos [list "Vehicle" $n] } }
    if {[info exists aircraft]} { foreach n [array names aircraft] { lappend all_technos [list "Aircraft" $n] } }
    if {[info exists buildings]} { foreach n [array names buildings] { lappend all_technos [list "Building" $n] } }

    foreach {type name} $all_technos {
        set death_weapon [::Checks::get_cached_property $name "DeathWeapon"]
        if {$death_weapon eq ""} continue
        if {![::Checks::_loco_uses_warhead $death_weapon]} continue
        if {!$is_phobos} {
            ::Logging::warning "$type \"$name\" has DeathWeapon=\"$death_weapon\" which uses an IsLocomotor warhead. Such a DeathWeapon will not work."
        }
    }

    # 3. Harvesters: unloading bug
    if {[info exists vehicles]} {
        foreach veh [array names vehicles] {
            set is_harvester [::Checks::get_cached_property $veh "Harvester"]
            if {![::Checks::is_true $is_harvester]} continue
            if {!$is_phobos} {
                ::Logging::notice "Harvester \"$veh\" exists in a game with IsLocomotor warheads. If any weapon targets it, unloading issues may occur."
                break
            }
        }
    }

    # 4. Bunker buildings: secondary weapons with IsLocomotor cannot lift vehicles out
    if {[info exists buildings]} {
        foreach bldg [array names buildings] {
            set bunker [::Checks::get_cached_property $bldg "Bunker"]
            if {![::Checks::is_true $bunker]} continue
            foreach slot {Secondary EliteSecondary} {
                set wep [::Checks::get_cached_property $bldg $slot]
                if {$wep eq ""} continue
                if {[::Checks::_loco_uses_warhead $wep] && !$is_phobos} {
                    ::Logging::warning "Bunker building \"$bldg\" has $slot weapon \"$wep\" with IsLocomotor warhead. This weapon cannot lift vehicles out of the bunker."
                }
            }
        }
    }

    # 5. BalloonHover units (e.g., ZEP) crush bug
    if {!$is_phobos && ([info exists vehicles] || [info exists aircraft])} {
        set balloon_types [list]
        if {[info exists vehicles]} {
            foreach veh [array names vehicles] {
                if {[::Checks::is_true [::Checks::get_cached_property $veh "BalloonHover"]]} {
                    lappend balloon_types "Vehicle $veh"
                }
            }
        }
        if {[info exists aircraft]} {
            foreach ac [array names aircraft] {
                if {[::Checks::is_true [::Checks::get_cached_property $ac "BalloonHover"]]} {
                    lappend balloon_types "Aircraft $ac"
                }
            }
        }
        if {[llength $balloon_types] > 0} {
            ::Logging::warning "BalloonHover units ([join $balloon_types ", "]) may be affected by IsLocomotor warheads. They may be pulled directly above the firer and fall, crushing it."
        }
    }
}

::Checks::register_check "validate_is_locomotor"