# checks/weaponx_ifv.tcl
# Validates WeaponX usage on VehicleTypes for IFV hardcoded limitation
# Game modes: RA2/YR (fixed in Ares)
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/WeaponX
#
# Bug:
#   In original RA2/YR, only one IFV unit is hardcoded to [FV].
#   If any other vehicle uses WeaponX, its turret will not be drawn.
#   Ares fixes this and allows any vehicle to function as IFV.

proc ::Checks::validate_weaponx_ifv {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::vehicles vehicles

    # Fixed in Ares
    if {$gamemode eq "ares" || $gamemode eq "phobos"} return

    if {![info exists vehicles]} return

    foreach veh [array names vehicles] {
        set wx [::Checks::get_cached_property $veh "WeaponX"]
        if {$wx eq ""} continue

        # FV is the hardcoded IFV name
        if {[string toupper $veh] ne "FV"} {
            ::Logging::warning "VehicleType \"$veh\" has WeaponX=\"$wx\". In original RA2/YR, only the hardcoded IFV (FV) supports WeaponX — this vehicle's turret will not be drawn. Ares fixes this limitation."
        }
    }
}

# Register this check
::Checks::register_check "validate_weaponx_ifv"
