# checks/number_of_docks.tcl
# Validates NumberOfDocks flag to prevent EIP and docking issues
# Game modes: RA2/YR (flag not present in Ares/Phobos or limited)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#   - Setting NumberOfDocks=2 (or higher) on buildings without Helipad=yes may cause issues.
#   - On buildings with Bunker=yes, NumberOfDocks > 1 does not allow a second vehicle to enter.
#   - On buildings with UnitRepair=yes, NumberOfDocks > 1 may trigger EIP#0044C71E.
#   - Refineries (Refinery=yes) ignore NumberOfDocks and DockingOffset.
# Uses ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_number_of_docks {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    if {![info exists buildings]} {
        return
    }

    foreach bldg [array names buildings] {
        set num_docks [::Checks::get_cached_property $bldg "NumberOfDocks"]
        if {$num_docks eq ""} {
            continue
        }
        if {![string is integer -strict $num_docks]} {
            ::Logging::warning "Building \"$bldg\" has non-integer NumberOfDocks: $num_docks"
            continue
        }

        # Convert to integer for comparison
        set docks [expr {$num_docks}]

        # For non-refinery buildings with NumberOfDocks >= 2
        if {$docks >= 2} {
            # --- Helipad ---
            set is_helipad [::Checks::is_true [::Checks::get_cached_property $bldg "Helipad"]]
            if {$is_helipad} {
                # On Helipads, NumberOfDocks works as expected (multiple landing pads)
                continue
            }

            # --- Bunker ---
            set is_bunker [::Checks::is_true [::Checks::get_cached_property $bldg "Bunker"]]
            if {$is_bunker} {
                ::Logging::warning "Building \"$bldg\" has NumberOfDocks=$docks and Bunker=yes. Only one vehicle can ever enter a bunker; additional docks are ignored. Vehicles may show 'Enter' cursor but will not enter."
                continue
            }

            # --- UnitRepair ---
            set is_unit_repair [::Checks::is_true [::Checks::get_cached_property $bldg "UnitRepair"]]
            if {$is_unit_repair} {
                ::Logging::warning "Building \"$bldg\" has NumberOfDocks=$docks and UnitRepair=yes. Docking multiple vehicles simultaneously is not supported and may trigger EIP. Use NumberOfDocks=1 or omit it."
                continue
            }

            # --- DockUnload (e.g., Refineries, but Refinery already handled) ---
            set has_dock [::Checks::is_true [::Checks::get_cached_property $bldg "DockUnload"]]
            if {$has_dock} {
                # If DockUnload=yes but not a refinery, it might be a custom docking building.
                # The number of docks is hardcoded to be limited, so NumberOfDocks may not work.
                ::Logging::warning "Building \"$bldg\" has NumberOfDocks=$docks and DockUnload=yes but not Refinery=yes. The number of docks may be hardcoded; setting NumberOfDocks may not work as expected."
                continue
            }

            # --- Generic warning for any building with NumberOfDocks >=2 ---
            ::Logging::warning "Building \"$bldg\" has NumberOfDocks=$docks without Helipad=yes. This may cause issues; NumberOfDocks is intended primarily for Helipads or specific dock structures."
        }
    }
}

::Checks::register_check "validate_number_of_docks"