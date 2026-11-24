# checks/land_targeting.tcl
# Validates LandTargeting flag on all TechnoTypes and warns when it is set on
#   types with Deployer+DeployFire or IsGattling, which causes the flag to be ignored
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Helper to check if a TechnoType has conflicting flags
proc ::Checks::_lt_check {type_name} {
    set land_targeting [::Checks::get_cached_property $type_name "LandTargeting"]
    if {$land_targeting eq "" || (![string is integer -strict $land_targeting] || $land_targeting == 0)} {
        return
    }

    set deployer [::Checks::get_cached_property $type_name "Deployer"]
    set deploy_fire [::Checks::get_cached_property $type_name "DeployFire"]
    set is_gattling [::Checks::get_cached_property $type_name "IsGattling"]

    if {[::Checks::is_true $deployer] && [::Checks::is_true $deploy_fire]} {
        ::Logging::warning "$type_name has LandTargeting=$land_targeting and Deployer=yes & DeployFire=yes. The LandTargeting flag will be ignored."
    } elseif {[::Checks::is_true $is_gattling]} {
        ::Logging::warning "$type_name has LandTargeting=$land_targeting and IsGattling=yes. The LandTargeting flag will be ignored."
    }
}

proc ::Checks::validate_land_targeting {} {
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles

    if {[info exists aircraft]} {
        foreach name [array names aircraft] {
            ::Checks::_lt_check $name
        }
    }
    if {[info exists buildings]} {
        foreach name [array names buildings] {
            ::Checks::_lt_check $name
        }
    }
    if {[info exists infantry]} {
        foreach name [array names infantry] {
            ::Checks::_lt_check $name
        }
    }
    if {[info exists vehicles]} {
        foreach name [array names vehicles] {
            ::Checks::_lt_check $name
        }
    }
}

::Checks::register_check "validate_land_targeting"