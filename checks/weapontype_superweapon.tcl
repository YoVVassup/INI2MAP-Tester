# checks/weapontype_superweapon.tcl
# Validates WeaponType usage across SuperWeaponTypes for first-use bug
# Game modes: RA2/YR (fixed in Ares 0.2)
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/WeaponType
#
# Bug (fixed in Ares 0.2):
#   WeaponType is only read on the first super weapon that uses it.
#   If multiple SuperWeaponTypes share the same WeaponType, only the
#   first one's WeaponType is actually used.

proc ::Checks::validate_weapontype_superweapon {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::superweapons superweapons

    # Fixed in Ares 0.2
    if {$gamemode eq "ares" || $gamemode eq "phobos"} return

    if {![info exists superweapons]} return

    set seen_weapons [dict create]
    foreach {idx sw_name} [array get superweapons] {
        set wt [::Checks::get_cached_property $sw_name "WeaponType"]
        if {$wt eq ""} continue

        if {[dict exists $seen_weapons $wt]} {
            set first_sw [dict get $seen_weapons $wt]
            ::Logging::warning "SuperWeaponType \"$sw_name\" has WeaponType=\"$wt\", which is also used by \"$first_sw\". WeaponType is only read on the first super weapon that uses it (fixed in Ares 0.2). \"$sw_name\" will use \"$first_sw\"'s WeaponType."
        } else {
            dict set seen_weapons $wt $sw_name
        }
    }
}

# Register this check
::Checks::register_check "validate_weapontype_superweapon"
