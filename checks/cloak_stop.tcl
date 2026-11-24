# checks/cloak_stop.tcl
# Validates CloakStop flag - warns when combined with BalloonHover, DeployToLand, or IsSimpleDeployer which cause CloakStop to be ignored
# Game modes: RA2/YR/Ares (skips Phobos)
# Uses: ::Checks::is_true, ::Checks::get_cached_property, ::Checks::get_all_techno_types

proc ::Checks::validate_cloak_stop {} {
    upvar ::Data::gamemode gamemode

    if {$gamemode eq "phobos"} return

    set all_types [::Checks::get_all_techno_types]

    foreach type $all_types {
        set cloak_stop [::Checks::get_cached_property $type "CloakStop"]
        if {![::Checks::is_true $cloak_stop]} continue

        set balloon_hover      [::Checks::get_cached_property $type "BalloonHover"]
        set deploy_to_land     [::Checks::get_cached_property $type "DeployToLand"]
        set is_simple_deployer [::Checks::get_cached_property $type "IsSimpleDeployer"]

        set has_conflict 0
        set conflicts ""
        if {[::Checks::is_true $balloon_hover]} {
            set has_conflict 1
            append conflicts " BalloonHover=yes"
        }
        if {[::Checks::is_true $deploy_to_land]} {
            set has_conflict 1
            append conflicts " DeployToLand=yes"
        }
        if {[::Checks::is_true $is_simple_deployer]} {
            set has_conflict 1
            append conflicts " IsSimpleDeployer=yes"
        }

        if {$has_conflict} {
            ::Logging::warning "Type \"$type\" has CloakStop=yes combined with:$conflicts. CloakStop will be ignored (does not work) in $gamemode."
        }
    }
}

# Register this check
::Checks::register_check "validate_cloak_stop"