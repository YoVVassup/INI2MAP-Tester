# checks/infinite_mind_control.tcl
# Validates weapons with InfiniteMindControl=yes for Damage=0/1 bugs and missing MindControl on warhead
# Game modes: YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_infinite_mind_control {} {
    upvar ::Data::gamemode gamemode

    # Only relevant for Yuri's Revenge and its mods (Ares/Phobos)
    if {$gamemode eq "ra2"} {
        return
    }

    set is_phobos [expr {$gamemode eq "phobos"}]

    # Get list of weapons from rules
    upvar ::Data::weapons weapons
    if {![info exists weapons]} {
        return
    }

    foreach {idx wep_name} [array get weapons] {
        set infinite_mc [::Checks::get_cached_property $wep_name "InfiniteMindControl"]
        if {![::Checks::is_true $infinite_mc]} {
            continue
        }

        set wh_name [::Checks::get_cached_property $wep_name "Warhead"]
        if {$wh_name eq ""} {
            ::Logging::warning "Weapon \"$wep_name\" has InfiniteMindControl=yes but no Warhead specified."
            continue
        }

        # Check if warhead has MindControl=yes using cached property
        set mind_control [::Checks::get_cached_property $wh_name "MindControl"]
        if {![::Checks::is_true $mind_control]} {
            ::Logging::warning "Weapon \"$wep_name\" has InfiniteMindControl=yes but Warhead \"$wh_name\" lacks MindControl=yes. Flag will be ignored."
            continue
        }

        set damage [::Checks::get_cached_property $wep_name "Damage"]
        if {$damage eq ""} {
            set damage 0
        }
        if {![string is integer -strict $damage]} {
            ::Logging::warning "Weapon \"$wep_name\" has non-integer Damage: $damage"
            continue
        }

        # Bug cases: Damage=0 and Damage=1 have known issues in YR/Ares.
        # In Phobos these are fixed, so we only warn for non-Phobos.
        if {!$is_phobos} {
            if {$damage == 0} {
                ::Logging::warning "Weapon \"$wep_name\" has InfiniteMindControl=yes and Damage=0. This allows unlimited mind-controlled units (ignores standard limit)."
            } elseif {$damage == 1} {
                ::Logging::warning "Weapon \"$wep_name\" has InfiniteMindControl=yes and Damage=1. This incorrectly limits control to only 1 unit. (Fixed in Phobos.)"
            }
        }
    }
}

::Checks::register_check "validate_infinite_mind_control"