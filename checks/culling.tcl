# checks/culling.tcl
# Validates Culling warhead flag - warns that Culling=yes prevents the warhead from killing any InfantryType objects
# Game modes: RA2/YR/Ares/Phobos (all modes - no gamemode check)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_culling {} {
    upvar ::Data::warheads warheads
    if {![info exists warheads]} return

    foreach {idx wh} [array get warheads] {
        set culling [::Checks::get_cached_property $wh "Culling"]
        if {[::Checks::is_true $culling]} {
            ::Logging::warning "Warhead \"$wh\" has Culling=yes. This flag prevents the warhead from killing any infantry (InfantryType objects)."
        }
    }
}

# Register this check
::Checks::register_check "validate_culling"