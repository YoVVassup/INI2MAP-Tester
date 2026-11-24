# checks/direct_rocker.tcl
# Validates that DirectRocker=yes warheads do not conflict with ShrapnelWeapon or NukeMaker on weapons
# Game modes: YR/Ares/Phobos
# Uses: is_true, get_cached_property

proc ::Checks::validate_direct_rocker {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::warheads warheads
    upvar ::Data::weapons weapons
    upvar ::Data::projectiles projectiles

    if {$gamemode eq "ra2"} return
    if {![info exists warheads] || ![info exists weapons] || ![info exists projectiles]} return

    set direct_rocker_warheads [list]
    foreach wh [array names warheads] {
        set dr [::Checks::get_cached_property $wh "DirectRocker"]
        if {[::Checks::is_true $dr]} {
            lappend direct_rocker_warheads $wh
        }
    }
    if {[llength $direct_rocker_warheads] == 0} return

    array set weapon_warhead {}
    foreach {idx wep} [array get weapons] {
        set wh [::Checks::get_cached_property $wep "Warhead"]
        if {$wh ne ""} { set weapon_warhead($wep) $wh }
    }

    foreach wep [array names weapon_warhead] {
        set wh $weapon_warhead($wep)
        if {[lsearch -exact $direct_rocker_warheads $wh] == -1} continue

        set proj [::Checks::get_cached_property $wep "Projectile"]
        if {$proj ne ""} {
            set shrapnel [::Checks::get_cached_property $proj "ShrapnelWeapon"]
            if {[::Checks::is_true $shrapnel]} {
                ::Logging::warning "Weapon \"$wep\" uses Warhead \"$wh\" with DirectRocker=yes, but its projectile \"$proj\" has ShrapnelWeapon=yes. DirectRocker=yes disables ShrapnelWeapon for Weapons."
            }
        }

        set nuke [::Checks::get_cached_property $wh "NukeMaker"]
        if {[::Checks::is_true $nuke]} {
            ::Logging::warning "Weapon \"$wep\" uses Warhead \"$wh\" with both DirectRocker=yes and NukeMaker=yes. DirectRocker=yes disables NukeMaker for Weapons."
        }
    }
}

# Register this check
::Checks::register_check "validate_direct_rocker"