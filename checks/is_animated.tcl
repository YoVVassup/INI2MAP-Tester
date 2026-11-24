# checks/is_animated.tcl
# Validates TerrainTypes with IsAnimated=yes for missing SpawnsTiberium=yes, which causes non-looping animation and invisible terrain
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_is_animated {} {
    upvar ::Data::terrains terrains

    if {![info exists terrains]} {
        return
    }

    foreach terrain [array names terrains] {
        set is_animated [::Checks::get_cached_property $terrain "IsAnimated"]
        if {![::Checks::is_true $is_animated]} {
            continue
        }

        set spawns_tiberium [::Checks::get_cached_property $terrain "SpawnsTiberium"]
        if {![::Checks::is_true $spawns_tiberium]} {
            ::Logging::warning "TerrainType \"$terrain\" has IsAnimated=yes but SpawnsTiberium=yes is not set. The animation will not loop, and the terrain object will become invisible after the animation completes."
        }
    }
}

::Checks::register_check "validate_is_animated"