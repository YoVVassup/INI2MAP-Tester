# checks/insignificant.tcl
# Validates all object types with Insignificant=yes for side effects: ignored BuildLimit, broken Super Weapons, dock issues, and ignored trigger events
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_insignificant {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings
    upvar ::Data::vehicles vehicles
    upvar ::Data::infantry infantry
    upvar ::Data::aircraft aircraft

    set all_types [list]

    if {[info exists infantry]} {
        foreach name [array names infantry] {
            lappend all_types [list "Infantry" $name]
        }
    }
    if {[info exists vehicles]} {
        foreach name [array names vehicles] {
            lappend all_types [list "Vehicle" $name]
        }
    }
    if {[info exists aircraft]} {
        foreach name [array names aircraft] {
            lappend all_types [list "Aircraft" $name]
        }
    }
    if {[info exists buildings]} {
        foreach name [array names buildings] {
            lappend all_types [list "Building" $name]
        }
    }

    foreach {type name} $all_types {
        set insignificant [::Checks::get_cached_property $name "Insignificant"]
        if {![::Checks::is_true $insignificant]} {
            continue
        }

        # BuildLimit is ignored
        set build_limit [::Checks::get_cached_property $name "BuildLimit"]
        if {$build_limit ne "" && [string is integer -strict $build_limit] && $build_limit > 0} {
            ::Logging::warning "$type \"$name\" has Insignificant=yes and BuildLimit=$build_limit. The BuildLimit will be ignored."
        }

        # For buildings: extra side effects (Super Weapons, docks, triggers)
        if {$type eq "Building"} {
            # Check if any Super Weapon is attached to this building
            upvar ::Data::superweapons superweapons
            if {[info exists superweapons]} {
                set sw_found 0
                foreach {idx sw_name} [array get superweapons] {
                    set sw_bldg [::Checks::get_cached_property $sw_name "SW.AuxBuilding"]
                    if {$sw_bldg eq ""} {
                        set sw_bldg [::Checks::get_cached_property $sw_name "AuxBuilding"]
                    }
                    if {$sw_bldg eq $name} {
                        set sw_found 1
                        break
                    }
                }
                if {$sw_found} {
                    ::Logging::warning "Building \"$name\" has Insignificant=yes and is used as AuxBuilding for a Super Weapon. The Super Weapon may fail to fire or fire incorrectly."
                }
            }

            # Check if the building has a dock (DockUnload=yes)
            set dock_unload [::Checks::get_cached_property $name "DockUnload"]
            if {[::Checks::is_true $dock_unload]} {
                ::Logging::warning "Building \"$name\" has Insignificant=yes and DockUnload=yes. Units will not automatically dock on it."
            }
        }

        # Trigger events are ignored (general for all object types)
        # This is informational, as we cannot statically know if the object is used in triggers.
        ::Logging::notice "$type \"$name\" with Insignificant=yes: any trigger event involving this object will be ignored."
    }
}

::Checks::register_check "validate_insignificant"