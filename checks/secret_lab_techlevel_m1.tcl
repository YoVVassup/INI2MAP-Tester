# checks/secret_lab_techlevel_m1.tcl
# Validates that TechnoTypes with TechLevel=-1 in SecretLab bonus pool won't freeze
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/TechLevel
#   https://modenc.renegadeprojects.com/SecretLab
#
# Bug:
#   If a BuildingType has SecretLab=yes and TechnoTypes with TechLevel=-1
#   are in the bonus pool (SecretInfantry/SecretUnits/SecretBuildings),
#   purchasing them causes the download to freeze at 50%.

proc ::Checks::validate_secret_lab_techlevel_m1 {} {
    upvar ::Data::buildings buildings
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft

    if {![info exists buildings]} return

    # 1. Check if any building has SecretLab=yes
    set has_secret_lab 0
    foreach bldg [array names buildings] {
        if {[::Checks::is_true [::Checks::get_cached_property $bldg "SecretLab"]]} {
            set has_secret_lab 1
            break
        }
    }
    if {!$has_secret_lab} return

    # 2. Collect SecretLab bonus pool from [General]
    set bonus_pool [dict create]
    foreach key {SecretInfantry SecretUnits SecretBuildings} {
        set val [::Checks::get_section_property "General" $key]
        if {$val eq "" || $val eq "none"} continue
        foreach item [split $val ","] {
            set item [string trim $item]
            if {$item ne ""} {
                dict set bonus_pool $item 1
            }
        }
    }
    if {[dict size $bonus_pool] == 0} return

    # 3. Check TechnoTypes with TechLevel=-1 that are IN the bonus pool
    set m1_types [list]

    if {[info exists infantry]} {
        foreach name [array names infantry] {
            if {![dict exists $bonus_pool $name]} continue
            set tl [::Checks::get_cached_property $name "TechLevel"]
            if {$tl eq "-1"} {
                lappend m1_types "InfantryType \"$name\""
            }
        }
    }
    if {[info exists vehicles]} {
        foreach name [array names vehicles] {
            if {![dict exists $bonus_pool $name]} continue
            set tl [::Checks::get_cached_property $name "TechLevel"]
            if {$tl eq "-1"} {
                lappend m1_types "VehicleType \"$name\""
            }
        }
    }
    if {[info exists aircraft]} {
        foreach name [array names aircraft] {
            if {![dict exists $bonus_pool $name]} continue
            set tl [::Checks::get_cached_property $name "TechLevel"]
            if {$tl eq "-1"} {
                lappend m1_types "AircraftType \"$name\""
            }
        }
    }

    if {[llength $m1_types] == 0} return

    # 4. Warn for each TechnoType with TechLevel=-1 in bonus pool
    foreach type_str $m1_types {
        ::Logging::warning "$type_str has TechLevel=-1 and is in the SecretLab bonus pool. Purchasing TechLevel=-1 types from a SecretLab causes the download to freeze at 50%. Remove the type from SecretInfantry/SecretUnits/SecretBuildings or change its TechLevel."
    }
}

# Register this check
::Checks::register_check "validate_secret_lab_techlevel_m1"
