# checks/spray_attack.tcl
# Validates SprayAttack usage for all TechnoTypes
# Game modes: YR/Ares/Phobos (not RA2)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/SprayAttack
# Bugs:
#   1. Weapons don't support IsSonic effects
#   2. When enabled on Parasite units, it permanently prevents
#      successful parasitism (units get ejected immediately)

proc ::Checks::validate_spray_attack {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings
    upvar ::Data::vehicles vehicles
    upvar ::Data::infantry infantry
    upvar ::Data::aircraft aircraft

    # Only applicable to YR and later (not RA2)
    if {$gamemode eq "ra2"} return

    # Process all TechnoType categories
    foreach {category arr_name} {
        Building buildings
        Vehicle vehicles
        Infantry infantry
        Aircraft aircraft
    } {
        if {![info exists $arr_name]} continue

        foreach name [array names $arr_name] {
            set spray [::Checks::get_cached_property $name "SprayAttack"]
            if {![::Checks::is_true $spray]} continue

            # Check if Parasite=yes (causes parasitism to fail)
            set parasite [::Checks::get_cached_property $name "Parasite"]
            if {[::Checks::is_true $parasite]} {
                ::Logging::warning "$category \"$name\" has SprayAttack=yes and Parasite=yes. SprayAttack permanently prevents successful parasitism — units get ejected immediately upon projectile impact and are forcibly deselected."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_spray_attack"
