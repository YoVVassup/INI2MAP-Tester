# checks/areafire.tcl
# Validates that AreaFire=yes weapons are not assigned to infantry Primary/ElitePrimary slots and are not combined with LimboLaunch=yes, preventing units from doing nothing or returning before detonation
# Game modes: RA2/YR
# Uses: ::Checks::is_true, ::Checks::get_cached_property, ::Checks::get_all_techno_types

proc ::Checks::validate_areafire {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::weapons weapons
    upvar ::Data::infantry infantry

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return
    if {![info exists weapons]} return

    set areafire_weapons [list]
    foreach {idx wep_name} [array get weapons] {
        set areafire [::Checks::get_cached_property $wep_name "AreaFire"]
        if {[::Checks::is_true $areafire]} {
            lappend areafire_weapons $wep_name
        }
    }
    if {[llength $areafire_weapons] == 0} return

    if {[info exists infantry]} {
        foreach inf [array names infantry] {
            foreach slot {Primary ElitePrimary} {
                set wep [::Checks::get_cached_property $inf $slot]
                if {$wep eq ""} continue
                if {[lsearch -exact $areafire_weapons $wep] != -1} {
                    ::Logging::warning "InfantryType \"$inf\" has AreaFire=yes weapon \"$wep\" assigned as $slot. Infantry can only use AreaFire weapons as deploy weapon (Secondary/EliteSecondary); otherwise they will approach target and do nothing."
                }
            }
        }
    }

    set all_types [::Checks::get_all_techno_types]
    foreach type $all_types {
        foreach slot {Primary Secondary ElitePrimary EliteSecondary} {
            set wep [::Checks::get_cached_property $type $slot]
            if {$wep eq ""} continue
            if {[lsearch -exact $areafire_weapons $wep] == -1} continue

            set limbo_launch [::Checks::get_cached_property $type "LimboLaunch"]
            if {[::Checks::is_true $limbo_launch]} {
                ::Logging::warning "Unit type \"$type\" ($slot weapon \"$wep\") has both AreaFire=yes and LimboLaunch=yes. The unit may return to its original cell before the warhead detonates."
                break
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_areafire"