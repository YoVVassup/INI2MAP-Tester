# checks/guard_range.tcl
# Validates that GuardRange values do not exceed the hard upper limit of 16 cells on techno types
# Game modes: RA2/YR/Ares
# Uses: get_cached_property, get_all_techno_types

proc ::Checks::validate_guard_range {} {
    if {$::Data::gamemode ne "ra2" && $::Data::gamemode ne "yr" && $::Data::gamemode ne "ares"} return

    set all_types [::Checks::get_all_techno_types]
    if {[info exists ::Data::buildings]} { foreach n [array names ::Data::buildings] { lappend all_types $n } }

    foreach type $all_types {
        set guard_range [::Checks::get_cached_property $type "GuardRange"]
        if {$guard_range eq ""} continue

        if {[string is integer -strict $guard_range] && $guard_range > $::Constants::MAX_GUARD_RANGE} {
            ::Logging::warning "Type \"$type\" has GuardRange=$guard_range (> $::Constants::MAX_GUARD_RANGE). There is a hard upper limit of $::Constants::MAX_GUARD_RANGE cells; values above are ignored."
        }
    }
}

# Register this check
::Checks::register_check "validate_guard_range"