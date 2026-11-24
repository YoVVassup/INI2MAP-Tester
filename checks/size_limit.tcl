# checks/size_limit.tcl
# Validates SizeLimit usage for VehicleTypes and AircraftTypes
# Game modes: RA2/YR
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/SizeLimit
# Bug 1: Vehicle with Size < SizeLimit of amphibious transport and SizeLimit > 2
#        will crash when ordered to enter (RA2 EIP:0054D10A)
# Bug 2: SizeLimit=999999999 with Passengers=5 and Size=100 units
#        cannot be transported

proc ::Checks::validate_size_limit {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft

    # Only applicable to RA2 and YR
    if {$gamemode ne "ra2" && $gamemode ne "yr"} return

    # Process VehicleTypes and AircraftTypes
    foreach {category arr_name} {
        Vehicle vehicles
        Aircraft aircraft
    } {
        if {![info exists $arr_name]} continue

        foreach name [array names $arr_name] {
            set size_limit [::Checks::get_cached_property $name "SizeLimit"]

            # Skip if not set or zero
            if {$size_limit eq "" || $size_limit eq "0"} continue

            # Check for non-numeric value
            if {![string is integer -strict $size_limit]} {
                ::Logging::warning "$category \"$name\" has SizeLimit=\"$size_limit\" which is not a valid integer."
                continue
            }

            # Check for amphibious transport crash bug
            # If SizeLimit > 2, warn about potential crash with amphibious transports
            if {$size_limit > 2} {
                set speed_type [::Checks::get_cached_property $name "SpeedType"]
                if {$speed_type eq "Amphibious"} {
                    ::Logging::warning "$category \"$name\" has SizeLimit=$size_limit and SpeedType=Amphibious. Giving a vehicle with Size smaller than SizeLimit of an amphibious transport a SizeLimit > 2 will crash when ordered to enter (RA2 EIP)."
                }
            }

            # Check for extreme SizeLimit values
            if {$size_limit > 1000} {
                ::Logging::notice "$category \"$name\" has SizeLimit=$size_limit which is very large. Extreme values may cause transport issues with units having Size=100 or higher."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_size_limit"
