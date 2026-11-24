# checks/gap_radius_in_cells.tcl
# Validates that GapRadiusInCells values on BuildingTypes do not exceed 127, which disables shroud generation
# Game modes: RA2/YR
# Uses: get_cached_property

proc ::Checks::validate_gap_radius_in_cells {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return
    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set gap_radius [::Checks::get_cached_property $bldg "GapRadiusInCells"]
        if {$gap_radius eq ""} continue

        if {[string is integer -strict $gap_radius] && $gap_radius > 127} {
            ::Logging::warning "Building \"$bldg\" has GapRadiusInCells=$gap_radius (> 127). Values above 127 cause no shroud to be generated at all."
        }
    }
}

# Register this check
::Checks::register_check "validate_gap_radius_in_cells"