# checks/laser_fence_post.tcl
# Validates LaserFencePost flag on BuildingTypes and warns about AI base
#   overloading when listed in ConcreteWalls, and missing wall connection distance display
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Helper: determine if this building belongs to an AI-controlled house.
proc ::Checks::_lfp_is_ai_building {bldg_type} {
    if {![info exists ::Data::rawmapdata(Structures)]} {
        return 0
    }
    foreach line $::Data::rawmapdata(Structures) {
        set eq [string first "=" $line]
        if {$eq == -1} {
            continue
        }
        set values [split [string range $line [expr {$eq+1}] end] ","]
        if {[llength $values] < 2} {
            continue
        }
        set placed_type [string trim [lindex $values 1]]
        if {$placed_type ne $bldg_type} {
            continue
        }
        set house_name [string trim [lindex $values 0]]
        if {[info exists ::Data::houses($house_name)]} {
            set pc [::Checks::get_cached_property $house_name "PlayerControl"]
            if {![::Checks::is_true $pc]} {
                return 1
            }
        }
    }
    return 0
}

# Helper: check if a building type is listed in the global ConcreteWalls list.
proc ::Checks::_lfp_in_concrete_walls {bldg_type} {
    set concrete_walls ""
    if {[info exists ::Data::rulesdata(General)]} {
        foreach line $::Data::rulesdata(General) {
            if {[regexp -nocase {^ConcreteWalls\s*=\s*(.*)} $line -> val]} {
                set concrete_walls $val
                break
            }
        }
    }
    if {$concrete_walls eq "" && [info exists ::Data::rawmapdata(General)]} {
        foreach line $::Data::rawmapdata(General) {
            if {[regexp -nocase {^ConcreteWalls\s*=\s*(.*)} $line -> val]} {
                set concrete_walls $val
                break
            }
        }
    }
    if {$concrete_walls eq ""} {
        return 0
    }
    set wall_types [split $concrete_walls ","]
    foreach wt $wall_types {
        if {[string trim $wt] eq $bldg_type} {
            return 1
        }
    }
    return 0
}

proc ::Checks::validate_laser_fence_post {} {
    upvar ::Data::buildings buildings

    if {![info exists buildings]} {
        return
    }

    # Iterate over all buildings
    foreach bldg [array names buildings] {
        set lfp [::Checks::get_cached_property $bldg "LaserFencePost"]
        if {![::Checks::is_true $lfp]} {
            continue
        }

        # Check if this building is owned by the AI
        if {[::Checks::_lfp_is_ai_building $bldg]} {
            ::Logging::warning "Building \"$bldg\" has LaserFencePost=yes and belongs to an AI house. The AI may overload its base with ineffective laser fences, harming its defenses and ignoring other tags."
        }

        # Check if the building is listed in ConcreteWalls
        if {[::Checks::_lfp_in_concrete_walls $bldg]} {
            ::Logging::warning "Building \"$bldg\" has LaserFencePost=yes and is listed in \[General\] ConcreteWalls. This may cause the AI to spam laser fences at the expense of other structures."
        }

        # Additional warning for wall-type buildings (the game does not display the connection distance)
        set is_wall [::Checks::is_true [::Checks::get_cached_property $bldg "Wall"]]
        if {!$is_wall} {
            set foundation [::Checks::get_cached_property $bldg "Foundation"]
            if {$foundation ne "" && $foundation ne "0x0"} {
                set is_wall 1
            }
        }
        if {$is_wall} {
            ::Logging::notice "Building \"$bldg\" has LaserFencePost=yes and is a wall-type building. The game will not display the number of cells between which a new wall can be connected."
        }
    }
}

::Checks::register_check "validate_laser_fence_post"