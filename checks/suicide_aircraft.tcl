# checks/suicide_aircraft.tcl
# Validates Suicide flag in TeamTypes with AircraftTypes
# Game modes: RA2/YR (vanilla only — fixed in Ares 3.0)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Suicide
# Bug: If AircraftType destroys itself using Suicide=yes in TeamTypes,
#      it will trigger EIP#00417D05. Fixed in Ares 3.0.

proc ::Checks::validate_suicide_aircraft {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::teamtypes teamtypes
    upvar ::Data::aircraft aircraft

    # Only check in vanilla modes (fixed in Ares)
    set is_ares [expr {$gamemode eq "ares" || $gamemode eq "phobos"}]
    if {$is_ares} return

    if {![info exists teamtypes]} return
    if {![info exists aircraft]} return

    foreach name [array names teamtypes] {
        set suicide [::Checks::get_cached_property $name "Suicide"]
        if {![::Checks::is_true $suicide]} continue

        # Check if this team contains aircraft
        # TeamTypes reference units via TaskForces, but we can check the team's own properties
        # For simplicity, warn about any TeamType with Suicide=yes in vanilla
        ::Logging::warning "TeamType \"$name\" has Suicide=yes. In vanilla RA2/YR, if an AircraftType destroys itself using Suicide=yes, it will trigger EIP crash."
    }
}

# Register this check
::Checks::register_check "validate_suicide_aircraft"
