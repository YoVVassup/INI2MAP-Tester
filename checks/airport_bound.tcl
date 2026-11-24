# checks/airport_bound.tcl
# Validates that buildable AircraftTypes do not use AirportBound=no, which causes selectability bugs and ignored Stop commands
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_airport_bound {} {
    upvar ::Data::aircraft aircraft

    if {![info exists aircraft]} return

    foreach type [array names aircraft] {
        set bound [::Checks::get_cached_property $type "AirportBound"]
        if {$bound eq ""} { set bound yes }
        if {[::Checks::is_true $bound]} continue

        set factory [::Checks::get_cached_property $type "Factory"]
        set buildcat [::Checks::get_cached_property $type "BuildCat"]
        set buildable [expr {$factory ne "" || $buildcat ne ""}]

        if {$buildable} {
            ::Logging::warning "AircraftType \"$type\" is buildable and AirportBound=no. It will not be selectable after being produced until it has taken off at least once. Also, aircraft may remember attack targets and cannot be stopped (Stop command ignored). Consider using convert‑logic (e.g., Ares/Phobos) to spawn a regular aircraft that converts after take‑off."
        } else {
            ::Logging::warning "AircraftType \"$type\" has AirportBound=no. It may remember attack targets, cannot be stopped, and if ever produced from a factory, it will suffer from the selectability bug."
        }
    }
}

# Register this check
::Checks::register_check "validate_airport_bound"