# checks/infantry_flags.tcl
# Validates InfantryTypes for conflicting flag combinations (Agent, Assaulter, Engineer, C4, IvanBomb) that cause crashes or broken logic
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_infantry_flags {} {
    upvar ::Data::infantry infantry
    if {![info exists infantry]} return

    foreach inf [array names infantry] {
        set agent_val    [::Checks::get_cached_property $inf "Agent"]
        set assaulter_val [::Checks::get_cached_property $inf "Assaulter"]
        set engineer_val [::Checks::get_cached_property $inf "Engineer"]
        set c4_val       [::Checks::get_cached_property $inf "C4"]
        set ivanbomb_val [::Checks::get_cached_property $inf "IvanBomb"]
        set primary      [::Checks::get_cached_property $inf "Primary"]
        set secondary    [::Checks::get_cached_property $inf "Secondary"]

        set hasAgent    [::Checks::is_true $agent_val]
        set hasAssaulter [::Checks::is_true $assaulter_val]
        set hasEngineer [::Checks::is_true $engineer_val]
        set hasC4       [::Checks::is_true $c4_val]
        set hasIvanBomb [::Checks::is_true $ivanbomb_val]
        set hasWeapon   [expr {$primary ne "" || $secondary ne ""}]

        if {$hasAgent && $hasAssaulter} {
            ::Logging::error "Infantry type \"$inf\" has both Agent=yes and Assaulter=yes. This combination is known to cause crashes (IEs)."
        }
        if {$hasAssaulter && $hasEngineer} {
            ::Logging::warning "Infantry type \"$inf\" has both Assaulter=yes and Engineer=yes. This combination breaks unit logic; it will not function as intended."
        }
        if {$hasAssaulter && !$hasC4} {
            ::Logging::warning "Infantry type \"$inf\" has Assaulter=yes but C4=no. It will not be able to clear buildings."
        }
        if {$hasAgent && $hasIvanBomb && $hasWeapon} {
            ::Logging::warning "Infantry type \"$inf\" has Agent=yes and IvanBomb=yes with a weapon. It will prefer using the weapon on buildings instead of infiltrating."
        }
        if {$hasAgent && $hasC4} {
            ::Logging::warning "Infantry type \"$inf\" has Agent=yes and C4=yes. It will prefer using C4 over infiltration, even if the building has CanC4=no."
        }
    }
}

# Register this check
::Checks::register_check "validate_infantry_flags"