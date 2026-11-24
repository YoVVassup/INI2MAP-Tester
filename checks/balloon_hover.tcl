# checks/balloon_hover.tcl
# Validates BalloonHover flag - warns about incompatible dock/repair/helipad interactions, aircraft crash scenarios, infantry transport issues, and Jumpjet factory ExitCoord conflicts
# Game modes: RA2/YR/Ares/Phobos (all modes - no gamemode check)
# Uses: ::Checks::is_true, ::Checks::get_cached_property, ::Checks::get_all_techno_types

# Building lists are identical for every BalloonHover type - build them
# once per run instead of scanning all buildings per type.
proc ::Checks::_bh_building_lists {} {
    variable bh_lists_ready
    variable bh_dock
    variable bh_repair
    variable bh_heli
    if {$bh_lists_ready} return
    set bh_dock {}
    set bh_repair {}
    set bh_heli {}
    if {[info exists ::Data::buildings]} {
        foreach bldg [array names ::Data::buildings] {
            if {[::Checks::is_true [::Checks::get_cached_property $bldg "DockUnload"]]} {
                lappend bh_dock $bldg
            }
            if {[::Checks::is_true [::Checks::get_cached_property $bldg "UnitRepair"]]} {
                lappend bh_repair $bldg
            }
            if {[::Checks::is_true [::Checks::get_cached_property $bldg "Helipad"]]} {
                lappend bh_heli $bldg
            }
        }
    }
    set bh_lists_ready 1
}

proc ::Checks::validate_balloon_hover {} {
    upvar ::Data::buildings buildings
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft
    upvar ::Data::infantry infantry
    variable bh_dock
    variable bh_repair
    variable bh_heli
    set all_types [::Checks::get_all_techno_types]

    foreach type $all_types {
        set balloon_hover [::Checks::get_cached_property $type "BalloonHover"]
        if {![::Checks::is_true $balloon_hover]} continue

        if {[info exists vehicles($type)] || [info exists aircraft($type)]} {
            ::Checks::_bh_building_lists
            if {[llength $bh_dock] > 0} {
                ::Logging::notice "Type \"$type\" (BalloonHover=yes) cannot dock at buildings with DockUnload=yes: [join $bh_dock ", "]."
            }
            if {[llength $bh_repair] > 0} {
                ::Logging::notice "Type \"$type\" (BalloonHover=yes) cannot be repaired at buildings with UnitRepair=yes: [join $bh_repair ", "]."
            }
            if {[llength $bh_heli] > 0} {
                ::Logging::notice "Type \"$type\" (BalloonHover=yes) cannot land on helipads: [join $bh_heli ", "]."
            }
        }

        if {[info exists aircraft($type)]} {
            set airport_bound [::Checks::get_cached_property $type "AirportBound"]
            if {[::Checks::is_true $airport_bound]} {
                ::Logging::warning "AircraftType \"$type\" has BalloonHover=yes and AirportBound=yes. It will crash after completing/aborting tasks as if no helipad is available."
            }
        }

        if {[info exists infantry($type)]} {
            ::Logging::notice "Infantry type \"$type\" with BalloonHover=yes cannot enter transport units (cursor shows NoEnter style)."
        }

        if {[info exists vehicles($type)] || [info exists aircraft($type)]} {
            set locomotor [::Checks::get_cached_property $type "Locomotor"]
            if {[string match "*{92612C46-F71F-11d1-AC9F-006008055BB5}*" $locomotor]} {
                set jumpjet_height [::Checks::get_cached_property $type "JumpjetHeight"]
                if {[string is integer -strict $jumpjet_height] && $jumpjet_height > 0} {
                    ::Logging::notice "Type \"$type\" (BalloonHover=yes, Jumpjet) must be produced from a factory with ExitCoord lower than its JumpjetHeight ($jumpjet_height) or it will get stuck."
                } else {
                    ::Logging::notice "Type \"$type\" has BalloonHover=yes and Locomotor=Jumpjet. Ensure its factory ExitCoord is lower than JumpjetHeight (if set)."
                }
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_balloon_hover"