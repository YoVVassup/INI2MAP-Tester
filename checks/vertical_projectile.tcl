# checks/vertical_projectile.tcl
# Validates Vertical=yes on ProjectileTypes for conflicting properties
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/Vertical
#
# Bugs:
#   1. Vertical + positive ROT: ROT takes precedence, turning the
#      projectile into an ordinary homing projectile instead of vertical.
#   2. Vertical + Arcing: Causes invisible projectile, no damage dealt,
#      and the weapon becomes unable to fire after a few shots.

proc ::Checks::validate_vertical_projectile {} {
    upvar ::Data::projectiles projectiles

    if {![info exists projectiles]} return

    foreach {idx proj_name} [array get projectiles] {
        set vertical [::Checks::get_cached_property $proj_name "Vertical"]
        if {![::Checks::is_true $vertical]} continue

        # Check ROT conflict
        set rot [::Checks::get_cached_property $proj_name "ROT"]
        if {$rot ne "" && $rot > 0} {
            ::Logging::warning "Projectile \"$proj_name\" has Vertical=yes and ROT=$rot. Positive ROT takes precedence over Vertical, turning the projectile into an ordinary homing projectile."
        }

        # Check Arcing conflict
        set arcing [::Checks::get_cached_property $proj_name "Arcing"]
        if {[::Checks::is_true $arcing]} {
            ::Logging::error "Projectile \"$proj_name\" has Vertical=yes and Arcing=yes. This combination causes invisible projectiles, no damage, and the weapon becomes unable to fire after a few shots."
        }
    }
}

# Register this check
::Checks::register_check "validate_vertical_projectile"
