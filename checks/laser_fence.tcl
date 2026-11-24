# checks/laser_fence.tcl
# Validates LaserFence flag on BuildingTypes and warns that it is broken in
#   RA2/YR (never activates even when powered), fixed in Ares/Phobos
# Game modes: RA2/YR
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_laser_fence {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    # LaserFence was introduced in RA2, but is broken in YR 1.001.
    # In Ares/Phobos it's fixed, so we only warn for RA2 and vanilla YR.
    if {$gamemode eq "ares" || $gamemode eq "phobos"} {
        return
    }

    if {![info exists buildings]} {
        return
    }

    foreach bldg [array names buildings] {
        set laser_fence [::Checks::get_cached_property $bldg "LaserFence"]
        if {[::Checks::is_true $laser_fence]} {
            ::Logging::warning "Building \"$bldg\" has LaserFence=yes. In $gamemode, this feature is broken: the laser fence will never turn on, even if the building is powered."
        }
    }
}

::Checks::register_check "validate_laser_fence"