# checks/prerequisite_override.tcl
# Validates that PrerequisiteOverride does not contain multiple values
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/The_Prerequisite_System
#
# Bug:
#   PrerequisiteOverride= is NOT cumulative like Prerequisite=.
#   Only ONE building activates production. If multiple buildings are
#   specified (comma-separated), only the first is used. The rest are
#   silently ignored, which is rarely the intended behavior.

proc ::Checks::validate_prerequisite_override {} {
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings

    set all_types [list]
    if {[info exists infantry]} {
        foreach n [array names infantry] { lappend all_types $n }
    }
    if {[info exists vehicles]} {
        foreach n [array names vehicles] { lappend all_types $n }
    }
    if {[info exists aircraft]} {
        foreach n [array names aircraft] { lappend all_types $n }
    }
    if {[info exists buildings]} {
        foreach n [array names buildings] { lappend all_types $n }
    }

    foreach name $all_types {
        set poverride [::Checks::get_cached_property $name "PrerequisiteOverride"]
        if {$poverride eq ""} continue

        set items [split $poverride ","]
        if {[llength $items] > 1} {
            set clean [list]
            foreach item $items {
                set trimmed [string trim $item]
                if {$trimmed ne ""} { lappend clean $trimmed }
            }
            if {[llength $clean] > 1} {
                ::Logging::warning "TechnoType \"$name\" has PrerequisiteOverride=\"$poverride\" with [llength $clean] entries. PrerequisiteOverride only accepts ONE building — the rest will be silently ignored. Use Prerequisite= for cumulative requirements."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_prerequisite_override"
