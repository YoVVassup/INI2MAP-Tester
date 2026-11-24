# checks/pad_aircraft.tcl
# Validates PadAircraft entries in [General] section have valid Dock buildings
# Game modes: RA2/YR/Ares/Phobos (all)
# Uses: ::Checks::is_true, ::Checks::get_cached_property, ::Checks::get_section_property
# building and that the building exists. Warns about missing Dock or non-existent
# buildings to prevent EIP#0045ED61.
# Uses ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_pad_aircraft {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings

    if {![info exists aircraft] || ![info exists buildings]} {
        return
    }

    set pad_aircraft_str [::Checks::get_section_property "General" "PadAircraft"]
    if {$pad_aircraft_str eq ""} {
        return
    }

    set pad_aircraft_list [split $pad_aircraft_str ","]
    set trimmed_list {}
    foreach item $pad_aircraft_list {
        lappend trimmed_list [string trim $item]
    }
    set pad_aircraft_list $trimmed_list

    foreach aircraft_name $pad_aircraft_list {
        if {![info exists aircraft($aircraft_name)]} {
            ::Logging::warning "AircraftType \"$aircraft_name\" is listed in \[General\] PadAircraft but is not defined. This will cause an IE upon game start."
            continue
        }

        set dock_buildings_str [::Checks::get_cached_property $aircraft_name "Dock"]
        if {$dock_buildings_str eq ""} {
            ::Logging::warning "AircraftType \"$aircraft_name\" is listed in PadAircraft but has no Dock= value. This will cause EIP."
            continue
        }

        set dock_buildings_list [split $dock_buildings_str ","]
        set valid_dock_found 0
        foreach dock_item $dock_buildings_list {
            set dock_bldg [string trim $dock_item]
            if {$dock_bldg eq "<none>" || $dock_bldg eq ""} {
                continue
            }
            if {[info exists buildings($dock_bldg)]} {
                set valid_dock_found 1
                break
            }
        }

        if {!$valid_dock_found} {
            ::Logging::warning "AircraftType \"$aircraft_name\" is listed in PadAircraft but its Dock=($dock_buildings_str) does not point to a valid BuildingType. This will cause EIP."
        }
    }
}

::Checks::register_check "validate_pad_aircraft"