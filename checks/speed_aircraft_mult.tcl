# checks/speed_aircraft_mult.tcl
# Validates SpeedAircraftMult in [Countries]
# Game modes: All except Phobos
# Uses: ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/SpeedAircraftMult
# Bug: AircraftType cannot benefit from most speed boost bonus effects,
#      this flag is effectively invalid. Fixed in Phobos Build 28.

proc ::Checks::validate_speed_aircraft_mult {} {
    upvar ::Data::gamemode gamemode

    # Not applicable to Phobos (fixed there)
    if {$gamemode eq "phobos"} return

    # Get the value from [Countries]
    set val [::Checks::get_cached_property "Countries" "SpeedAircraftMult"]
    if {$val eq ""} return

    # Only warn if not default (1.0)
    if {$val eq "1.0" || $val eq "1" || $val eq "100%"} return

    ::Logging::warning "SpeedAircraftMult=$val in \[Countries\] is effectively invalid in vanilla RA2/YR. AircraftType cannot benefit from most speed boost bonus effects."
}

# Register this check
::Checks::register_check "validate_speed_aircraft_mult"
