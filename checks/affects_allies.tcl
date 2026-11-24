# checks/affects_allies.tcl
# Validates that AffectsAllies=yes is not combined with Temporal=yes or IsLocomotor=yes on Warheads, which causes incorrect ally targeting or crashes
# Game modes: YR
# Uses: ::Checks::is_true, ::Checks::is_false, ::Checks::get_cached_property

proc ::Checks::validate_affects_allies {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::warheads warheads

    if {$gamemode ne "yr"} return
    if {![info exists warheads]} return

    foreach {idx warhead_name} [array get warheads] {
        set affects_allies [::Checks::get_cached_property $warhead_name "AffectsAllies"]
        if {[::Checks::is_true $affects_allies]} {
            set affects_yes 1
        } elseif {[::Checks::is_false $affects_allies]} {
            set affects_yes 0
        } else {
            continue
        }

        if {!$affects_yes} continue

        set temporal [::Checks::get_cached_property $warhead_name "Temporal"]
        set is_locomotor [::Checks::get_cached_property $warhead_name "IsLocomotor"]

        if {[::Checks::is_true $temporal]} {
            ::Logging::warning "Warhead \"$warhead_name\" has AffectsAllies=yes and Temporal=yes. Temporal weapons ignore AffectsAllies and will not affect allies as expected."
        }
        if {[::Checks::is_true $is_locomotor]} {
            ::Logging::warning "Warhead \"$warhead_name\" has AffectsAllies=yes and IsLocomotor=yes. This combination may cause crashes or unexpected behavior."
        }
    }
}

# Register this check
::Checks::register_check "validate_affects_allies"