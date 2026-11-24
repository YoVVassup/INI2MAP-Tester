# checks/thief_guard_mode.tcl
# Validates that InfantryTypes with Thief=yes can still enter guard mode
# Game modes: YR/Ares/Phobos (not RA2)
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/Thief
#
# Bug:
#   In Yuri's Revenge, if Thief=yes is set on an InfantryType, that unit
#   will be unable to enter guard mode. For example, an Attack Dog with
#   Thief=yes cannot detect and attack disguised enemy units automatically.
#   This is engine behavior in YR and later.

proc ::Checks::validate_thief_guard_mode {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::infantry infantry

    # Only applicable to YR and later (not RA2)
    if {$gamemode eq "ra2"} return
    if {![info exists infantry]} return

    foreach name [array names infantry] {
        set thief [::Checks::get_cached_property $name "Thief"]
        if {[string tolower $thief] eq "yes"} {
            ::Logging::warning "InfantryType \"$name\" has Thief=yes. In YR and later, this prevents the unit from entering guard mode — it cannot automatically detect or attack disguised enemies."
        }
    }
}

# Register this check
::Checks::register_check "validate_thief_guard_mode"
