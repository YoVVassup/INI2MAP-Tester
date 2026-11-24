# checks/hospital.tcl
# Validates buildings with Hospital=yes combined with Factory=yes on the map; warns about AI unit spam for AI-owned houses
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_hospital {} {
    upvar ::Data::buildings buildings
    upvar ::Data::rawmapdata rawmapdata
    upvar ::Data::houses houses

    if {![info exists buildings] || ![info exists rawmapdata(Structures)]} {
        return
    }

    # Determine which houses are AI-controlled (PlayerControl=no or not explicitly yes)
    array set ai_house {}
    foreach house [array names houses] {
        set pc [::Checks::get_cached_property $house "PlayerControl"]
        # If PlayerControl is explicitly set to yes -> human player, otherwise AI
        if {[::Checks::is_true $pc]} {
            set ai_house($house) 0
        } else {
            set ai_house($house) 1
        }
    }

    # Iterate over placed structures on the map
    foreach line $::Data::rawmapdata(Structures) {
        set kv [::util::_parse_keyval $line]
        if {$kv eq ""} continue
        set idx [lindex $kv 0]
        set fields [split [lindex $kv 1] ","]
        if {[llength $fields] < 17} continue
        set house [lindex $fields 0]
        set bldg_type [lindex $fields 1]

        # Check if the building type exists and has Hospital+Factory
        if {![info exists buildings($bldg_type)]} continue
        set hospital [::Checks::get_cached_property $bldg_type "Hospital"]
        if {![::Checks::is_true $hospital]} continue
        set factory [::Checks::get_cached_property $bldg_type "Factory"]
        if {$factory ne "UnitType" && $factory ne "InfantryType"} continue

        # Check if the building belongs to an AI house
        if {[info exists ai_house($house)] && $ai_house($house) == 1} {
            ::Logging::warning "Building \"$bldg_type\" at index $idx belongs to AI house \"$house\" and has Hospital=yes with Factory=$factory. This causes the AI to spam only one type of unit from this factory (the first buildable $factory type that the AI house owns)."
        } elseif {![info exists ai_house($house)]} {
            # House not found (unlikely, but warn anyway)
            ::Logging::warning "Building \"$bldg_type\" at index $idx has unknown house \"$house\". Hospital=yes + Factory=$factory may cause AI spam if this house is AI-controlled."
        }
    }
}

::Checks::register_check "validate_hospital"