# checks/is_sonic.tcl
# Validates IsSonic weapon flag and warns about known YR bugs: Primary-only
#   Warhead/AmbientDamage reads, no conventional damage, 8-cell range cap,
#   and Wall=no being ignored (fixed in Ares/Phobos)
# Game modes: YR
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_is_sonic {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::weapons weapons

    # IsSonic is not used in RA2, and in Ares/Phobos bugs are fixed
    if {$gamemode ne "yr"} {
        return
    }

    if {![info exists weapons]} {
        return
    }

    foreach {idx wep_name} [array get weapons] {
        set is_sonic [::Checks::get_cached_property $wep_name "IsSonic"]
        if {![::Checks::is_true $is_sonic]} {
            continue
        }

        ::Logging::warning "Weapon \"$wep_name\" has IsSonic=yes. Sonic weapons have severe bugs: they deal no conventional damage, Warhead/AmbientDamage are read from Primary weapon, range is limited to 8 cells, and Warhead ignores Wall=no."

        # Check range (Range= or MaximumRange=) – warn if > 8
        set range [::Checks::get_cached_property $wep_name "Range"]
        set max_range [::Checks::get_cached_property $wep_name "MaximumRange"]
        if {$range eq ""} { set range 0 }
        if {$max_range eq ""} { set max_range 0 }
        set effective_range [expr {max($range, $max_range)}]
        if {$effective_range > 8} {
            ::Logging::warning "Sonic weapon \"$wep_name\" has range $effective_range (>8). The effective range is hard-limited to 8 cells."
        }
    }
}

::Checks::register_check "validate_is_sonic"