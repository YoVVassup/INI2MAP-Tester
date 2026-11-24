# checks/weapons_factory_building.tcl
# Validates WeaponsFactory=yes combinations on BuildingTypes
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/WeaponsFactory
#
# Bugs:
#   1. WeaponsFactory=yes + DockUnload=yes: Harvesters can't unload,
#      stuck in Enter mission at dock position.
#   2. WeaponsFactory=yes + Hospital/Armory=yes: Infantry can't be
#      released after entering.
#   3. WeaponsFactory=yes + Factory=InfantryType: Cloning disabled
#      (fixed in Ares 0.2). Infantry spawns at cell #10 of 5x3
#      buildings instead of rally point.
#   4. WeaponsFactory=yes + UnitRepair=yes: Damage transfers to building,
#      special effects invalidated (fixed in Ares 0.6).

proc ::Checks::validate_weapons_factory_building {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    if {![info exists buildings]} return

    set is_ares_new [expr {$gamemode eq "ares" || $gamemode eq "phobos"}]

    foreach bldg [array names buildings] {
        set wf [::Checks::get_cached_property $bldg "WeaponsFactory"]
        if {![::Checks::is_true $wf]} continue

        # DockUnload conflict
        set dock_unload [::Checks::get_cached_property $bldg "DockUnload"]
        if {[::Checks::is_true $dock_unload]} {
            ::Logging::warning "BuildingType \"$bldg\" has WeaponsFactory=yes and DockUnload=yes. Harvesters will be unable to complete unload when docking and will remain stuck in the Enter mission state."
        }

        # Hospital/Armory conflict
        set hospital [::Checks::get_cached_property $bldg "Hospital"]
        set armory [::Checks::get_cached_property $bldg "Armory"]
        if {[::Checks::is_true $hospital] || [::Checks::is_true $armory]} {
            ::Logging::warning "BuildingType \"$bldg\" has WeaponsFactory=yes and Hospital/Armory=yes. Infantry will be unable to be released after entering the building."
        }

        # Factory=InfantryType conflict (cloning + spawn position, fixed in Ares 0.2)
        if {!$is_ares_new} {
            set factory [::Checks::get_cached_property $bldg "Factory"]
            if {$factory eq "InfantryType"} {
                ::Logging::warning "BuildingType \"$bldg\" has WeaponsFactory=yes and Factory=InfantryType. Cloning (Cloning=yes) will not trigger, and infantry will spawn at cell #10 of 5x3 buildings instead of the rally point."
            }
        }

        # UnitRepair conflict (fixed in Ares 0.6)
        if {!$is_ares_new} {
            set repair [::Checks::get_cached_property $bldg "UnitRepair"]
            if {[::Checks::is_true $repair]} {
                ::Logging::warning "BuildingType \"$bldg\" has WeaponsFactory=yes and UnitRepair=yes. Damage will transfer to the building and special effects (IsLocomotor, Temporal, IronCurtain) will be invalidated."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_weapons_factory_building"
