# checks/ifv_weapon_system.tcl
# Validates IFV weapon system on Gunner=yes VehicleTypes: TurretCount limits, YTurretIndex duplicates, WeaponTurretIndex consistency, and infantry IFVMode support
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_ifv_weapon_system {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::vehicles vehicles
    upvar ::Data::infantry infantry

    if {![info exists vehicles]} {
        return
    }

    # Max turrets depending on game mode
    set max_turrets 17
    switch -exact -- $gamemode {
        "ra2"   { set max_turrets 13 }
        "yr"    { set max_turrets 17 }
        "ares"  { set max_turrets 127 }
        "phobos" { set max_turrets 127 }
        default { set max_turrets 17 }
    }

    # ---- Collect all IFVMode values supported by any IFV vehicle ----
    array set supported_modes {}

    foreach veh [array names vehicles] {
        set gunner [::Checks::get_cached_property $veh "Gunner"]
        if {![::Checks::is_true $gunner]} continue

        set turret_count [::Checks::get_cached_property $veh "TurretCount"]
        if {$turret_count eq ""} continue
        if {![string is integer -strict $turret_count]} continue
        set tc [expr {$turret_count}]
        if {$tc <= 0} continue

        # 1) Classic YR mechanism: iTurretIndex for i = 0..TurretCount-1
        #    The index i is the IFVMode value.
        for {set i 0} {$i < $tc} {incr i} {
            set idx_val [::Checks::get_cached_property $veh "${i}TurretIndex"]
            if {$idx_val ne "" && [string is integer -strict $idx_val]} {
                set supported_modes($i) 1
            }
        }

        # 2) Ares/Phobos mechanism: WeaponX + WeaponTurretIndexX
        #    The number X (1..WeaponCount) is the IFVMode value.
        set weapon_count [::Checks::get_cached_property $veh "WeaponCount"]
        if {$weapon_count ne "" && [string is integer -strict $weapon_count]} {
            set wc [expr {$weapon_count}]
            for {set w 1} {$w <= $wc} {incr w} {
                # At least one of WeaponX or WeaponTurretIndexX must exist
                set wep [::Checks::get_cached_property $veh "Weapon$w"]
                set wt_idx [::Checks::get_cached_property $veh "WeaponTurretIndex$w"]
                if {$wep ne "" || ($wt_idx ne "" && [string is integer -strict $wt_idx])} {
                    set supported_modes($w) 1
                }
            }
        }
    }

    # ---- Second pass: validate each IFV vehicle (warnings/errors) ----
    foreach veh [array names vehicles] {
        set gunner [::Checks::get_cached_property $veh "Gunner"]
        if {![::Checks::is_true $gunner]} continue

        # TurretCount
        set turret_count [::Checks::get_cached_property $veh "TurretCount"]
        if {$turret_count eq ""} {
            ::Logging::warning "Vehicle \"$veh\" has Gunner=yes but missing TurretCount."
            continue
        }
        if {![string is integer -strict $turret_count]} {
            ::Logging::error "Vehicle \"$veh\" has non-integer TurretCount: $turret_count"
            continue
        }
        set tc [expr {$turret_count}]
        if {$tc <= 0} {
            ::Logging::error "Vehicle \"$veh\" has TurretCount=$tc (must be positive)."
            continue
        }

        # Check against game limits
        if {$tc > $max_turrets} {
            if {$gamemode eq "ra2" || $gamemode eq "yr"} {
                ::Logging::warning "Vehicle \"$veh\" has TurretCount=$tc in $gamemode (max $max_turrets). May cause invisible turrets."
            } elseif {$tc > 127} {
                ::Logging::error "Vehicle \"$veh\" has TurretCount=$tc in $gamemode (max 127)."
            } else {
                ::Logging::notice "Vehicle \"$veh\" has TurretCount=$tc (Ares/Phobos). Ensure all required Y*TurretWeapon entries exist."
            }
        }

        # Duplicate YTurretIndex (iTurretIndex) - classic YR check
        array unset seen_index
        set max_idx [expr {($tc > 0 && $tc <= 128) ? $tc - 1 : 127}]
        for {set i 0} {$i <= $max_idx} {incr i} {
            set idx_val [::Checks::get_cached_property $veh "${i}TurretIndex"]
            if {$idx_val eq ""} continue
            if {![string is integer -strict $idx_val]} {
                ::Logging::warning "Vehicle \"$veh\" has ${i}TurretIndex=\"$idx_val\" (non-integer)."
                continue
            }
            if {[info exists seen_index($idx_val)]} {
                ::Logging::warning "Vehicle \"$veh\" duplicate YTurretIndex $idx_val (indices $seen_index($idx_val) and $i)."
            } else {
                set seen_index($idx_val) $i
            }
        }

        # Check defined Y*TurretWeapon entries (classic)
        set defined 0
        for {set i 0} {$i <= $max_idx} {incr i} {
            set wep [::Checks::get_cached_property $veh "${i}TurretWeapon"]
            if {$wep ne ""} { incr defined }
        }
        if {$defined > 0 && $defined < $tc} {
            ::Logging::warning "Vehicle \"$veh\" has TurretCount=$tc but only $defined Y*TurretWeapon entries defined. Unmapped IFVMode values will use default weapon/turret."
        }

        # Ares-specific: check WeaponTurretIndexX for consistency
        if {$gamemode eq "ares" || $gamemode eq "phobos"} {
            set weapon_count [::Checks::get_cached_property $veh "WeaponCount"]
            if {$weapon_count ne "" && [string is integer -strict $weapon_count]} {
                set wc [expr {$weapon_count}]
                for {set w 1} {$w <= $wc} {incr w} {
                    set wt_idx [::Checks::get_cached_property $veh "WeaponTurretIndex$w"]
                    if {$wt_idx ne "" && ![string is integer -strict $wt_idx]} {
                        ::Logging::warning "Vehicle \"$veh\" has WeaponTurretIndex$w=\"$wt_idx\" (non-integer)."
                    }
                }
            }
        }
    }

    # ---- Third pass: warn about infantry IFVMode not supported by any IFV ----
    if {[info exists infantry]} {
        foreach inf [array names infantry] {
            set mode [::Checks::get_cached_property $inf "IFVMode"]
            if {$mode eq ""} continue
            if {![string is integer -strict $mode]} {
                ::Logging::warning "Infantry \"$inf\" has non-integer IFVMode: $mode"
                continue
            }
            # Mode 0 is the default mode (use vehicle's own weapon), always supported
            if {$mode == 0} {
                continue
            }
            if {![info exists supported_modes($mode)]} {
                ::Logging::notice "Infantry \"$inf\" has IFVMode=$mode but no IFV vehicle supports this mode. Default weapon will be used."
            }
        }
    }
}

::Checks::register_check "validate_ifv_weapon_system"