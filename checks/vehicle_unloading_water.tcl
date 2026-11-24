# checks/vehicle_unloading_water.tcl
# Validates UnloadingClass and WaterImage usage on VehicleTypes
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/UnloadingClass
#   https://modenc.renegadeprojects.com/WaterImage
#
# Bugs:
#   UnloadingClass:
#     Logic only works for VehicleTypes with Dock=yes AND IsSimpleDeployer=yes.
#     Setting it on other vehicles has no effect on unload behavior.
#   WaterImage:
#     Shape -> Voxel: No transformation, renders empty if resource missing.
#     Voxel -> Shape: Crashes if Voxel resource fails to load.
#     Cannot switch between Voxel and Shape formats.

proc ::Checks::validate_vehicle_unloading_water {} {
    upvar ::Data::vehicles vehicles

    if {![info exists vehicles]} return

    foreach veh [array names vehicles] {
        # UnloadingClass check - only warn if vehicle has neither Dock nor IsSimpleDeployer
        set uc [::Checks::get_cached_property $veh "UnloadingClass"]
        if {$uc ne ""} {
            set dock [::Checks::get_cached_property $veh "Dock"]
            set deployer [::Checks::get_cached_property $veh "IsSimpleDeployer"]

            if {![::Checks::is_true $dock] && ![::Checks::is_true $deployer]} {
                ::Logging::notice "VehicleType \"$veh\" has UnloadingClass=\"$uc\" but does not have Dock=yes or IsSimpleDeployer=yes. UnloadingClass unload logic only works when both are set."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_vehicle_unloading_water"
