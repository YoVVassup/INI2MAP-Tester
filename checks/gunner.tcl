# checks/gunner.tcl
# Validates VehicleTypes with Gunner=yes for compatibility with OpenTopped; warns about Temporal weapon crash risk
# Game modes: RA2/YR
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_gunner {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::vehicles vehicles

    if {$gamemode ne "ra2" && $gamemode ne "yr"} return
    if {![info exists vehicles]} return

    foreach veh [array names vehicles] {
        set gunner [::Checks::get_cached_property $veh "Gunner"]
        if {![::Checks::is_true $gunner]} continue

        set open_topped [::Checks::get_cached_property $veh "OpenTopped"]
        if {[::Checks::is_true $open_topped]} {
            ::Logging::warning "VehicleType \"$veh\" has both Gunner=yes and OpenTopped=yes. If a passenger carries a Temporal=yes weapon, it may lose its Temporal device (used by the vehicle) and crash the game when it tries to fire."
        }
    }
}

# Register this check
::Checks::register_check "validate_gunner"