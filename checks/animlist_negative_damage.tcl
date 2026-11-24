# checks/animlist_negative_damage.tcl
# Validates that Warheads or Weapons with negative Damage do not have AnimList set, which causes EI crash when the animation plays
# Game modes: RA2/YR
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_animlist_negative_damage {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::warheads warheads
    upvar ::Data::weapons weapons

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return
    if {![info exists warheads] || ![info exists weapons]} return

    foreach {idx wh_name} [array get warheads] {
        set animlist [::Checks::get_cached_property $wh_name "AnimList"]
        if {$animlist eq ""} continue

        set damage [::Checks::get_cached_property $wh_name "Damage"]
        if {$damage eq ""} continue

        if {[string is double -strict $damage] && $damage < 0} {
            ::Logging::warning "Warhead \"$wh_name\" has negative Damage ($damage) and an AnimList. This combination causes EI crash when the animation plays."
        }
    }

    foreach {idx wep_name} [array get weapons] {
        set wh_name [::Checks::get_cached_property $wep_name "Warhead"]
        if {$wh_name eq ""} continue
        if {![info exists warheads($wh_name)]} continue

        set animlist [::Checks::get_cached_property $wh_name "AnimList"]
        if {$animlist eq ""} continue

        set damage [::Checks::get_cached_property $wep_name "Damage"]
        if {$damage eq ""} continue

        if {[string is double -strict $damage] && $damage < 0} {
            ::Logging::warning "Weapon \"$wep_name\" has negative Damage ($damage) and Warhead \"$wh_name\" has AnimList. This combination may cause EI crash."
        }
    }
}

# Register this check
::Checks::register_check "validate_animlist_negative_damage"