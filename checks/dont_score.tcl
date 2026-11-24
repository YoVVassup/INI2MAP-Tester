# checks/dont_score.tcl
# Validates that VehicleTypes with DontScore=yes do not persist in memory after death, preventing house defeat
# Game modes: YR
# Uses: is_true, get_cached_property

proc ::Checks::validate_dont_score {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::vehicles vehicles

    if {$gamemode ne "yr"} return
    if {![info exists vehicles]} return

    foreach veh [array names vehicles] {
        set dont_score [::Checks::get_cached_property $veh "DontScore"]
        if {![::Checks::is_true $dont_score]} continue

        ::Logging::warning "VehicleType \"$veh\" has DontScore=yes. This will cause the vehicle to persist in memory after being killed, making its owning house impossible to defeat and preventing events that check unit existence from ever being satisfied."
    }
}

# Register this check
::Checks::register_check "validate_dont_score"