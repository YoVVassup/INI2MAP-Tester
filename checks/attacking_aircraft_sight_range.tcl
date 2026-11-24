# checks/attacking_aircraft_sight_range.tcl
# Validates that [General] AttackingAircraftSightRange is not set to 6 or higher, which causes spawned missiles to reveal the map
# Game modes: RA2/YR
# Uses: ::Checks::get_section_property

proc ::Checks::validate_attacking_aircraft_sight_range {} {
    upvar ::Data::gamemode gamemode

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return

    set val [::Checks::get_section_property "General" "AttackingAircraftSightRange"]
    if {$val eq ""} return

    if {![string is integer -strict $val]} {
        ::Logging::error "\[General\] AttackingAircraftSightRange is not an integer: $val"
        return
    }

    if {$val >= 6} {
        ::Logging::warning "\[General\] AttackingAircraftSightRange = $val (>= 6). This causes spawned missiles (e.g., V3) to reveal the map."
    }
}

# Register this check
::Checks::register_check "validate_attacking_aircraft_sight_range"