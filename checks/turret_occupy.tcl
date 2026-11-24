# checks/turret_occupy.tcl
# Validates that BuildingTypes with CanBeOccupied=yes do not have Turret=yes
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/Turret
#   https://modenc.renegadeprojects.com/CanBeOccupied
#
# Bug:
#   Buildings with CanBeOccupied=yes and Turret=yes cause infantry to be
#   unable to re-enter after leaving. Bio Reactor is not affected by this
#   specific glitch — instead, its owner cannot release infantry inside.

proc ::Checks::validate_turret_occupy {} {
    upvar ::Data::buildings buildings

    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set can_occupy [::Checks::get_cached_property $bldg "CanBeOccupied"]
        if {![::Checks::is_true $can_occupy]} continue

        set turret [::Checks::get_cached_property $bldg "Turret"]
        if {[::Checks::is_true $turret]} {
            ::Logging::warning "BuildingType \"$bldg\" has Turret=yes and CanBeOccupied=yes. Infantry will be unable to re-enter after leaving. This also prevents the building from functioning correctly as an occupiable structure."
        }
    }
}

# Register this check
::Checks::register_check "validate_turret_occupy"
