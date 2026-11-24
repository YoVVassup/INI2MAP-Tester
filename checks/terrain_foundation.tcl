# checks/terrain_foundation.tcl
# Validates TerrainTypes for Foundation=0x0 to prevent map loading crashes (IE).
# Game modes: RA2/YR/Ares/Phobos (all modes; no gamemode check)
# Uses: ::Checks::get_cached_property (indirectly), ::Checks::register_check

proc ::Checks::validate_terrain_foundation {} {
    upvar ::Data::terrains terrains
    upvar ::Data::terrain_foundation terrain_foundation

    if {![info exists terrains]} return

    foreach terrain [array names terrains] {
        if {[info exists terrain_foundation($terrain)]} {
            set foundation $terrain_foundation($terrain)
            if {$foundation eq "0x0"} {
                ::Logging::error "TerrainType \"$terrain\" uses Foundation=0x0. This is known to cause a crash (IE) when loading a map with such terrain placed. Change it to a different foundation (e.g., 1x1)."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_terrain_foundation"