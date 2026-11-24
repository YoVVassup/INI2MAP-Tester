# checks/is_simple_deployer.tcl
# Validates IsSimpleDeployer flag usage on Jumpjet VehicleTypes and warns about
#   conflicting DeployToLand/BalloonHover interactions and redundant tag combinations
# Game modes: YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_is_simple_deployer {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::vehicles vehicles

    # This flag is not available in RA2
    if {$gamemode eq "ra2"} {
        return
    }

    if {![info exists vehicles]} {
        return
    }

    # CLSID for Jumpjet locomotor (airborne units)
    set jumpjet_clsid "{92612C46-F71F-11d1-AC9F-006008055BB5}"

    foreach veh [array names vehicles] {
        set is_simple_deployer [::Checks::get_cached_property $veh "IsSimpleDeployer"]
        if {![::Checks::is_true $is_simple_deployer]} {
            continue
        }

        # Check locomotor type – only relevant for airborne units
        set locomotor [::Checks::get_cached_property $veh "Locomotor"]
        if {[string first $jumpjet_clsid $locomotor] == -1} {
            # Not a Jumpjet unit; skip (ground units don't have landing issues)
            continue
        }

        set deploy_to_land [::Checks::get_cached_property $veh "DeployToLand"]
        set deploy_to_land_yes [::Checks::is_true $deploy_to_land]

        if {!$deploy_to_land_yes} {
            ::Logging::warning "Vehicle \"$veh\" has IsSimpleDeployer=yes but DeployToLand=no (or missing). This will prevent BalloonHover from keeping the unit in the air; the unit will land as soon as possible. Add DeployToLand=yes if you want hovering deployment."
        } else {
            ::Logging::warning "Vehicle \"$veh\" has IsSimpleDeployer=yes and DeployToLand=yes. For VehicleTypes, this combination is pointless (no effect). IsSimpleDeployer alone is sufficient for deployment behavior; adding DeployToLand=yes provides no benefit for airborne units."
        }

        # Optional: check BalloonHover for additional context
        set balloon_hover [::Checks::get_cached_property $veh "BalloonHover"]
        if {[::Checks::is_true $balloon_hover] && !$deploy_to_land_yes} {
            ::Logging::notice "Vehicle \"$veh\" has IsSimpleDeployer=yes and BalloonHover=yes but lacks DeployToLand=yes. BalloonHover will be ignored; the unit will land upon deployment."
        }
    }
}

::Checks::register_check "validate_is_simple_deployer"