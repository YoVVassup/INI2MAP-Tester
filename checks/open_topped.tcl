# checks/open_topped.tcl
# Validates OpenTopped flag on buildings to prevent infantry attacking their own building
# Game modes: YR/Ares/Phobos (excludes RA2)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
# exiting the building to attack it.
# Uses ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_open_topped {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    # OpenTopped on buildings is only relevant for Yuri's Revenge and its mods
    if {$gamemode eq "ra2"} {
        return
    }

    if {![info exists buildings]} {
        return
    }

    foreach bldg [array names buildings] {
        set open_topped [::Checks::get_cached_property $bldg "OpenTopped"]
        if {[::Checks::is_true $open_topped]} {
            ::Logging::warning "Building \"$bldg\" has OpenTopped=yes. This will cause infantry exiting this building to attack it, trying to occupy its central cell."
        }
    }
}

::Checks::register_check "validate_open_topped"