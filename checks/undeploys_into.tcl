# checks/undeploys_into.tcl
# Validates UndeploysInto usage for potential bugs
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/UndeploysInto
#
# Bugs:
#   1. Health floor: DeploysInto/UndeploysInto floor health during
#      execution. Repeated deploy/undeploy cycles cause continuous
#      health loss until HP reaches 1. Fixed in Phobos Build#49.
#   2. WaterBound conflict: If the source building has WaterBound=yes,
#      the undeployed vehicle cannot set correct movement targets
#      because the game only checks "not none" for SpeedType/MovementZone.

proc ::Checks::validate_undeploys_into {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings

    set is_phobos [expr {$gamemode eq "phobos"}]

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
        set undeploys [::Checks::get_cached_property $name "UndeploysInto"]
        if {$undeploys eq "" || [string tolower $undeploys] eq "none"} continue

        # Check if target type exists
        set target_exists 0
        foreach arr_name {infantry vehicles aircraft buildings} {
            if {[info exists $arr_name] && [info exists ${arr_name}($undeploys)]} {
                set target_exists 1
                break
            }
        }
        if {!$target_exists} {
            ::Logging::warning "$type_name \"$name\" has UndeploysInto=\"$undeploys\" but the target type does not exist."
            continue
        }

        # Health floor bug (fixed in Phobos)
        if {!$is_phobos} {
            ::Logging::notice "$type_name \"$name\" has UndeploysInto=\"$undeploys\". Repeated deploy/undeploy cycles will cause health to floor at 1 HP."
        }

        # WaterBound conflict
        if {$type_name eq "BuildingType"} {
            set water_bound [::Checks::get_cached_property $name "WaterBound"]
            if {[::Checks::is_true $water_bound]} {
                ::Logging::warning "$type_name \"$name\" has UndeploysInto=\"$undeploys\" and WaterBound=yes. The undeployed vehicle may fail to set correct movement targets."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_undeploys_into"
