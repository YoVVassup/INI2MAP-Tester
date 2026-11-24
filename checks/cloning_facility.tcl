# checks/cloning_facility.tcl
# Validates CloningFacility flag - warns about WeaponsFactory conflict causing AI production spam and cloned vehicles getting stuck inside the building
# Game modes: RA2/YR/Ares (skips Phobos)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_cloning_facility {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    if {$gamemode eq "phobos"} return
    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set is_cloning [::Checks::get_cached_property $bldg "CloningFacility"]
        if {![::Checks::is_true $is_cloning]} continue

        set weapons_factory [::Checks::get_cached_property $bldg "WeaponsFactory"]
        if {[::Checks::is_true $weapons_factory]} {
            ::Logging::warning "Building \"$bldg\" has CloningFacility=yes and WeaponsFactory=yes. AI may spam production, and cloned vehicles can get stuck inside the building."
        }
    }
}

# Register this check
::Checks::register_check "validate_cloning_facility"