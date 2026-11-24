# checks/use_charge_drain_superweapon.tcl
# Validates UseChargeDrain usage on SuperWeaponTypes
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/UseChargeDrain
#
# Bug:
#   UseChargeDrain was designed specifically for the Firestorm super weapon
#   and has hardcoded behavior. Using it on other SuperWeaponTypes causes
#   unexpected results. For example, using it on Iron Curtain allows
#   firing multiple times during the discharge period because firing
#   does not count as switching it off.

proc ::Checks::validate_use_charge_drain_superweapon {} {
    upvar ::Data::superweapons superweapons

    if {![info exists superweapons]} return

    foreach {idx sw_name} [array get superweapons] {
        set ucd [::Checks::get_cached_property $sw_name "UseChargeDrain"]
        if {![::Checks::is_true $ucd]} continue

        set sw_type [::Checks::get_cached_property $sw_name "Type"]
        set sw_type_lower [string tolower $sw_type]

        # Firestorm is the intended use case
        if {$sw_type_lower eq "firestorm"} continue

        ::Logging::warning "SuperWeaponType \"$sw_name\" (Type=$sw_type) has UseChargeDrain=yes. This flag was designed for Firestorm only and has hardcoded behavior. Using it on other super weapons may cause unintended effects (e.g., Iron Curtain firing multiple times during discharge)."
    }
}

# Register this check
::Checks::register_check "validate_use_charge_drain_superweapon"
