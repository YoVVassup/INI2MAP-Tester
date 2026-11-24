# checks/warpable_temporal.tcl
# Validates Warpable=no usage on TechnoTypes in RA2/YR
# Game modes: RA2/YR only (fixed in Ares 0.1)
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/Warpable
#
# Bug (fixed in Ares 0.1):
#   Attacking a unit with Temporal=yes warhead when it has Warpable=no
#   can still cause negative effects:
#   - Mind-controlled units by the unwarpable unit are freed
#   - Aircraft-spawners have those aircraft destroyed
#   Unwarpable units are no longer affected in Ares 0.1+.

proc ::Checks::validate_warpable_temporal {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings

    # Bug only in RA2/YR, fixed in Ares 0.1
    if {$gamemode eq "ares" || $gamemode eq "phobos"} return

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
        set warpable [::Checks::get_cached_property $name "Warpable"]
        if {[string tolower $warpable] ne "no"} continue

        ::Logging::warning "$type_name \"$name\" has Warpable=no. In RA2/YR, Temporal=yes warheads can still affect this unit: mind-controlled units will be freed and aircraft-spawners will lose their aircraft. Fixed in Ares 0.1."
    }
}

# Register this check
::Checks::register_check "validate_warpable_temporal"
