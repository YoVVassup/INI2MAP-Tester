# checks/ag_projectile.tcl
# Validates that Projectiles with AG=no are not used as the only weapons on units or buildings, preventing missing attack cursors and target scanning failures
# Game modes: RA2/YR/Ares/Phobos (AG=no building warning suppressed in Phobos where it is fixed)
# Uses: ::Checks::is_true, ::Checks::is_false, ::Checks::get_cached_property, ::Checks::get_all_techno_types

proc ::Checks::validate_ag_projectile {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::weapons weapons
    upvar ::Data::projectiles projectiles
    upvar ::Data::buildings buildings
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft

    if {![info exists projectiles]} return

    set ag_no_proj [list]
    foreach proj [array names projectiles] {
        set ag [::Checks::get_cached_property $proj "AG"]
        if {[::Checks::is_false $ag]} {
            lappend ag_no_proj $proj
        }
    }
    if {![llength $ag_no_proj]} return

    array set weapon_projectile {}
    if {[info exists weapons]} {
        foreach {idx wep} [array get weapons] {
            set proj [::Checks::get_cached_property $wep "Projectile"]
            if {$proj ne ""} { set weapon_projectile($wep) $proj }
        }
    }

    if {[info exists buildings]} {
        foreach bldg [array names buildings] {
            foreach slot {Primary Secondary ElitePrimary EliteSecondary} {
                set wep [::Checks::get_cached_property $bldg $slot]
                if {$wep eq ""} continue
                if {[info exists weapon_projectile($wep)]} {
                    set proj $weapon_projectile($wep)
                    if {[lsearch -exact $ag_no_proj $proj] != -1} {
                        if {$gamemode ne "phobos"} {
                            ::Logging::warning "Building \"$bldg\" uses weapon \"$wep\" with projectile \"$proj\" (AG=no). This building will not get the Attack cursor on ground targets (fixed in Phobos)."
                        }
                        break
                    }
                }
            }
        }
    }

    set all_types [::Checks::get_all_techno_types]
    foreach type $all_types {
        set pri_wep [::Checks::get_cached_property $type "Primary"]
        set sec_wep [::Checks::get_cached_property $type "Secondary"]
        set is_gattling [::Checks::is_true [::Checks::get_cached_property $type "IsGattling"]]

        set pri_proj [expr {($pri_wep ne "" && [info exists weapon_projectile($pri_wep)]) ? $weapon_projectile($pri_wep) : ""}]
        set sec_proj [expr {($sec_wep ne "" && [info exists weapon_projectile($sec_wep)]) ? $weapon_projectile($sec_wep) : ""}]

        if {$pri_proj ne "" && $sec_proj ne ""} {
            set pri_ag_no [expr {[lsearch -exact $ag_no_proj $pri_proj] != -1}]
            set sec_ag_no [expr {[lsearch -exact $ag_no_proj $sec_proj] != -1}]
            if {$pri_ag_no && $sec_ag_no} {
                if {$is_gattling} {
                    ::Logging::warning "Unit \"$type\" (IsGattling=yes) has both weapons' projectiles with AG=no. The unit will be unable to actively scan for targets. Consider setting at least one Secondary weapon projectile to AG=yes."
                } else {
                    ::Logging::warning "Unit \"$type\" has both Primary and Secondary weapons' projectiles with AG=no. The unit will be unable to actively scan for targets. Consider setting Secondary to a weapon with AG=yes projectile."
                }
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_ag_projectile"