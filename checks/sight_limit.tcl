# checks/sight_limit.tcl
# Validates Sight value for all TechnoTypes
# Game modes: RA2/YR (vanilla only — limit raised in Ares 0.6)
# Uses: ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Sight
# Bug: Sight uses a lookup table like CellSpread, limited to max 10.
#      Setting higher than 10 has same effect as 10.
#      Fixed in Ares 0.6.
# Note: Sight=0 blocks vision entirely.

proc ::Checks::validate_sight_limit {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings
    upvar ::Data::vehicles vehicles
    upvar ::Data::infantry infantry
    upvar ::Data::aircraft aircraft

    # Only check in vanilla modes (limit raised in Ares)
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
            set sight [::Checks::get_cached_property $name "Sight"]

            # Skip if not set
            if {$sight eq ""} continue

            # Check for non-numeric value
            if {![string is integer -strict $sight]} {
                ::Logging::warning "$category \"$name\" has Sight=\"$sight\" which is not a valid integer."
                continue
            }

            # Warn if Sight=0 (blocks vision)
            if {$sight == 0} {
                ::Logging::warning "$category \"$name\" has Sight=0 which blocks vision entirely. The unit will not be able to see anything."
                continue
            }

            # Warn if Sight > 10 in vanilla (limited to 10)
            if {!$is_ares && $sight > 10} {
                ::Logging::notice "$category \"$name\" has Sight=$sight. In vanilla RA2/YR, Sight is limited to 10 (lookup table). Values > 10 have same effect as 10."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_sight_limit"
