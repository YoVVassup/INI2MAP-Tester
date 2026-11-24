# checks/inviso.tcl
# Validates projectiles with Inviso=yes for inaccuracy bugs when combined with Airburst=yes or EMEffect=yes warheads
# Game modes: RA2/YR/Ares
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Map projectile name -> first weapon using it that has a non-empty warhead.
# Mirrors the original scan order: first matching weapon with a warhead wins,
# empty-warhead matches are skipped.
proc ::Checks::_inviso_proj_index {} {
    variable inviso_idx_ready
    variable inviso_idx
    if {$inviso_idx_ready} { return $inviso_idx }
    set inviso_idx [dict create]
    if {[info exists ::Data::weapons]} {
        foreach {w_idx wep_name} [array get ::Data::weapons] {
            set proj [::Checks::get_cached_property $wep_name "Projectile"]
            if {$proj eq "" || [dict exists $inviso_idx $proj]} continue
            set wh [::Checks::get_cached_property $wep_name "Warhead"]
            if {$wh ne ""} { dict set inviso_idx $proj [list $wep_name $wh] }
        }
    }
    set inviso_idx_ready 1
    return $inviso_idx
}

proc ::Checks::validate_inviso {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::projectiles projectiles
    upvar ::Data::weapons weapons

    # Inviso is fixed in Phobos
    if {$gamemode eq "phobos"} {
        return
    }

    if {![info exists projectiles]} {
        return
    }

    set proj_index ""
    foreach {idx proj_name} [array get projectiles] {
        set inviso [::Checks::get_cached_property $proj_name "Inviso"]
        if {![::Checks::is_true $inviso]} {
            continue
        }

        set airburst [::Checks::get_cached_property $proj_name "Airburst"]
        set has_airburst [::Checks::is_true $airburst]

        set has_em_effect 0
        set wh_name ""

        # Find warhead via weapon that uses this projectile
        if {$proj_index eq ""} { set proj_index [::Checks::_inviso_proj_index] }
        if {[dict exists $proj_index $proj_name]} {
            lassign [dict get $proj_index $proj_name] wh_weapon wh_name
            set em_effect [::Checks::get_cached_property $wh_name "EMEffect"]
            set has_em_effect [::Checks::is_true $em_effect]
        }

        if {$has_airburst && $has_em_effect} {
            ::Logging::warning "Projectile \"$proj_name\" has Inviso=yes combined with Airburst=yes and warhead \"$wh_name\" with EMEffect=yes. This combination may cause severe inaccuracy and damage bugs."
        } elseif {$has_airburst} {
            ::Logging::warning "Projectile \"$proj_name\" has Inviso=yes and Airburst=yes. This may cause inaccuracy problems."
        } elseif {$has_em_effect} {
            ::Logging::warning "Projectile \"$proj_name\" has Inviso=yes and uses warhead \"$wh_name\" with EMEffect=yes. This may cause inaccuracy and damage bugs."
        }
    }
}

::Checks::register_check "validate_inviso"