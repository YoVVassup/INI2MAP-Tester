# checks/missile_spawn.tcl
# Validates MissileSpawn flag usage to prevent fatal errors in Phobos engine
# Game modes: Phobos only
# Uses: ::Checks::is_true, ::Checks::get_cached_property
# Applicable to: AircraftTypes, BuildingTypes, InfantryTypes, VehicleTypes.

proc ::Checks::_ms_check {type_name name} {
    set ms [::Checks::get_cached_property $name "MissileSpawn"]
    if {[::Checks::is_true $ms]} {
        ::Logging::warning "$type_name \"$name\" has MissileSpawn=yes. In Phobos, this can cause a fatal error when firing."
    }
}

proc ::Checks::validate_missile_spawn {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles

    if {$gamemode ne "phobos"} {
        return
    }

    if {[info exists aircraft]} {
        foreach name [array names aircraft] { ::Checks::_ms_check "AircraftType" $name }
    }
    if {[info exists buildings]} {
        foreach name [array names buildings] { ::Checks::_ms_check "BuildingType" $name }
    }
    if {[info exists infantry]} {
        foreach name [array names infantry] { ::Checks::_ms_check "InfantryType" $name }
    }
    if {[info exists vehicles]} {
        foreach name [array names vehicles] { ::Checks::_ms_check "VehicleType" $name }
    }
}

::Checks::register_check "validate_missile_spawn"