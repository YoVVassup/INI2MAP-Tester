# checks/spawner_spawns.tcl
# Validates Spawner weapon + Spawns definition consistency
# Game modes: All (RA2/YR/Ares/Phobos)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Spawner
# Bug: Units using a Spawner weapon must have a valid Spawns= definition,
#      otherwise EIP#006B7D30 will be triggered.

proc ::Checks::validate_spawner_spawns {} {
    upvar ::Data::weapons weapons
    upvar ::Data::buildings buildings
    upvar ::Data::vehicles vehicles
    upvar ::Data::infantry infantry
    upvar ::Data::aircraft aircraft

    if {![info exists weapons]} return

    # Build set of weapons that have Spawner=yes
    set spawner_weapons [dict create]
    foreach {idx name} [array get weapons] {
        if {$name eq ""} continue
        set spawner [::Checks::get_cached_property $name "Spawner"]
        if {[::Checks::is_true $spawner]} {
            dict set spawner_weapons $name 1
        }
    }

    if {[dict size $spawner_weapons] == 0} return

    # TechnoType weapon property names
    set techno_weapon_props {Primary Secondary DeathWeapon ElitePrimary EliteSecondary EliteDeathWeapon OccupyWeapon EliteOccupyWeapon WeaponType}

    # Check all TechnoTypes for Spawner weapons without Spawns=
    foreach {category arr_name} {
        Building buildings
        Vehicle vehicles
        Infantry infantry
        Aircraft aircraft
    } {
        if {![info exists $arr_name]} continue

        foreach name [array names $arr_name] {
            # Check all weapon properties
            foreach prop $techno_weapon_props {
                set weap [::Checks::get_cached_property $name $prop]
                if {$weap eq "" || $weap eq "none"} continue

                if {[dict exists $spawner_weapons $weap]} {
                    # Check if this unit has Spawns= defined
                    set spawns [::Checks::get_cached_property $name "Spawns"]
                    if {$spawns eq "" || $spawns eq "none"} {
                        ::Logging::error "$category \"$name\" uses Spawner weapon \"$weap\" but has no Spawns= definition. This will cause EIP crash."
                    }
                }
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_spawner_spawns"
