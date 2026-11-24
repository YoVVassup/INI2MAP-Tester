# checks/nuke_maker.tcl
# Validates NukeMaker warhead flag to prevent EIP and weapon triggering issues
# Game modes: YR/Ares/Phobos (flag not present in RA2)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Helper: check if a weapon uses a NukeMaker warhead
proc ::Checks::_nm_uses_warhead {wep_name} {
    set wh [::Checks::get_cached_property $wep_name "Warhead"]
    if {$wh eq ""} { return 0 }
    return [info exists ::Checks::_nm_wh($wh)]
}

proc ::Checks::validate_nuke_maker {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::weapons weapons
    upvar ::Data::warheads warheads
    upvar ::Data::projectiles projectiles

    if {![info exists weapons] || ![info exists warheads]} {
        return
    }

    set is_ares   [expr {$gamemode eq "ares"}]
    set is_phobos [expr {$gamemode eq "phobos"}]

    # Find all warheads with NukeMaker=yes
    array set ::Checks::_nm_wh {}
    foreach {idx wh_name} [array get warheads] {
        set nuke_maker [::Checks::get_cached_property $wh_name "NukeMaker"]
        if {[::Checks::is_true $nuke_maker]} {
            set ::Checks::_nm_wh($wh_name) 1
        }
    }

    if {[array size ::Checks::_nm_wh] == 0} {
        return
    }

    # 1. ShrapnelWeapon not working with NukeMaker
    foreach {idx wep_name} [array get weapons] {
        if {![::Checks::_nm_uses_warhead $wep_name]} {
            continue
        }
        set proj [::Checks::get_cached_property $wep_name "Projectile"]
        if {$proj eq ""} continue
        set shrapnel [::Checks::get_cached_property $proj "ShrapnelWeapon"]
        if {$shrapnel ne ""} {
            ::Logging::warning "Weapon \"$wep_name\" uses NukeMaker warhead, and its projectile \"$proj\" has ShrapnelWeapon=$shrapnel. The shrapnel weapon will not be triggered."
        }
    }

    # 2. NukeMaker weapon as a sub-weapon from ShrapnelWeapon
    foreach {idx master_wep} [array get weapons] {
        set sub_wep [::Checks::get_cached_property $master_wep "ShrapnelWeapon"]
        if {$sub_wep eq ""} continue
        if {[::Checks::_nm_uses_warhead $sub_wep]} {
            if {!$is_ares && !$is_phobos} {
                ::Logging::warning "Weapon \"$master_wep\" has ShrapnelWeapon=\"$sub_wep\" which uses a NukeMaker warhead. In YR, this will cause EIP."
            }
        }
    }

    # 3. NukeMaker weapon as a sub-weapon from AirburstWeapon
    foreach {idx master_wep} [array get weapons] {
        set sub_wep [::Checks::get_cached_property $master_wep "AirburstWeapon"]
        if {$sub_wep eq ""} continue
        if {[::Checks::_nm_uses_warhead $sub_wep]} {
            if {!$is_phobos} {
                ::Logging::warning "Weapon \"$master_wep\" has AirburstWeapon=\"$sub_wep\" which uses a NukeMaker warhead. In YR/Ares (non-Phobos), this will cause EIP."
            }
        }
    }
}

::Checks::register_check "validate_nuke_maker"