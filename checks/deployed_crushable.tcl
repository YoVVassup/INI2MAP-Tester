# checks/deployed_crushable.tcl
# Validates that InfantryTypes with DeployedCrushable=yes do not have Crushable=no, which would make the flag ineffective
# Game modes: RA2/YR/Ares/Phobos
# Uses: is_true, get_cached_property

proc ::Checks::validate_deployed_crushable {} {
    upvar ::Data::infantry infantry

    if {![info exists infantry]} return

    foreach inf [array names infantry] {
        set depCrush [::Checks::get_cached_property $inf "DeployedCrushable"]
        if {$depCrush eq ""} continue

        set crushable [::Checks::get_cached_property $inf "Crushable"]
        set crushYes [expr {$crushable eq "" || [::Checks::is_true $crushable]}]

        if {[::Checks::is_true $depCrush]} {
            if {!$crushYes} {
                ::Logging::warning "InfantryType \"$inf\" has DeployedCrushable=yes but Crushable=no. The unit cannot be crushed by Crusher=yes units regardless of deployed state."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_deployed_crushable"