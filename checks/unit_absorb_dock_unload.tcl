# checks/unit_absorb_dock_unload.tcl
# Validates that UnitAbsorb=yes buildings do not also have DockUnload=yes
# Game modes: YR/Ares/Phobos (not RA2)
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/UnitAbsorb
#
# Bug:
#   If UnitAbsorb=yes is applied to a building with DockUnload=yes,
#   units will be unable to perform their original behaviors while
#   docked. For example, ore trucks will fail to complete ore unloading.

proc ::Checks::validate_unit_absorb_dock_unload {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    if {$gamemode eq "ra2"} return
    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set absorb [::Checks::get_cached_property $bldg "UnitAbsorb"]
        if {![::Checks::is_true $absorb]} continue

        set dock [::Checks::get_cached_property $bldg "DockUnload"]
        if {[::Checks::is_true $dock]} {
            ::Logging::warning "BuildingType \"$bldg\" has UnitAbsorb=yes and DockUnload=yes. Units docked at this building will be unable to perform their original behaviors (e.g., ore trucks will fail to unload)."
        }
    }
}

# Register this check
::Checks::register_check "validate_unit_absorb_dock_unload"
