# checks/no_spawn_alt.tcl
# Validates NoSpawnAlt flag to prevent EIP and display issues with Turret
# Game modes: YR/Ares/Phobos (excludes RA2)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#   - Using NoSpawnAlt on vehicles that cannot spawn objects will cause an IE.
#   - Conflict with Turret=yes and image allocation (fixed in Ares 3.0).
# Uses ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_no_spawn_alt {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::vehicles vehicles
    upvar ::Data::weapons weapons

    # This flag only exists in YR/Ares/Phobos; RA2 does not use it.
    if {$gamemode eq "ra2"} {
        return
    }

    if {![info exists vehicles]} {
        return
    }

    set is_ares   [expr {$gamemode eq "ares"}]
    set is_phobos [expr {$gamemode eq "phobos"}]
    set has_turret_fix [expr {$is_ares || $is_phobos}]

    # Step 1: Find all weapons with Spawner=yes
    array set spawner_weapons {}
    if {[info exists weapons]} {
        foreach {idx wep_name} [array get weapons] {
            set spawner [::Checks::get_cached_property $wep_name "Spawner"]
            if {[::Checks::is_true $spawner]} {
                set spawner_weapons($wep_name) 1
            }
        }
    }

    # If no Spawner weapons exist, NoSpawnAlt is irrelevant
    if {[array size spawner_weapons] == 0} {
        return
    }

    # Step 2: Check each vehicle
    foreach veh [array names vehicles] {
        set no_spawn_alt [::Checks::get_cached_property $veh "NoSpawnAlt"]
        if {![::Checks::is_true $no_spawn_alt]} {
            continue
        }

        # Step 3: Check if the vehicle can actually spawn objects
        set can_spawn 0

        # Check if the vehicle has a valid Spawns= entry
        set spawns [::Checks::get_cached_property $veh "Spawns"]
        if {$spawns ne ""} {
            set can_spawn 1
        }

        # If not, check if any of its weapons has Spawner=yes
        if {!$can_spawn} {
            foreach slot {Primary Secondary ElitePrimary EliteSecondary} {
                set wep [::Checks::get_cached_property $veh $slot]
                if {$wep ne "" && [info exists spawner_weapons($wep)]} {
                    set can_spawn 1
                    break
                }
            }
        }

        # Error if the vehicle has NoSpawnAlt but cannot spawn
        if {!$can_spawn} {
            ::Logging::error "Vehicle \"$veh\" has NoSpawnAlt=yes but cannot spawn objects (Spawns= missing or no weapon with Spawner=yes). This will cause an EIP."
            continue
        }

        # Step 4: Check for Turret conflict
        set turret [::Checks::get_cached_property $veh "Turret"]
        if {[::Checks::is_true $turret] && !$has_turret_fix} {
            ::Logging::warning "Vehicle \"$veh\" has NoSpawnAlt=yes and Turret=yes. The alternate image is stored in the same memory buffer as the turret, causing display issues."
        }
    }
}

::Checks::register_check "validate_no_spawn_alt"