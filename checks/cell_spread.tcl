# checks/cell_spread.tcl
# Validates CellSpread property on Warheads - checks for non-numeric values and values exceeding 11 that cause internal error on detonation
# Game modes: RA2/YR only (skips Ares/Phobos)
# Uses: ::Checks::get_cached_property

proc ::Checks::validate_cell_spread {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::warheads warheads

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return
    if {![info exists warheads]} return

    foreach {idx warhead_name} [array get warheads] {
        set cell_spread [::Checks::get_cached_property $warhead_name "CellSpread"]
        if {$cell_spread eq ""} continue
        if {![string is double -strict $cell_spread]} {
            ::Logging::error "Warhead \"$warhead_name\" has non-numeric CellSpread: $cell_spread"
            continue
        }
        if {$cell_spread > 11} {
            ::Logging::error "Warhead \"$warhead_name\" has CellSpread=$cell_spread (> 11). This will cause an IE when the warhead detonates."
        }
    }
}

# Register this check
::Checks::register_check "validate_cell_spread"