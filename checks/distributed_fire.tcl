# checks/distributed_fire.tcl
# Validates that DistributedFire=yes and FireOnce=yes redundancy is flagged on BuildingTypes
# Game modes: RA2/YR/Ares/Phobos
# Uses: is_true, get_cached_property

proc ::Checks::validate_distributed_fire {} {
    upvar ::Data::buildings buildings

    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set dist_fire [::Checks::get_cached_property $bldg "DistributedFire"]
        if {![::Checks::is_true $dist_fire]} continue

        set fire_once [::Checks::get_cached_property $bldg "FireOnce"]
        if {[::Checks::is_true $fire_once]} {
            ::Logging::notice "Building \"$bldg\" has both DistributedFire=yes and FireOnce=yes. DistributedFire already causes the building to attack only once; FireOnce is redundant."
        } else {
            ::Logging::warning "Building \"$bldg\" has DistributedFire=yes. This causes the building to attack only once (like FireOnce=yes), even if FireOnce is not set."
        }
    }
}

# Register this check
::Checks::register_check "validate_distributed_fire"