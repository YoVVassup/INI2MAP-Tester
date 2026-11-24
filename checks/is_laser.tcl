# checks/is_laser.tcl
# Validates buildings with non-Primary laser weapons for the bug where laser parameters are always read from the Primary weapon
# Game modes: RA2/YR/Ares
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_is_laser {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings
    upvar ::Data::weapons weapons

    if {![info exists weapons] || ![info exists buildings]} {
        return
    }

    # Phobos has fixed the bug
    set is_phobos [expr {$gamemode eq "phobos"}]

    # Collect all weapons with IsLaser=yes
    array set laser_weapons {}
    foreach {idx wep_name} [array get weapons] {
        set is_laser [::Checks::get_cached_property $wep_name "IsLaser"]
        if {[::Checks::is_true $is_laser]} {
            set laser_weapons($wep_name) 1
        }
    }

    if {[array size laser_weapons] == 0} {
        return
    }

    # Check each building that uses any laser weapon
    foreach bldg [array names buildings] {
        set found_problem 0
        set has_laser_primary 0
        set non_primary_laser ""

        # Check primary weapon
        set primary [::Checks::get_cached_property $bldg "Primary"]
        if {$primary ne "" && [info exists laser_weapons($primary)]} {
            set has_laser_primary 1
        }

        # Check secondary and elite weapons for lasers
        foreach slot {Secondary ElitePrimary EliteSecondary} {
            set wep [::Checks::get_cached_property $bldg $slot]
            if {$wep eq ""} continue
            if {[info exists laser_weapons($wep)]} {
                if {!$has_laser_primary} {
                    set found_problem 1
                    set non_primary_laser $wep
                    break
                }
            }
        }

        if {$found_problem && !$is_phobos} {
            ::Logging::warning "Building \"$bldg\" has a laser weapon \"$non_primary_laser\" but its Primary weapon is not a laser. In $gamemode, laser parameters are always read from the Primary weapon, so the laser for \"$non_primary_laser\" will not draw correctly (or at all)."
        }
    }
}

::Checks::register_check "validate_is_laser"