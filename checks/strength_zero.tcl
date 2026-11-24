# checks/strength_zero.tcl
# Validates Strength value for all TechnoTypes
# Game modes: All (RA2/YR/Ares/Phobos)
# Uses: ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Strength
# Bug: If a unit has Strength=0, it will not join Team and execute Script.
#      If called by the last item in Task Force, triggers EIP#0065D99F.

proc ::Checks::validate_strength_zero {} {
    upvar ::Data::buildings buildings
    upvar ::Data::vehicles vehicles
    upvar ::Data::infantry infantry
    upvar ::Data::aircraft aircraft

    # Process all TechnoType categories
    foreach {category arr_name} {
        Building buildings
        Vehicle vehicles
        Infantry infantry
        Aircraft aircraft
    } {
        if {![info exists $arr_name]} continue

        foreach name [array names $arr_name] {
            set strength [::Checks::get_cached_property $name "Strength"]

            # Skip if not set (default is 0, but we only warn if explicitly set)
            if {$strength eq ""} continue

            # Check for non-numeric value
            if {![string is integer -strict $strength]} {
                ::Logging::warning "$category \"$name\" has Strength=\"$strength\" which is not a valid integer."
                continue
            }

            # Warn if Strength=0
            if {$strength == 0} {
                ::Logging::warning "$category \"$name\" has Strength=0. Units with Strength=0 will not join Team or execute Scripts. If called by the last item in a Task Force, this will trigger EIP crash."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_strength_zero"
