# checks/slowdown_distance.tcl
# Validates SlowdownDistance usage for InfantryTypes, VehicleTypes, AircraftTypes
# Game modes: All (RA2/YR/Ares/Phobos)
# Uses: ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/SlowdownDistance
# Bug: SlowdownDistance=0 causes Move action to never complete.
#      Unit will not land after approaching destination.
#      May cause distance issues with [General]→Stray=.
#      Teams will be unable to execute next script.

proc ::Checks::validate_slowdown_distance {} {
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft

    # Process all applicable TechnoType categories
    foreach {category arr_name} {
        Infantry infantry
        Vehicle vehicles
        Aircraft aircraft
    } {
        if {![info exists $arr_name]} continue

        foreach name [array names $arr_name] {
            set val [::Checks::get_cached_property $name "SlowdownDistance"]

            # Skip if not set
            if {$val eq ""} continue

            # Check for non-numeric value
            if {![string is integer -strict $val]} {
                ::Logging::warning "$category \"$name\" has SlowdownDistance=\"$val\" which is not a valid integer."
                continue
            }

            # Warn if SlowdownDistance=0 (causes move to never complete)
            if {$val == 0} {
                ::Logging::warning "$category \"$name\" has SlowdownDistance=0. This causes the Move action to never complete — the unit will not land after approaching the destination. Distance to target cannot be less than \[General\]→Stray= value. If this unit is in a task force, the team will be unable to execute the next script."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_slowdown_distance"
