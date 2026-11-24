# checks/locomotor_bugs.tcl
# Validates known Locomotor combination bugs
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/Locomotor
#
# Bugs:
#   Hover + IsSimpleDeployer + DeployToLand: Stuck deployment, continuous
#     movement sound (fixed in Phobos Build#44).
#   Tunnel + InfantryType: Immediate crash on movement (Phobos DevBuild#44).
#   Ship + Bunker=yes building entry: IE crash.
#   Jumpjet + Harvester: No auto-mine, overlapping docking crash
#     (fixed in Phobos Build#48).
#   Rocket + Teleporter=yes VehicleType: Crash on destruction,
#     inaccurate targeting (fixed in Phobos Build#49).

proc ::Checks::validate_locomotor_bugs {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft

    set is_phobos [expr {$gamemode eq "phobos"}]

    # Collect all TechnoTypes with their type names
    set all_types [list]
    if {[info exists infantry]} {
        foreach n [array names infantry] { lappend all_types "InfantryType" $n }
    }
    if {[info exists vehicles]} {
        foreach n [array names vehicles] { lappend all_types "VehicleType" $n }
    }
    if {[info exists aircraft]} {
        foreach n [array names aircraft] { lappend all_types "AircraftType" $n }
    }

    foreach {type_name name} $all_types {
        set loco [::Checks::get_cached_property $name "Locomotor"]
        if {$loco eq ""} continue

        set loco_lower [string tolower $loco]

        # Hover + IsSimpleDeployer + DeployToLand
        if {[string match "*4a582742-9839-11d1-b709-00a024ddafd1*" $loco_lower]} {
            set deployer [::Checks::get_cached_property $name "IsSimpleDeployer"]
            set deploy_land [::Checks::get_cached_property $name "DeployToLand"]
            if {[::Checks::is_true $deployer] && [::Checks::is_true $deploy_land] && !$is_phobos} {
                ::Logging::warning "$type_name \"$name\" uses Hover Locomotor with IsSimpleDeployer=yes and DeployToLand=yes. Units may get stuck in deployment and continuously play movement sounds. Fixed in Phobos Build#44."
            }
        }

        # Tunnel + InfantryType crash
        if {[string match "*4a582743-9839-11d1-b709-00a024ddafd1*" $loco_lower] && $type_name eq "InfantryType" && !$is_phobos} {
            ::Logging::error "$type_name \"$name\" uses Tunnel Locomotor. InfantryTypes with Tunnel will crash immediately upon moving due to a bug. Fixed in Phobos DevBuild#44."
        }

        # Jumpjet + Harvester
        if {[string match "*92612c46-f71f-11d1-ac9f-006008055bb5*" $loco_lower]} {
            set harvester [::Checks::get_cached_property $name "Harvester"]
            if {[::Checks::is_true $harvester] && !$is_phobos} {
                ::Logging::warning "$type_name \"$name\" uses Jumpjet Locomotor with Harvester=yes. Harvesters will not auto-mine after leaving Factory, and overlapping docking may cause a crash. Fixed in Phobos Build#48."
            }
        }

        # Rocket + Teleporter
        if {[string match "*b7b49766-e576-11d3-9bd9-00104b972fe8*" $loco_lower] && $type_name eq "VehicleType"} {
            set teleporter [::Checks::get_cached_property $name "Teleporter"]
            if {[::Checks::is_true $teleporter] && !$is_phobos} {
                ::Logging::warning "$type_name \"$name\" uses Rocket Locomotor with Teleporter=yes. The vehicle will crash when destroyed. Fixed in Phobos Build#49."
            }
        }

        # Ship + Bunker entry
        if {[string match "*2bea74e1-7cca-11d3-be14-00104b62a16c*" $loco_lower]} {
            ::Logging::warning "$type_name \"$name\" uses Ship Locomotor. Ship units cannot enter buildings with Bunker=yes - this will cause an Internal Error."
        }
    }
}

# Register this check
::Checks::register_check "validate_locomotor_bugs"
