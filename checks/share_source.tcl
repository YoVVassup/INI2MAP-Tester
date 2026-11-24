# checks/share_source.tcl
# Validates ShareSource usage in VoxelAnims
# Game modes: All (RA2/YR/Ares/Phobos)
# Uses: ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/ShareSource
# Bug: If the TechnoType referenced by ShareSource is redefined later
#      in gamemode/map files, and the VoxelAnim is not, attempting to
#      display this anim will crash the game.

proc ::Checks::validate_share_source {} {
    upvar ::Data::rawmapdata rawmapdata
    upvar ::Data::rulesdata rulesdata

    # Check VoxelAnims in rulesdata
    foreach section {VoxelAnims} {
        if {![info exists rulesdata($section)]} continue

        foreach line $rulesdata($section) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set pfx [string trim [string range $line 0 [expr {$eq-1}]]]
            set val [string trim [string range $line [expr {$eq+1}] end]]

            # Check for ShareSource property
            if {$pfx ne "ShareSource" || $val eq "" || $val eq "none"} continue

            # Check if the referenced TechnoType is redefined in map data
            set techno_redefined 0
            foreach map_section {BuildingTypes VehicleTypes InfantryTypes AircraftTypes} {
                if {[info exists rawmapdata($map_section)]} {
                    foreach map_line $rawmapdata($map_section) {
                        set map_eq [string first "=" $map_line]
                        if {$map_eq == -1} continue
                        set map_val [string trim [string range $map_line [expr {$map_eq+1}] end]]
                        if {$map_val eq $val} {
                            set techno_redefined 1
                            break
                        }
                    }
                }
                if {$techno_redefined} break
            }

            if {$techno_redefined} {
                ::Logging::warning "VoxelAnim uses ShareSource=\"$val\" but this TechnoType is redefined in map data. If the VoxelAnim is not also redefined, attempting to display this anim will crash the game."
            }
        }
    }

    # Also check if ShareSource references a non-existent TechnoType
    # Build list of known TechnoTypes from rules
    set known_types [dict create]
    foreach section {BuildingTypes VehicleTypes InfantryTypes AircraftTypes} {
        if {[info exists rulesdata($section)]} {
            foreach line $rulesdata($section) {
                set eq [string first "=" $line]
                if {$eq == -1} continue
                set val [string trim [string range $line [expr {$eq+1}] end]]
                if {$val ne ""} {
                    dict set known_types $val 1
                }
            }
        }
    }

    # Check VoxelAnims ShareSource references
    if {[info exists rulesdata(VoxelAnims)]} {
        foreach line $rulesdata(VoxelAnims) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set pfx [string trim [string range $line 0 [expr {$eq-1}]]]
            set val [string trim [string range $line [expr {$eq+1}] end]]

            if {$pfx eq "ShareSource" && $val ne "" && $val ne "none"} {
                if {![dict exists $known_types $val]} {
                    ::Logging::warning "VoxelAnim uses ShareSource=\"$val\" but this TechnoType is not defined in rules."
                }
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_share_source"
