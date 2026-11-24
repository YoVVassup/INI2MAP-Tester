# checks/laser_thickness.tcl
# Validates LaserThickness on laser weapons and warns about Ares limitations:
#   effective max of 8, requires IsHouseColor=yes (fixed in Phobos)
# Game modes: Ares
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_laser_thickness {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::weapons weapons

    if {$gamemode ne "ares"} {
        return
    }

    if {![info exists weapons]} {
        return
    }

    foreach {idx wep_name} [array get weapons] {
        set thickness [::Checks::get_cached_property $wep_name "LaserThickness"]
        if {$thickness eq "" || ![string is integer -strict $thickness]} {
            continue
        }

        # Check if the weapon is a laser type
        set is_laser [::Checks::get_cached_property $wep_name "IsLaser"]
        set is_big_laser [::Checks::get_cached_property $wep_name "IsBigLaser"]
        set is_laser_weapon [expr {[::Checks::is_true $is_laser] || [::Checks::is_true $is_big_laser]}]

        if {!$is_laser_weapon} {
            ::Logging::warning "Weapon \"$wep_name\" has LaserThickness=$thickness but IsLaser=no (and IsBigLaser=no). LaserThickness only works on laser weapons."
            continue
        }

        # Check IsHouseColor requirement
        set is_house_color [::Checks::get_cached_property $wep_name "IsHouseColor"]
        if {![::Checks::is_true $is_house_color]} {
            ::Logging::warning "Weapon \"$wep_name\" has LaserThickness=$thickness but IsHouseColor is not set to yes. In Ares, LaserThickness only works with IsHouseColor=yes."
        }

        # Warn if thickness exceeds the effective limit (8)
        if {$thickness > 8} {
            ::Logging::warning "Weapon \"$wep_name\" has LaserThickness=$thickness. In Ares, the maximum supported effective value is 8."
        }
    }
}

::Checks::register_check "validate_laser_thickness"