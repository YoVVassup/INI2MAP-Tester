# checks/walk_rate_zero.tcl
# Validates that no TechnoType has WalkRate=0
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/WalkRate
#
# Bug:
#   WalkRate=0 causes an Internal Error:
#     RA2: EIP 004C931E
#     YR:  EIP 004DA90E
#   To prevent walk animation, set WalkRate to a very high value instead.

proc ::Checks::validate_walk_rate_zero {} {
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings

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
        set wr [::Checks::get_cached_property $name "WalkRate"]
        if {$wr eq ""} continue

        if {$wr == 0} {
            ::Logging::error "$type_name \"$name\" has WalkRate=0. This causes an Internal Error (EIP 004C931E in RA2, EIP 004DA90E in YR). To prevent walk animation, set WalkRate to a very high value instead."
        }
    }
}

# Register this check
::Checks::register_check "validate_walk_rate_zero"
