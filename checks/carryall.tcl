# checks/carryall.tcl
# Validates Carryall flag on AircraftTypes - warns about watercraft airlift danger (immediate explosion on land drop) and Ares/Phobos pickup restrictions for Organic/NonVehicle units
# Game modes: RA2/YR/Ares/Phobos (all modes - no gamemode early return)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_carryall {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::aircraft aircraft
    upvar ::Data::vehicles vehicles

    if {![info exists aircraft]} return

    set carryall_aircraft [list]
    foreach type [array names aircraft] {
        set carryall [::Checks::get_cached_property $type "Carryall"]
        if {[::Checks::is_true $carryall]} {
            lappend carryall_aircraft $type
        }
    }
    if {![llength $carryall_aircraft]} return

    if {[info exists vehicles]} {
        set watercraft [list]
        foreach veh [array names vehicles] {
            set movement_zone [::Checks::get_cached_property $veh "MovementZone"]
            if {[string match "*Water*" $movement_zone]} {
                lappend watercraft $veh
            }
        }
        if {[llength $watercraft] > 0} {
            ::Logging::warning "Carryall aircraft ([join $carryall_aircraft ", "]) can airlift watercraft ([join $watercraft ", "]). If dropped on land, watercraft will immediately explode. In Ares, you can set Organic=yes and/or NonVehicle=yes on watercraft to prevent them from being picked up."
        }
    }

    if {$gamemode eq "ares" || $gamemode eq "phobos"} {
        ::Logging::notice "Carryall logic in Ares/Phobos prevents pickup of units with Organic=yes and/or NonVehicle=yes by default. Verify if this affects intended cargo units."
    }
}

# Register this check
::Checks::register_check "validate_carryall"