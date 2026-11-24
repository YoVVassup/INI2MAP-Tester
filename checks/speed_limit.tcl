# checks/speed_limit.tcl
# Validates Speed value for InfantryTypes, VehicleTypes, AircraftTypes
# Game modes: All (RA2/YR/Ares/Phobos)
# Uses: ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Speed
# Bug 1: Infantry with Speed >= 14 will move erratically (Walk locomotor limit)
# Bug 2: Speed=0 causes units to enter move mission and get stuck

proc ::Checks::validate_speed_limit {} {
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft

    # Check InfantryTypes
    if {[info exists infantry]} {
        foreach name [array names infantry] {
            set speed [::Checks::get_cached_property $name "Speed"]

            # Skip if not set
            if {$speed eq ""} continue

            # Check for non-numeric value
            if {![string is integer -strict $speed]} {
                ::Logging::warning "Infantry \"$name\" has Speed=\"$speed\" which is not a valid integer."
                continue
            }

            # Warn if Speed=0 (stuck in move mission)
            if {$speed == 0} {
                ::Logging::warning "Infantry \"$name\" has Speed=0 which causes units to enter a move mission and get stuck."
                continue
            }

            # Warn if Speed >= 14 (erratic movement)
            if {$speed >= 14} {
                ::Logging::notice "Infantry \"$name\" has Speed=$speed. Infantry with Speed >= 14 will move erratically due to Walk locomotor limitations."
            }
        }
    }

    # Check VehicleTypes and AircraftTypes for Speed=0
    foreach {category arr_name} {
        Vehicle vehicles
        Aircraft aircraft
    } {
        if {![info exists $arr_name]} continue

        foreach name [array names $arr_name] {
            set speed [::Checks::get_cached_property $name "Speed"]

            # Skip if not set
            if {$speed eq ""} continue

            # Check for non-numeric value
            if {![string is integer -strict $speed]} {
                ::Logging::warning "$category \"$name\" has Speed=\"$speed\" which is not a valid integer."
                continue
            }

            # Warn if Speed=0 (stuck in move mission)
            if {$speed == 0} {
                ::Logging::warning "$category \"$name\" has Speed=0 which causes units to enter a move mission and get stuck."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_speed_limit"
