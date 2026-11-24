# checks/turret_voxel_newtheater.tcl
# Validates that BuildingTypes with TurretAnimIsVoxel=yes have NewTheater=yes
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/TurretAnimIsVoxel
#
# Bug:
#   If TurretAnimIsVoxel=yes is enabled on a BuildingType, the building
#   must also have NewTheater=yes. Otherwise the turret will not be drawn.

proc ::Checks::validate_turret_voxel_newtheater {} {
    upvar ::Data::buildings buildings

    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set is_voxel [::Checks::get_cached_property $bldg "TurretAnimIsVoxel"]
        if {![::Checks::is_true $is_voxel]} continue

        set newtheater [::Checks::get_cached_property $bldg "NewTheater"]
        if {![::Checks::is_true $newtheater]} {
            ::Logging::warning "BuildingType \"$bldg\" has TurretAnimIsVoxel=yes but NewTheater is not set to yes. The voxel turret will not be drawn without NewTheater=yes."
        }
    }
}

# Register this check
::Checks::register_check "validate_turret_voxel_newtheater"
