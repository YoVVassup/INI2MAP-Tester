# checks/fire_once_aircraft.tcl
# Validates that AircraftTypes do not use FireOnce=yes, which causes an IE when the aircraft fires
# Game modes: RA2/YR
# Uses: is_true, get_cached_property

proc ::Checks::validate_fire_once_aircraft {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::aircraft aircraft

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return
    if {![info exists aircraft]} return

    foreach type [array names aircraft] {
        set fire_once [::Checks::get_cached_property $type "FireOnce"]
        if {[::Checks::is_true $fire_once]} {
            ::Logging::error "AircraftType \"$type\" has FireOnce=yes. This causes an IE when the aircraft fires."
        }
    }
}

# Register this check
::Checks::register_check "validate_fire_once_aircraft"