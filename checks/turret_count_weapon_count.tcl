# checks/turret_count_weapon_count.tcl
# Validates that TurretCount > 0 types have WeaponCount set correctly
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/TurretCount
#   https://modenc.renegadeprojects.com/WeaponCount
#
# Bugs:
#   When TurretCount is set to a value greater than 0, WeaponCount must
#   also be set correctly. WeaponCount is not initialized to a constant
#   value — garbage in memory can lead to desyncs, crashes during
#   loading, or appear to be working. If TurretCount > 0, set this value.

proc ::Checks::validate_turret_count_weapon_count {} {
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings

    set all_types [list]
    if {[info exists infantry]} {
        foreach n [array names infantry] { lappend all_types "InfantryType" $n }
    }
    if {[info exists vehicles]} {
        foreach n [array names vehicles] { lappend all_types "VehicleType" $n }
    }
    if {[info exists aircraft]} {
        foreach n [array names aircraft] { lappend all_types "AircraftType" $n }
    }
    if {[info exists buildings]} {
        foreach n [array names buildings] { lappend all_types "BuildingType" $n }
    }

    foreach {type_name name} $all_types {
        set tc [::Checks::get_cached_property $name "TurretCount"]
        if {$tc eq "" || $tc == 0} continue

        set wc [::Checks::get_cached_property $name "WeaponCount"]
        if {$wc eq ""} {
            ::Logging::error "$type_name \"$name\" has TurretCount=$tc but WeaponCount is not set. WeaponCount is not initialized by the engine - uninitialized memory may cause crashes, desyncs, or corruption."
        } elseif {$wc < $tc} {
            ::Logging::warning "$type_name \"$name\" has TurretCount=$tc but WeaponCount=$wc. WeaponCount should be >= TurretCount to avoid uninitialized weapon slots."
        }
    }
}

# Register this check
::Checks::register_check "validate_turret_count_weapon_count"
