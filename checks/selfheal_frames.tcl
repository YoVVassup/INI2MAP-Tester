# checks/selfheal_frames.tcl
# Validates SelfHealInfantryFrames and SelfHealUnitFrames values in [General]
# Game modes: YR/Ares/Phobos (not RA2)
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/SelfHealInfantryFrames
#   https://modenc.renegadeprojects.com/SelfHealUnitFrames
#
# Bugs:
#   SelfHealInfantryFrames=0 → EIP#0070A549 (crash), default: 50
#   SelfHealUnitFrames=0 → EIP#0070A5B5 (crash), default: 75
#   Values <= 5 cause Pip grayscale flicker effect during healing

proc ::Checks::validate_selfheal_frames {} {
    upvar ::Data::gamemode gamemode

    # Only applicable to YR and later (not RA2)
    if {$gamemode eq "ra2"} return

    # Check SelfHealInfantryFrames
    set infantry_val [::Checks::get_cached_property "General" "SelfHealInfantryFrames"]
    if {$infantry_val ne ""} {
        if {$infantry_val eq "0"} {
            ::Logging::error "SelfHealInfantryFrames=0 in \[General\] will cause EIP crash. Default value is 50."
        } elseif {![string is integer -strict $infantry_val]} {
            ::Logging::warning "SelfHealInfantryFrames=\"$infantry_val\" in \[General\] is not a valid integer."
        } elseif {$infantry_val > 0 && $infantry_val <= 5} {
            ::Logging::warning "SelfHealInfantryFrames=$infantry_val in \[General\] will cause Pip grayscale flicker during healing. Recommended: >5 (default: 50)."
        }
    }

    # Check SelfHealUnitFrames
    set unit_val [::Checks::get_cached_property "General" "SelfHealUnitFrames"]
    if {$unit_val ne ""} {
        if {$unit_val eq "0"} {
            ::Logging::error "SelfHealUnitFrames=0 in \[General\] will cause EIP crash. Default value is 75."
        } elseif {![string is integer -strict $unit_val]} {
            ::Logging::warning "SelfHealUnitFrames=\"$unit_val\" in \[General\] is not a valid integer."
        } elseif {$unit_val > 0 && $unit_val <= 5} {
            ::Logging::warning "SelfHealUnitFrames=$unit_val in \[General\] will cause Pip grayscale flicker during healing. Recommended: >5 (default: 75)."
        }
    }
}

# Register this check
::Checks::register_check "validate_selfheal_frames"
