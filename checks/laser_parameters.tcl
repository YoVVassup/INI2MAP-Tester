# checks/laser_parameters.tcl
# Validates laser weapon parameters and warns when secondary/elite laser weapons
#   differ from primary, since LaserDuration/InnerColor/OuterColor/OuterSpread
#   are only read from the Primary weapon (fixed in Phobos)
# Game modes: RA2/YR/Ares
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Helper to check if a weapon is a laser type
proc ::Checks::_lp_is_laser {wep_name} {
    set is_laser [::Checks::get_cached_property $wep_name "IsLaser"]
    set is_big_laser [::Checks::get_cached_property $wep_name "IsBigLaser"]
    return [expr {[::Checks::is_true $is_laser] || [::Checks::is_true $is_big_laser]}]
}

# Helper to get a parameter value from a weapon
proc ::Checks::_lp_get_param {wep_name param} {
    set val [::Checks::get_cached_property $wep_name $param]
    if {$val eq ""} {
        switch -- $param {
            "LaserDuration"    { return 10 }
            "LaserInnerColor"  { return "0,0,0" }
            "LaserOuterColor"  { return "0,0,0" }
            "LaserOuterSpread" { return "0,0,0" }
            default            { return $val }
        }
    }
    return $val
}

proc ::Checks::validate_laser_parameters {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::weapons weapons

    # The bug is fixed in Phobos
    if {$gamemode eq "phobos"} {
        return
    }

    if {![info exists weapons]} {
        return
    }

    # Laser parameters affected by the bug
    set laser_params [list \
        LaserDuration \
        LaserInnerColor \
        LaserOuterColor \
        LaserOuterSpread \
    ]

    # Iterate over all techno types
    foreach {type_name type_array} [list \
        Infantry infantry \
        Vehicle vehicles \
        Aircraft aircraft \
        Building buildings \
    ] {
        if {![info exists $type_array]} continue
        upvar 0 $type_array arr
        foreach name [array names arr] {
            set primary [::Checks::get_cached_property $name "Primary"]
            set secondary [::Checks::get_cached_property $name "Secondary"]
            set elite_primary [::Checks::get_cached_property $name "ElitePrimary"]
            set elite_secondary [::Checks::get_cached_property $name "EliteSecondary"]

            if {$primary eq ""} continue

            set primary_is_laser [::Checks::_lp_is_laser $primary]

            foreach wep [list $secondary $elite_primary $elite_secondary] {
                if {$wep eq ""} continue
                if {![::Checks::_lp_is_laser $wep]} continue

                if {!$primary_is_laser} {
                    ::Logging::notice "$type_name \"$name\" has secondary/elite laser weapon \"$wep\" but primary weapon \"$primary\" is not a laser. In $gamemode, the laser will not draw at all."
                    continue
                }

                foreach param $laser_params {
                    set primary_val [::Checks::_lp_get_param $primary $param]
                    set wep_val [::Checks::_lp_get_param $wep $param]
                    if {$primary_val ne $wep_val} {
                        ::Logging::notice "$type_name \"$name\" has secondary/elite laser weapon \"$wep\" with $param=$wep_val, but primary weapon \"$primary\" has $param=$primary_val. In $gamemode, $param is only read from the primary weapon."
                    }
                }
            }
        }
    }
}

::Checks::register_check "validate_laser_parameters"