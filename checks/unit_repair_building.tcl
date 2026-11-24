# checks/unit_repair_building.tcl
# Validates UnitRepair=yes on BuildingTypes for known bugs
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/UnitRepair
#
# Bugs:
#   1. AI sends damaged units to the closest UnitRepair building even if
#      the unit can't enter. If the building is an airpad, infinite loop
#      and crash.
#   2. Aircraft that can land will trigger repair loop after landing and
#      get kicked off once fully repaired — preventing proper docking.
#   3. BalloonHover vehicles with Vertical projectiles won't approach
#      targets beyond weapon range.

proc ::Checks::validate_unit_repair_building {} {
    upvar ::Data::buildings buildings

    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set repair [::Checks::get_cached_property $bldg "UnitRepair"]
        if {![::Checks::is_true $repair]} continue

        # Check for aircraft-related buildings (Dock may indicate airpad)
        set dock [::Checks::get_cached_property $bldg "Dock"]
        set fighter [::Checks::get_cached_property $bldg "Fighter"]
        set airport [::Checks::get_cached_property $bldg "AirportBound"]

        if {[::Checks::is_true $dock] || [::Checks::is_true $fighter] || [::Checks::is_true $airport]} {
            ::Logging::warning "BuildingType \"$bldg\" has UnitRepair=yes and appears to be an aircraft docking structure (Dock/Fighter/AirportBound=yes). This will cause an infinite loop crash when AI units try to repair there. Aircraft will also be kicked off after repair, preventing proper docking."
        } else {
            ::Logging::notice "BuildingType \"$bldg\" has UnitRepair=yes. AI will send damaged units here regardless of whether they can enter, potentially causing pathfinding issues. Aircraft docking may also be disrupted by the repair loop."
        }
    }
}

# Register this check
::Checks::register_check "validate_unit_repair_building"
