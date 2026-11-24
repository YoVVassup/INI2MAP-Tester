# checks/dig.tcl
# Validates that [AudioVisual] Dig references a valid Animation to prevent IE on dig triggers
# Game modes: RA2/YR/Ares/Phobos
# Uses: get_section_property

proc ::Checks::validate_dig {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::anims anims

    set dig [::Checks::get_section_property "AudioVisual" "Dig"]
    if {$dig eq ""} return

    if {![info exists anims($dig)]} {
        if {$gamemode eq "ra2"} {
            ::Logging::warning "\[AudioVisual\] Dig=$dig is set but the referenced Animation '$dig' does not exist. In RA2 this flag is not normally used and will cause an IE if triggered."
        } elseif {$gamemode eq "yr"} {
            ::Logging::warning "\[AudioVisual\] Dig=$dig is set but the referenced Animation '$dig' does not exist. This may cause an IE when a VehicleType with Dig=yes attempts to play it."
        } elseif {$gamemode eq "ares" || $gamemode eq "phobos"} {
            ::Logging::error "\[AudioVisual\] Dig=$dig is set but the referenced Animation '$dig' does not exist. This will cause an IE when a VehicleType with Dig=yes attempts to play it."
        }
    }
}

# Register this check
::Checks::register_check "validate_dig"