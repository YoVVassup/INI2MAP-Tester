# checks/trainable_agent.tcl
# Validates that Agent=yes infantry do not bypass Trainable=no restrictions
# Game modes: RA2/YR (fixed in Ares 0.2)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/Trainable
#   https://modenc.renegadeprojects.com/Agent
#
# Bug (fixed in Ares 0.2):
#   Agent infantry entering Factory-type buildings can upgrade units
#   regardless of whether those units have Trainable=no.
#   This means Trainable=no is effectively bypassed by Agent=yes.

proc ::Checks::validate_trainable_agent {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings

    # Fixed in Ares 0.2
    set is_ares [expr {$gamemode eq "ares" || $gamemode eq "phobos"}]
    if {$is_ares} return

    if {![info exists infantry]} return

    # 1. Collect Agent infantry
    set agent_infantry [list]
    foreach name [array names infantry] {
        if {[::Checks::is_true [::Checks::get_cached_property $name "Agent"]]} {
            lappend agent_infantry $name
        }
    }
    if {[llength $agent_infantry] == 0} return

    # 2. Check if any Factory-type building exists
    set has_factory 0
    if {[info exists buildings]} {
        foreach bldg [array names buildings] {
            set factory [::Checks::get_cached_property $bldg "Factory"]
            if {$factory ne "" && $factory ne "0"} {
                set has_factory 1
                break
            }
        }
    }
    if {!$has_factory} return

    # 3. Warn about Agent + Trainable interaction
    foreach agent_name $agent_infantry {
        set trainable [::Checks::get_cached_property $agent_name "Trainable"]
        if {[::Checks::is_true $trainable]} {
            ::Logging::notice "InfantryType \"$agent_name\" has Agent=yes and Trainable=yes. Agent infantry entering factories can upgrade units regardless of their Trainable setting."
        } else {
            ::Logging::warning "InfantryType \"$agent_name\" has Agent=yes. Agent infantry entering factories can upgrade units even if they have Trainable=no, bypassing the restriction."
        }
    }
}

# Register this check
::Checks::register_check "validate_trainable_agent"
