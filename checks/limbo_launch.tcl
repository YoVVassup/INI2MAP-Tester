# checks/limbo_launch.tcl
# Validates LimboLaunch weapon flag and warns about building weapon misuse,
#   missing Parasite warhead, Spawner conflicts, and BuildLimit glitches
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Map weapon name -> buildings whose weapon slots use it (built once per run).
# A building is listed at most once per weapon (original warned on first
# matching slot only).
proc ::Checks::_limbo_weapon_buildings {} {
    variable limbo_idx_ready
    variable limbo_idx
    if {$limbo_idx_ready} { return $limbo_idx }
    set limbo_idx [dict create]
    if {[info exists ::Data::buildings]} {
        set seen [dict create]
        foreach bldg [array names ::Data::buildings] {
            foreach slot {Primary Secondary ElitePrimary EliteSecondary} {
                set wep [::Checks::get_cached_property $bldg $slot]
                if {$wep eq ""} continue
                set key "$wep\|$bldg"
                if {[dict exists $seen $key]} continue
                dict set seen $key 1
                dict lappend limbo_idx $wep $bldg
            }
        }
    }
    set limbo_idx_ready 1
    return $limbo_idx
}

proc ::Checks::validate_limbo_launch {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::weapons weapons
    upvar ::Data::warheads warheads
    upvar ::Data::buildings buildings

    # LimboLaunch is applicable to RA2, YR, Ares and Phobos
    # No reason to skip any mode, but bugs persist unless explicitly fixed.
    if {![info exists weapons]} {
        return
    }

    foreach {idx wep_name} [array get weapons] {
        set limbo [::Checks::get_cached_property $wep_name "LimboLaunch"]
        if {![::Checks::is_true $limbo]} {
            continue
        }

        # 1. Basic check for required warhead with Parasite=yes
        set wh_name [::Checks::get_cached_property $wep_name "Warhead"]
        if {$wh_name eq ""} {
            ::Logging::warning "Weapon \"$wep_name\" has LimboLaunch=yes but no Warhead. The weapon will not function correctly."
        } else {
            set parasite [::Checks::get_cached_property $wh_name "Parasite"]
            if {![::Checks::is_true $parasite]} {
                ::Logging::warning "Weapon \"$wep_name\" has LimboLaunch=yes but its Warhead \"$wh_name\" does not have Parasite=yes. This can cause glitches (e.g., BuildLimit still counting the unit after it fires)."
            }
        }

        # 2. Check for Spawner conflict
        set spawner [::Checks::get_cached_property $wep_name "Spawner"]
        if {[::Checks::is_true $spawner]} {
            ::Logging::warning "Weapon \"$wep_name\" has both LimboLaunch=yes and Spawner=yes. LimboLaunch will be ignored."
        }

        # 3. For buildings: this tag is not suitable and will cause problems
        # If any building uses this weapon, warn.
        if {[info exists buildings]} {
            set weapon_buildings [::Checks::_limbo_weapon_buildings]
            if {[dict exists $weapon_buildings $wep_name]} {
                foreach bldg [dict get $weapon_buildings $wep_name] {
                    ::Logging::warning "Building \"$bldg\" uses weapon \"$wep_name\" which has LimboLaunch=yes. LimboLaunch weapons are not suitable for buildings and may cause the building to permanently disappear from the map."
                }
            }
        }
    }
}

::Checks::register_check "validate_limbo_launch"