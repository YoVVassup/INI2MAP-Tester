# checks/is_gattling.tcl
# Validates InfantryTypes, VehicleTypes, and BuildingTypes with IsGattling=yes for platform support limits, deployer state bugs, targeting issues, and Bunker interaction bugs
# Game modes: YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_is_gattling {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::buildings buildings

    # IsGattling is not supported in RA2
    if {$gamemode eq "ra2"} {
        return
    }

    set is_phobos [expr {$gamemode eq "phobos"}]

    # ----- InfantryTypes (Phobos only) -----
    if {[info exists infantry]} {
        foreach inf [array names infantry] {
            set is_gattling [::Checks::get_cached_property $inf "IsGattling"]
            if {![::Checks::is_true $is_gattling]} continue

            if {!$is_phobos} {
                ::Logging::warning "InfantryType \"$inf\" has IsGattling=yes but this flag is only supported in Phobos Build 48+. In $gamemode, it will be ignored."
            }
            # In Phobos, no warning (it works)
        }
    }

    # ----- VehicleTypes (YR/Ares/Phobos) -----
    if {[info exists vehicles]} {
        foreach veh [array names vehicles] {
            set is_gattling [::Checks::get_cached_property $veh "IsGattling"]
            if {![::Checks::is_true $is_gattling]} continue

            # Simple deployer state (Deployer=yes)
            set deployer [::Checks::get_cached_property $veh "Deployer"]
            if {[::Checks::is_true $deployer] && !$is_phobos} {
                ::Logging::warning "Vehicle \"$veh\" has IsGattling=yes and Deployer=yes. In simple deployer state it will only use EliteWeapon2."
            }

            # NavalTargeting / LandTargeting ignored
            set naval_targeting [::Checks::get_cached_property $veh "NavalTargeting"]
            set land_targeting [::Checks::get_cached_property $veh "LandTargeting"]
            if {($naval_targeting ne "" || $land_targeting ne "") && !$is_phobos} {
                ::Logging::warning "Vehicle \"$veh\" has IsGattling=yes and NavalTargeting/LandTargeting set. These will not affect weapon selection."
            }
        }
    }

    # ----- BuildingTypes (YR/Ares/Phobos) with Bunker=yes -----
    if {[info exists buildings]} {
        foreach bldg [array names buildings] {
            set is_gattling [::Checks::get_cached_property $bldg "IsGattling"]
            if {![::Checks::is_true $is_gattling]} continue

            set bunker [::Checks::get_cached_property $bldg "Bunker"]
            if {[::Checks::is_true $bunker]} {
                # This bug exists in all modes (including Phobos? Documentation doesn't mention fix)
                ::Logging::warning "Building \"$bldg\" has IsGattling=yes and Bunker=yes. After a vehicle enters and leaves, the building will no longer be able to fire, and if it was firing, the sound will loop indefinitely."
            }
        }
    }
}

::Checks::register_check "validate_is_gattling"