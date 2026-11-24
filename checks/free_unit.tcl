# checks/free_unit.tcl
# Validates FreeUnit references and cost relationships for BuildingTypes, including UnitsCostBonus impact
# Game modes: RA2/YR/Ares/Phobos
# Uses: is_true, get_cached_property

proc ::Checks::validate_free_unit {} {
    upvar ::Data::buildings buildings
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft

    if {![info exists buildings]} return

    set critical_bonus_buildings [list]
    set low_bonus_buildings [list]
    foreach bldg [array names buildings] {
        set bonus [::Checks::get_cached_property $bldg "UnitsCostBonus"]
        if {$bonus eq ""} continue
        if {![string is double -strict $bonus]} continue
        if {$bonus <= 0.01} {
            lappend critical_bonus_buildings $bldg
        } elseif {$bonus <= 0.05} {
            lappend low_bonus_buildings $bldg
        }
    }

    if {[llength $critical_bonus_buildings] > 0} {
        set list [join $critical_bonus_buildings ", "]
        ::Logging::warning "Building(s) with UnitsCostBonus <= 0.01: $list. This completely disables FreeUnit for ALL buildings."
    }

    foreach bldg [array names buildings] {
        set free_unit [::Checks::get_cached_property $bldg "FreeUnit"]
        if {$free_unit eq ""} continue

        set bldg_cost [::Checks::get_cached_property $bldg "Cost"]
        if {![string is integer -strict $bldg_cost]} { set bldg_cost 0 }

        set free_cost ""
        if {[info exists infantry] && [info exists infantry($free_unit)]} {
            set free_cost [::Checks::get_cached_property $free_unit "Cost"]
        } elseif {[info exists vehicles] && [info exists vehicles($free_unit)]} {
            set free_cost [::Checks::get_cached_property $free_unit "Cost"]
        } elseif {[info exists aircraft] && [info exists aircraft($free_unit)]} {
            set free_cost [::Checks::get_cached_property $free_unit "Cost"]
        } else {
            ::Logging::warning "Building \"$bldg\" has FreeUnit=\"$free_unit\" which is not a recognized InfantryType/VehicleType/AircraftType."
            continue
        }

        if {![string is integer -strict $free_cost]} { set free_cost 0 }
        if {$free_cost > $bldg_cost} {
            ::Logging::warning "Building \"$bldg\" (Cost=$bldg_cost) has FreeUnit \"$free_unit\" with Cost=$free_cost. The displayed build cost will be overridden to $free_cost (construction speed unchanged)."
        }
    }
}

# Register this check
::Checks::register_check "validate_free_unit"