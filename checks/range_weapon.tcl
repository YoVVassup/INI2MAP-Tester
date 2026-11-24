# checks/range_weapon.tcl
# Validates weapon Range flag to prevent EIP and performance issues
# Game modes: RA2/YR/Ares/Phobos (all)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#   - Range=-2 (infinite) combined with missing GuardRange -> passive units
#   - Range=-2 with DiskLaser=yes -> weapon never charges
#   - Range=-2 on aircraft -> cannot attack
#   - Range > 11 on ShrapnelWeapon may cause EIP
#   - Buildings use only Primary weapon's Range; secondary weapons with higher Range are useless
#   - Excessive Range (> 100) may cause performance issues
# Uses ::Checks::is_true, ::Checks::is_false, ::Checks::get_cached_property

proc ::Checks::validate_range_weapon {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::weapons weapons
    upvar ::Data::projectiles projectiles
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings

    if {![info exists weapons]} {
        return
    }

    set is_ares   [expr {$gamemode eq "ares"}]
    set is_phobos [expr {$gamemode eq "phobos"}]

    # Collect all weapons with Range=-2
    array set infinite_range_weapons {}
    # Collect all ShrapnelWeapon relationships
    array set shrapnel_map {}

    foreach {idx wep} [array get weapons] {
        set range [::Checks::get_cached_property $wep "Range"]
        if {$range eq ""} continue
        if {![string is double -strict $range]} {
            ::Logging::warning "Weapon \"$wep\" has non-numeric Range: $range"
            continue
        }

        if {$range == -2.0} {
            set infinite_range_weapons($wep) 1
        }

        # Check for extreme range (performance)
        if {$range > 100} {
            ::Logging::warning "Weapon \"$wep\" has Range=$range (>100). This may cause performance issues due to GuardRange inheritance."
        }

        # Check for ShrapnelWeapon reference
        set shrapnel [::Checks::get_cached_property $wep "ShrapnelWeapon"]
        if {$shrapnel ne ""} {
            lappend shrapnel_map($shrapnel) $wep
        }
    }

    # ---- Range = -2 specific checks ----
    if {[array size infinite_range_weapons] > 0} {
        # Aircraft cannot attack with Range=-2
        if {[info exists aircraft]} {
            foreach ac [array names aircraft] {
                set primary [::Checks::get_cached_property $ac "Primary"]
                if {$primary ne "" && [info exists infinite_range_weapons($primary)]} {
                    ::Logging::warning "Aircraft \"$ac\" has Primary weapon \"$primary\" with Range=-2. Aircraft cannot perform attack actions with Range=-2."
                }
                set elite_primary [::Checks::get_cached_property $ac "ElitePrimary"]
                if {$elite_primary ne "" && [info exists infinite_range_weapons($elite_primary)]} {
                    ::Logging::warning "Aircraft \"$ac\" has ElitePrimary weapon \"$elite_primary\" with Range=-2. Aircraft cannot perform attack actions with Range=-2."
                }
            }
        }

        # DiskLaser=yes + Range=-2 -> cannot fire
        foreach wep [array names infinite_range_weapons] {
            set is_laser [::Checks::get_cached_property $wep "IsLaser"]
            set is_big_laser [::Checks::get_cached_property $wep "IsBigLaser"]
            set disk_laser [::Checks::get_cached_property $wep "DiskLaser"]
            if {[::Checks::is_true $disk_laser] && ([::Checks::is_true $is_laser] || [::Checks::is_true $is_big_laser])} {
                ::Logging::warning "Weapon \"$wep\" has Range=-2 and DiskLaser=yes. The weapon will never start charging and cannot fire."
            }
        }

        # Check GuardRange presence for units using infinite-range weapons
        set all_technos [list]
        if {[info exists ::Data::infantry]} {
            foreach n [array names ::Data::infantry] { lappend all_technos $n }
        }
        if {[info exists ::Data::vehicles]} {
            foreach n [array names ::Data::vehicles] { lappend all_technos $n }
        }
        if {[info exists ::Data::aircraft]} {
            foreach n [array names ::Data::aircraft] { lappend all_technos $n }
        }

        foreach techno $all_technos {
            foreach slot {Primary Secondary ElitePrimary EliteSecondary} {
                set wep [::Checks::get_cached_property $techno $slot]
                if {$wep ne "" && [info exists infinite_range_weapons($wep)]} {
                    set guard_range [::Checks::get_cached_property $techno "GuardRange"]
                    if {$guard_range eq ""} {
                        ::Logging::warning "TechnoType \"$techno\" uses infinite-range weapon \"$wep\" but has no GuardRange defined. The unit will not actively seek out enemies. Set GuardRange manually."
                    }
                    break
                }
            }
        }

        # Range=-2 ignores MinimumRange (inform)
        foreach wep [array names infinite_range_weapons] {
            set min_range [::Checks::get_cached_property $wep "MinimumRange"]
            if {$min_range ne "" && $min_range != 0} {
                ::Logging::notice "Weapon \"$wep\" has Range=-2 and MinimumRange=$min_range. The MinimumRange will be ignored because the weapon has infinite range."
            }
        }
    }

    # ---- ShrapnelWeapon range > 11 EIP check ----
    if {[array size shrapnel_map] > 0 && (!$is_ares && !$is_phobos)} {
        foreach sub_wep [array names shrapnel_map] {
            set sub_range [::Checks::get_cached_property $sub_wep "Range"]
            if {$sub_range eq ""} continue
            if {![string is double -strict $sub_range]} continue
            if {$sub_range > 11} {
                foreach master_wep $shrapnel_map($sub_wep) {
                    ::Logging::warning "Weapon \"$sub_wep\" is used as ShrapnelWeapon by \"$master_wep\" and has Range=$sub_range (>11). This may cause EIP (aims regardless of distance)."
                }
            }
        }
    }

    # ---- Buildings: only Primary weapon's Range matters ----
    if {[info exists buildings]} {
        foreach bldg [array names buildings] {
            set primary [::Checks::get_cached_property $bldg "Primary"]
            if {$primary eq ""} continue
            set primary_range [::Checks::get_cached_property $primary "Range"]
            if {$primary_range eq ""} continue
            if {![string is double -strict $primary_range]} continue
            foreach slot {Secondary ElitePrimary EliteSecondary} {
                set wep [::Checks::get_cached_property $bldg $slot]
                if {$wep eq ""} continue
                set wep_range [::Checks::get_cached_property $wep "Range"]
                if {$wep_range eq ""} continue
                if {![string is double -strict $wep_range]} continue
                if {$wep_range > $primary_range} {
                    ::Logging::warning "Building \"$bldg\" has $slot weapon \"$wep\" with Range=$wep_range > Primary Range=$primary_range. The building uses only the Primary weapon's Range to determine its attack range, so the secondary weapon will never be used at its full potential."
                }
            }
        }
    }
}

::Checks::register_check "validate_range_weapon"