# checks/repairable.tcl
# Validates Repairable flag conflict with Capturable=yes
# Game modes: RA2/YR/Ares/Phobos (all)
# Uses: ::Checks::is_false, ::Checks::is_true, ::Checks::get_cached_property
# because engineers will be unable to enter and repair/capture it.
# Based on ModEnc: "If it has Repairable=no set, the building will not be able
# to be repaired by either of these methods" (ClickRepairable page).
# Uses ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_repairable {} {
    upvar ::Data::buildings buildings

    if {![info exists buildings]} {
        return
    }

    foreach bldg [array names buildings] {
        set repairable [::Checks::get_cached_property $bldg "Repairable"]
        # If Repairable is not explicitly set to "no", skip
        if {![::Checks::is_false $repairable]} {
            continue
        }

        set capturable [::Checks::get_cached_property $bldg "Capturable"]
        if {[::Checks::is_true $capturable]} {
            ::Logging::warning "Building \"$bldg\" has Repairable=no but also Capturable=yes. Engineers will be unable to enter or repair/capture this building."
        }
    }
}

::Checks::register_check "validate_repairable"