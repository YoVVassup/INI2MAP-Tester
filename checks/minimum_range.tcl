# checks/minimum_range.tcl
# Validates MinimumRange on weapons and warns when combined with Range=-2
#   (infinite range), which causes MinimumRange to be ignored
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property

proc ::Checks::validate_minimum_range {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::weapons weapons
    upvar ::Data::infantry infantry

    if {![info exists weapons]} {
        return
    }

    set is_phobos [expr {$gamemode eq "phobos"}]

    # Iterate over all weapons
    foreach {idx wep_name} [array get weapons] {
        set min_range [::Checks::get_cached_property $wep_name "MinimumRange"]
        if {$min_range eq ""} {
            continue
        }

        set range [::Checks::get_cached_property $wep_name "Range"]
        if {[string is integer -strict $range] && $range == -2} {
            ::Logging::warning "Weapon \"$wep_name\" has MinimumRange=$min_range and Range=-2. The MinimumRange will be ignored because the weapon has infinite range."
        }
    }
}

::Checks::register_check "validate_minimum_range"