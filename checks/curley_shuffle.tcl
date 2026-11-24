# checks/curley_shuffle.tcl
# Validates that CurleyShuffle=yes in [General] does not cause AirportBound=yes aircraft to stack at a single location
# Game modes: RA2/YR/Ares/Phobos
# Uses: is_true, get_section_property, get_cached_property

proc ::Checks::validate_curley_shuffle {} {
    upvar ::Data::aircraft aircraft

    set curley [::Checks::get_section_property "General" "CurleyShuffle"]
    if {![::Checks::is_true $curley]} return

    if {![info exists aircraft]} return

    set affected [list]
    foreach type [array names aircraft] {
        set airport_bound [::Checks::get_cached_property $type "AirportBound"]
        if {$airport_bound eq ""} { set airport_bound yes }
        if {[::Checks::is_true $airport_bound]} {
            lappend affected $type
        }
    }

    if {[llength $affected] > 0} {
        set list [join $affected ", "]
        ::Logging::warning "\[General\] CurleyShuffle=yes affects aircraft with AirportBound=yes: $list. They will only circle targets once and then stack at a single location, instead of maintaining circling attacks."
    }
}

# Register this check
::Checks::register_check "validate_curley_shuffle"