# checks/cloning.tcl
# Validates Cloning flag - warns when combined with Refinery=yes which permanently blocks infantry production after BuildLimit units are produced
# Game modes: RA2/YR/Ares/Phobos (all modes - no gamemode check)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_cloning {} {
    upvar ::Data::buildings buildings

    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set cloning [::Checks::get_cached_property $bldg "Cloning"]
        if {![::Checks::is_true $cloning]} continue

        set refinery [::Checks::get_cached_property $bldg "Refinery"]
        if {[::Checks::is_true $refinery]} {
            ::Logging::error "Building \"$bldg\" has both Cloning=yes and Refinery=yes. Once any infantry with BuildLimit is produced, they will never be buildable again (like BuildLimit=-1). Infantry icons remain visible but production is permanently blocked."
        }
    }
}

# Register this check
::Checks::register_check "validate_cloning"