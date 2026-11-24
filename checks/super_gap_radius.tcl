# checks/super_gap_radius.tcl
# Validates SuperGapRadiusInCells value in BuildingTypes
# Game modes: RA2/YR (vanilla only — fixed in Ares 3.0)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/SuperGapRadiusInCells
# Bug: Values over 127 result in no shroud being generated at all.
#      Fixed in Ares 3.0.

proc ::Checks::validate_super_gap_radius {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    # Only check in vanilla modes (fixed in Ares)
    set is_ares [expr {$gamemode eq "ares" || $gamemode eq "phobos"}]
    if {$is_ares} return

    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set val [::Checks::get_cached_property $bldg "SuperGapRadiusInCells"]

        # Skip if not set or zero
        if {$val eq "" || $val eq "0"} continue

        # Check for non-numeric value
        if {![string is integer -strict $val]} {
            ::Logging::warning "Building \"$bldg\" has SuperGapRadiusInCells=\"$val\" which is not a valid integer."
            continue
        }

        # Warn if value > 127
        if {$val > 127} {
            ::Logging::warning "Building \"$bldg\" has SuperGapRadiusInCells=$val. Values over 127 result in no shroud being generated at all in vanilla RA2/YR."
        }
    }
}

# Register this check
::Checks::register_check "validate_super_gap_radius"
