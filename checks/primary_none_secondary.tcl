# checks/primary_none_secondary.tcl
# Validates Primary/Secondary weapon consistency for all TechnoTypes
# Game modes: RA2/YR/Ares/Phobos (all modes)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Secondary
# Bug: If Primary=none, Secondary or EliteSecondary will not be available.

proc ::Checks::validate_primary_none_secondary {} {
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
            set primary [::Checks::get_cached_property $name "Primary"]
            set secondary [::Checks::get_cached_property $name "Secondary"]
            set elite_secondary [::Checks::get_cached_property $name "EliteSecondary"]

            # Skip if no Primary defined or Primary is not "none"
            if {$primary eq "" || $primary ne "none"} continue

            # Warn if Secondary is defined when Primary=none
            if {$secondary ne "" && $secondary ne "none"} {
                ::Logging::warning "$category \"$name\" has Primary=none but Secondary=\"$secondary\". Secondary weapons are unavailable when Primary is none — the Secondary weapon will never fire."
            }

            # Warn if EliteSecondary is defined when Primary=none
            if {$elite_secondary ne "" && $elite_secondary ne "none"} {
                ::Logging::warning "$category \"$name\" has Primary=none but EliteSecondary=\"$elite_secondary\". EliteSecondary weapons are unavailable when Primary is none — the EliteSecondary weapon will never fire."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_primary_none_secondary"
