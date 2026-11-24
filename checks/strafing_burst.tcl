# checks/strafing_burst.tcl
# Validates Strafing burst behavior for AircraftTypes
# Game modes: RA2/YR/Ares (not Phobos — fixed in Build#12)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Strafing
# Bug: Aircraft with Fighter=no or using strafing pattern will apply
#      weapon's Burst to the first shot only, not all shots.

proc ::Checks::validate_strafing_burst {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::aircraft aircraft

    # Not applicable to Phobos (fixed in Build#12)
    if {$gamemode eq "phobos"} return

    if {![info exists aircraft]} return

    foreach name [array names aircraft] {
        set fighter [::Checks::get_cached_property $name "Fighter"]
        set strafing [::Checks::get_cached_property $name "Strafing"]

        # Only check if aircraft has strafing behavior (Fighter=no or Strafing=yes)
        if {[::Checks::is_true $fighter]} continue
        if {![::Checks::is_true $strafing] && $fighter ne "no"} continue

        # Check if weapon has Burst > 1
        set primary [::Checks::get_cached_property $name "Primary"]
        if {$primary eq "" || $primary eq "none"} continue

        set burst [::Checks::get_cached_property $primary "Burst"]
        if {$burst eq "" || $burst eq "1"} continue

        ::Logging::notice "Aircraft \"$name\" has Fighter=no (or strafing pattern) with weapon \"$primary\" (Burst=$burst). In vanilla RA2/YR/Ares, Burst applies to the first shot only, not all shots."
    }
}

# Register this check
::Checks::register_check "validate_strafing_burst"
