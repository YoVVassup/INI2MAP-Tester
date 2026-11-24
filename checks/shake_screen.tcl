# checks/shake_screen.tcl
# Validates ShakeScreen value in [AudioVisual]
# Game modes: RA2/YR
# Uses: ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/ShakeScreen
# Bug: A value of 0 will trigger EIP#00441C28 (division by zero crash)
# Note: ShakeScreen is obsolete in RA2/YR (no visual effect), but the
#       division calculation still exists in the game code.

proc ::Checks::validate_shake_screen {} {
    upvar ::Data::gamemode gamemode

    # Only applicable to RA2 and YR
    if {$gamemode ne "ra2" && $gamemode ne "yr"} return

    # Get the value from [AudioVisual]
    set val [::Checks::get_cached_property "AudioVisual" "ShakeScreen"]
    if {$val eq ""} return

    # Check for 0 value (causes crash)
    if {$val eq "0"} {
        ::Logging::error "ShakeScreen=0 in \[AudioVisual\] will cause EIP crash (division by zero)."
        return
    }

    # Check for non-numeric value
    if {![string is integer -strict $val]} {
        ::Logging::warning "ShakeScreen=\"$val\" in \[AudioVisual\] is not a valid integer."
        return
    }
}

# Register this check
::Checks::register_check "validate_shake_screen"
