# checks/auxbuilding_superweapons.tcl
# Validates that SuperWeaponTypes AuxBuilding references a valid BuildingType and warns that upgrade buildings can bypass AuxBuilding requirements in RA2/YR
# Game modes: RA2/YR
# Uses: ::Checks::get_cached_property, ::Checks::get_section_property

proc ::Checks::validate_auxbuilding_superweapons {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::rawmapdata rawmapdata
    upvar ::Data::rulesdata rulesdata
    upvar ::Data::buildings buildings

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return

    set sw_list [list]
    if {[info exists rulesdata(SuperWeaponTypes)]} {
        foreach line $rulesdata(SuperWeaponTypes) {
            set eq [string first "=" $line]
            if {$eq != -1} {
                lappend sw_list [string trim [string range $line [expr {$eq+1}] end]]
            }
        }
    }
    if {[info exists rawmapdata(SuperWeaponTypes)]} {
        foreach line $rawmapdata(SuperWeaponTypes) {
            set eq [string first "=" $line]
            if {$eq != -1} {
                lappend sw_list [string trim [string range $line [expr {$eq+1}] end]]
            }
        }
    }
    set sw_list [lsort -unique $sw_list]
    if {![llength $sw_list]} return

    set warned_sw [list]
    foreach sw $sw_list {
        set aux [::Checks::get_cached_property $sw "AuxBuilding"]
        if {$aux eq ""} continue
        if {![info exists buildings($aux)]} {
            ::Logging::warning "SuperWeapon \"$sw\" has AuxBuilding \"$aux\" which is not a valid BuildingType."
        }
        lappend warned_sw $sw
    }

    if {[llength $warned_sw] > 0} {
        set sw_str [join $warned_sw ", "]
        ::Logging::warning "SuperWeapon(s) with AuxBuilding: $sw_str. The AuxBuilding requirement is ignored if the super weapon is granted by an upgrade building (a building obtained through upgrade from another). In RA2/YR this can allow unintended access."
    }
}

# Register this check
::Checks::register_check "validate_auxbuilding_superweapons"