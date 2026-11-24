# checks/rot_aircraft.tcl
# Validates aircraft ROT to prevent Strafing mode issues with non-Inviso projectiles; warns when ROT < 2 and projectile is not Inviso.
# Game modes: RA2/YR/Ares/Phobos (all modes; no early gamemode check)
# Uses: ::Checks::get_cached_property, ::Checks::is_true, ::Checks::register_check

# Helper: check if a projectile is Inviso=yes
proc ::Checks::_ra_is_inviso {proj_name} {
    set inviso [::Checks::get_cached_property $proj_name "Inviso"]
    return [::Checks::is_true $inviso]
}

proc ::Checks::validate_rot_aircraft {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::aircraft aircraft

    if {![info exists aircraft]} {
        return
    }

    set is_phobos [expr {$gamemode eq "phobos"}]

    foreach ac [array names aircraft] {
        set rot [::Checks::get_cached_property $ac "ROT"]
        if {$rot eq ""} {
            set rot 0
        }
        if {![string is integer -strict $rot]} {
            ::Logging::warning "Aircraft \"$ac\" has non-integer ROT: $rot"
            continue
        }

        # Only check ROT < 2 (0 or 1)
        if {$rot >= 2} {
            continue
        }

        # Collect weapons used by this aircraft
        set weapons_list [list]
        foreach slot {Primary Secondary ElitePrimary EliteSecondary} {
            set wep [::Checks::get_cached_property $ac $slot]
            if {$wep ne ""} {
                lappend weapons_list $wep
            }
        }

        if {[llength $weapons_list] == 0} {
            continue
        }

        # Check each weapon's projectile
        set has_problem 0
        foreach wep $weapons_list {
            set proj [::Checks::get_cached_property $wep "Projectile"]
            if {$proj eq ""} {
                continue
            }
            if {![::Checks::_ra_is_inviso $proj]} {
                set has_problem 1
                break
            }
        }

        if {$has_problem && !$is_phobos} {
            ::Logging::warning "Aircraft \"$ac\" has ROT=$rot (<2) and uses a non-Inviso projectile. It will enter Strafing mode and cannot attack aerial targets."
        }
    }
}

::Checks::register_check "validate_rot_aircraft"