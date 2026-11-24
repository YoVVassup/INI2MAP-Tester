# checks/powers_unit.tcl
# Validates PowersUnit building flag to prevent power management issues
# Game modes: YR/Ares/Phobos (excludes RA2)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Helper: get house name from a placed structure line
proc ::Checks::_pu_house_from_line {line} {
    set eq [string first "=" $line]
    if {$eq == -1} { return "" }
    set values [split [string range $line [expr {$eq+1}] end] ","]
    if {[llength $values] < 1} { return "" }
    return [string trim [lindex $values 0]]
}

proc ::Checks::validate_powers_unit {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings
    upvar ::Data::rawmapdata rawmapdata

    if {$gamemode eq "ra2"} {
        return
    }

    if {![info exists buildings]} {
        return
    }

    # Collect all buildings with PowersUnit=yes
    array set powers_buildings {}
    set powers_building_types [list]
    foreach bldg [array names buildings] {
        set powers_unit [::Checks::get_cached_property $bldg "PowersUnit"]
        if {[::Checks::is_true $powers_unit]} {
            set powers_buildings($bldg) 1
            lappend powers_building_types $bldg
        }
    }

    if {[llength $powers_building_types] == 0} {
        return
    }

    # Count how many houses own multiple PowersUnit buildings
    array set house_powers_count {}

    if {[info exists rawmapdata(Structures)]} {
        foreach line $rawmapdata(Structures) {
            set house [::Checks::_pu_house_from_line $line]
            if {$house eq ""} continue
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set values [split [string range $line [expr {$eq+1}] end] ","]
            if {[llength $values] < 2} continue
            set bldg_type [string trim [lindex $values 1]]
            if {[info exists powers_buildings($bldg_type)]} {
                incr house_powers_count($house)
            }
        }
    }

    # Warn about houses with multiple PowersUnit buildings
    foreach house [array names house_powers_count] {
        if {$house_powers_count($house) > 1} {
            ::Logging::warning "House \"$house\" owns $house_powers_count($house) buildings with PowersUnit=yes. This will cause problems: only one of them will deactivate and reactivate powered units correctly. Units powered by other centers may become permanently deactivated."
        }
    }

    # If multiple PowersUnit building types exist but not placed yet, also warn
    if {[array size powers_buildings] > 1 && [llength [array names house_powers_count]] == 0} {
        ::Logging::warning "Multiple BuildingTypes with PowersUnit=yes exist: [join $powers_building_types ", "]. If a single house owns more than one, problems will occur."
    }
}

::Checks::register_check "validate_powers_unit"