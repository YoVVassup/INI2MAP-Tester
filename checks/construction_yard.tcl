# checks/construction_yard.tcl
# Validates ConstructionYard buildings - warns about Prerequisite/PrerequisiteOverride/PrerequisiteLists causing IE when building is constructed and cancelled
# Game modes: RA2/YR only (skips Ares/Phobos)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_construction_yard {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return
    if {![info exists buildings]} return

    set prereq_keys {Prerequisite PrerequisiteOverride PrerequisiteLists}

    foreach bldg [array names buildings] {
        set is_cy [::Checks::get_cached_property $bldg "ConstructionYard"]
        if {![::Checks::is_true $is_cy]} continue

        set has_prereq 0
        set found_key ""

        foreach key $prereq_keys {
            set val [::Checks::get_cached_property $bldg $key]
            if {$val ne ""} {
                set has_prereq 1
                set found_key $key
                break
            }
        }

        if {$has_prereq} {
            ::Logging::error "Building \"$bldg\" has ConstructionYard=yes and $found_key is set. This will cause an IE if the building is built and then cancelled. Construction Yards should not be buildable; they should only be deployed from vehicles."
        }
    }
}

# Register this check
::Checks::register_check "validate_construction_yard"