# checks/bunker.tcl
# Validates Bunker flag on BuildingTypes - warns about 1x1 foundation preventing vehicle entry, InfantryAbsorb/UnitAbsorb conflicts, and passenger count limitations
# Game modes: YR/Ares/Phobos (skips RA2)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_bunker {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    if {$gamemode eq "ra2"} return
    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set is_bunker [::Checks::get_cached_property $bldg "Bunker"]
        if {![::Checks::is_true $is_bunker]} continue

        set foundation [::Checks::get_cached_property $bldg "Foundation"]
        if {$foundation eq "1x1"} {
            ::Logging::warning "Building \"$bldg\" has Bunker=yes but Foundation=1x1. Vehicles can approach but cannot actually enter the building."
        }

        set infantry_absorb [::Checks::get_cached_property $bldg "InfantryAbsorb"]
        if {[::Checks::is_true $infantry_absorb]} {
            set unit_absorb [::Checks::get_cached_property $bldg "UnitAbsorb"]
            if {[::Checks::is_true $unit_absorb]} {
                ::Logging::warning "Building \"$bldg\" has Bunker=yes, InfantryAbsorb=yes, and UnitAbsorb=yes. Vehicles will attempt to enter but will never actually enter the building."
            } else {
                ::Logging::warning "Building \"$bldg\" has Bunker=yes and InfantryAbsorb=yes. UnitAbsorb=no (default) will prevent vehicles from entering. If vehicles should enter, set UnitAbsorb=yes, but even then they will only attempt to enter without success."
            }
        }

        set passengers [::Checks::get_cached_property $bldg "Passengers"]
        if {[string is integer -strict $passengers] && $passengers > 0} {
            ::Logging::notice "Building \"$bldg\" has Bunker=yes and Passengers=$passengers. Bunker can only hold one vehicle regardless of Passenger settings."
        }
    }
}

# Register this check
::Checks::register_check "validate_bunker"