# checks/cluster.tcl
# Validates Cluster property on Projectiles - warns when Airburst=yes overrides Cluster value with hardcoded 9 in RA2/YR
# Game modes: RA2/YR only (skips Ares/Phobos)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_cluster {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::projectiles projectiles

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return
    if {![info exists projectiles]} return

    foreach {idx proj_name} [array get projectiles] {
        set cluster  [::Checks::get_cached_property $proj_name "Cluster"]
        if {![string is integer -strict $cluster]} continue

        set airburst [::Checks::get_cached_property $proj_name "Airburst"]
        if {[::Checks::is_true $airburst]} {
            ::Logging::warning "Projectile \"$proj_name\" has Cluster=$cluster and Airburst=yes. In RA2/YR, when Airburst is set, the Cluster value is ignored and a hardcoded value of 9 is used instead."
        }
    }
}

# Register this check
::Checks::register_check "validate_cluster"