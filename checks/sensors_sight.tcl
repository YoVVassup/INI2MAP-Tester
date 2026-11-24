# checks/sensors_sight.tcl
# Validates SensorsSight usage for all TechnoTypes
# Game modes: RA2/YR (vanilla only — bug fixed in Ares 0.5)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/SensorsSight
# Bug: When a unit with SensorsSight is destroyed, a permanently viable
#      sensor area is retained at the point of destruction.
# Fixed in Ares 0.5.
# Note: In vanilla, SensorsSight has no effect on BuildingTypes.

proc ::Checks::validate_sensors_sight {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings
    upvar ::Data::vehicles vehicles
    upvar ::Data::infantry infantry
    upvar ::Data::aircraft aircraft

    # Only check in vanilla modes (bug fixed in Ares)
    set is_ares [expr {$gamemode eq "ares" || $gamemode eq "phobos"}]

    # Process all TechnoType categories
    foreach {category arr_name} {
        Building buildings
        Vehicle vehicles
        Infantry infantry
        Aircraft aircraft
    } {
        if {![info exists $arr_name]} continue

        foreach name [array names $arr_name] {
            set sensors_sight [::Checks::get_cached_property $name "SensorsSight"]

            # Skip if not set or zero
            if {$sensors_sight eq "" || $sensors_sight eq "0"} continue

            # Check for non-numeric value
            if {![string is integer -strict $sensors_sight]} {
                ::Logging::warning "$category \"$name\" has SensorsSight=\"$sensors_sight\" which is not a valid integer."
                continue
            }

            # Warn about the permanent sensor bug in vanilla
            if {!$is_ares} {
                ::Logging::warning "$category \"$name\" has SensorsSight=$sensors_sight. In vanilla RA2/YR, when this unit is destroyed, a permanently viable sensor area is retained at the point of destruction. This bug is exploitable."
            }

            # Warn if BuildingTypes use SensorsSight without SensorArray in vanilla
            if {$category eq "Building" && !$is_ares} {
                set sensor_array [::Checks::get_cached_property $name "SensorArray"]
                if {![::Checks::is_true $sensor_array]} {
                    ::Logging::warning "Building \"$name\" has SensorsSight=$sensors_sight but SensorArray is not set. In vanilla RA2/YR, SensorsSight has no effect on BuildingTypes without SensorArray=yes."
                }
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_sensors_sight"
