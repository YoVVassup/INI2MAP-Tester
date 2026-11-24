# checks/crew_flags.tcl
# Validates crew flags for all sides - checks General section flags (Technician/Engineer/AlliedCrew/SovietCrew/ThirdCrew) and per-side Crew definitions against valid InfantryTypes
# Game modes: RA2/YR only (skips Ares/Phobos)
# Uses: ::Checks::get_section_property
#
# References:
#   https://modenc.renegadeprojects.com/Technician
#
# Bugs (fixed in Ares 0.3):
#   When Technician=, Engineer=, AlliedCrew= etc. are not defined in [General],
#   the game crashes when a building is sold or destroyed.
#   - Selling: flawed [InfantryType]→Engineer=yes check runs before crew type is verified
#   - Destroying: game checks if crew type is set, then writes name to debug log regardless
#   This is NOT a cosmetic issue — missing flags cause Internal Error in vanilla RA2/YR.

proc ::Checks::validate_crew_flags {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::infantry infantry
    upvar ::Data::rawmapdata rawmapdata
    upvar ::Data::rulesdata rulesdata

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return
    if {![info exists infantry]} return

    set general_flags {Technician Engineer AlliedCrew SovietCrew ThirdCrew}
    foreach flag $general_flags {
        set value [::Checks::get_section_property "General" $flag]
        if {$value eq ""} {
            ::Logging::warning "\[General\] $flag is not defined. In vanilla RA2/YR, this causes a crash when a building is sold or destroyed (fixed in Ares 0.3). Define it to prevent Internal Error."
        } else {
            if {![info exists infantry($value)]} {
                ::Logging::error "\[General\] $flag=\"$value\" refers to non-existent InfantryType."
            }
        }
    }

    set sides_list {}
    if {[info exists rawmapdata(Sides)]} {
        foreach line $rawmapdata(Sides) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set value [string trim [string range $line [expr {$eq+1}] end]]
            if {$value ne "" && [lsearch -exact $sides_list $value] == -1} {
                lappend sides_list $value
            }
        }
    }
    if {[info exists rulesdata(Sides)]} {
        foreach line $rulesdata(Sides) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set value [string trim [string range $line [expr {$eq+1}] end]]
            if {$value ne "" && [lsearch -exact $sides_list $value] == -1} {
                lappend sides_list $value
            }
        }
    }

    set standard_sides {GDI Nod Civilian Mutant}
    if {$gamemode eq "yr"} {
        lappend standard_sides ThirdSide
    }

    foreach side $sides_list {
        if {$side in $standard_sides} continue
        set crew [::Checks::get_section_property $side "Crew"]
        if {$crew eq ""} {
            ::Logging::warning "Side \"$side\" has no Crew= defined. The side will not have a default crew infantry."
        } else {
            if {![info exists infantry($crew)]} {
                ::Logging::error "Side \"$side\" has Crew=\"$crew\" which is not a valid InfantryType."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_crew_flags"
