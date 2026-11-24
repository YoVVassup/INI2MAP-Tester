#----------------------------------------------------------------------------------------------------------
# aicheck/ref_check.tcl - Cross-reference validation (weapons, warheads, projectiles, animations)
#----------------------------------------------------------------------------------------------------------

proc ::AICheck::check_references {} {
    if {[catch {_check_references_impl} err]} {
        ::Logging::error "check_references failed: $err"
    }
}

proc ::AICheck::_check_references_impl {} {
    if {![info exists ::Data::rulesdata] && ![info exists ::Data::rawmapdata]} return

    set used_weapons [dict create]
    set used_warheads [dict create]
    set used_projectiles [dict create]
    set anim_refs {}

    # Build name-based lookups from rules data (O(n) once, O(1) lookup later)
    set known_weapons [dict create]
    if {[info exists ::Data::weapons]} {
        foreach idx [array names ::Data::weapons] {
            set n $::Data::weapons($idx)
            if {$n ne ""} { dict set known_weapons $n 1 }
        }
    }
    set known_warheads [dict create]
    if {[info exists ::Data::warheads]} {
        foreach idx [array names ::Data::warheads] {
            set n $::Data::warheads($idx)
            if {$n ne ""} { dict set known_warheads $n 1 }
        }
    }
    set known_projectiles [dict create]
    if {[info exists ::Data::projectiles]} {
        foreach idx [array names ::Data::projectiles] {
            set n $::Data::projectiles($idx)
            if {$n ne ""} { dict set known_projectiles $n 1 }
        }
    }

    # Build lookup sets from rawmapdata type lists (dict instead of lsearch)
    set raw_weapons [dict create]
    if {[info exists ::Data::rawmapdata(WeaponTypes)]} {
        foreach wl $::Data::rawmapdata(WeaponTypes) {
            set kv [::util::_parse_keyval $wl]
            if {$kv ne ""} { dict set raw_weapons [lindex $kv 1] 1 }
        }
    }
    set raw_warheads [dict create]
    if {[info exists ::Data::rawmapdata(Warheads)]} {
        foreach wl $::Data::rawmapdata(Warheads) {
            set kv [::util::_parse_keyval $wl]
            if {$kv ne ""} { dict set raw_warheads [lindex $kv 1] 1 }
        }
    }
    set raw_projectiles [dict create]
    if {[info exists ::Data::rawmapdata(Projectiles)]} {
        foreach wl $::Data::rawmapdata(Projectiles) {
            set kv [::util::_parse_keyval $wl]
            if {$kv ne ""} { dict set raw_projectiles [lindex $kv 1] 1 }
        }
    }

    # TechnoType weapon property names
    set techno_weapon_props [dict create]
    foreach p {Primary Secondary DeathWeapon ElitePrimary EliteSecondary EliteDeathWeapon
        OccupyWeapon EliteOccupyWeapon WeaponType} {
        dict set techno_weapon_props $p 1
    }
    for {set i 1} {$i <= 127} {incr i} {
        dict set techno_weapon_props "Weapon$i" 1
        dict set techno_weapon_props "EliteWeapon$i" 1
    }

    # Projectile weapon property names
    set projectile_weapon_props [dict create AirburstWeapon 1 ShrapnelWeapon 1]

    # Warhead property names
    set warhead_props [dict create Warhead 1 SW.Warhead 1 Missile.Warhead 1 Missile.EliteWarhead 1 IvanBomb.Warhead 1]

    # Animation property names
    set anim_props [dict create Buildup 1 BibShape 1 DestroyAnim 1 TrailerAnim 1 ExpireAnim 1 AnimList 1 DebrisAnims 1]

    # Single pass over all sections
    foreach src {::Data::rulesdata ::Data::rawmapdata} {
        if {![info exists $src]} continue

        foreach section [array names $src] {
            if {$section eq ""} continue

            foreach line [set ${src}($section)] {
                set eq [string first "=" $line]
                if {$eq == -1} continue
                set pfx [string range $line 0 [expr {$eq-1}]]
                set pfx [string trim $pfx]
                set val [string range $line [expr {$eq+1}] end]
                set val [string trim $val]
                if {$val eq "" || $val eq "none" || $val eq "<none>"} continue

                if {[dict exists $techno_weapon_props $pfx] || [dict exists $projectile_weapon_props $pfx]} {
                    if {![dict exists $known_weapons $val] && ![dict exists $raw_weapons $val]} {
                        ::Logging::warning "\[$section\] uses undeclared Weapon: $val"
                    } else {
                        dict set used_weapons $val 1
                    }
                } elseif {[dict exists $warhead_props $pfx]} {
                    if {![dict exists $known_warheads $val] && ![dict exists $raw_warheads $val]} {
                        ::Logging::warning "\[$section\] uses undeclared Warhead: $val"
                    } else {
                        dict set used_warheads $val 1
                    }
                } elseif {$pfx eq "Projectile"} {
                    if {![dict exists $known_projectiles $val] && ![dict exists $raw_projectiles $val]} {
                        ::Logging::warning "\[$section\] uses undeclared Projectile: $val"
                    } else {
                        dict set used_projectiles $val 1
                    }
                } elseif {[dict exists $anim_props $pfx]} {
                    foreach anim [split $val ","] {
                        set anim [string trim [string toupper $anim]]
                        if {$anim ne ""} {
                            lappend anim_refs [list $section $pfx $anim]
                        }
                    }
                }
            }
        }
    }

    foreach ref $anim_refs {
        lassign $ref section pfx anim
        if {![info exists ::Data::anims($anim)]} {
            ::Logging::warning "\[$section\] $pfx uses undeclared Animation: $anim"
        }
    }

    # Report unused weapons
    dict for {name _} $known_weapons {
        if {![dict exists $used_weapons $name] && ![dict exists $raw_weapons $name]} {
            ::Logging::notice "Weapon \"$name\" is declared but unused"
        }
    }

    # Report unused warheads
    dict for {name _} $known_warheads {
        if {![dict exists $used_warheads $name] && ![dict exists $raw_warheads $name]} {
            ::Logging::notice "Warhead \"$name\" is declared but unused"
        }
    }
}
