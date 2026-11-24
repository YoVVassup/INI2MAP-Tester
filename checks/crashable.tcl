# checks/crashable.tcl
# Validates Crashable flag - warns about non-crashable Jumpjet units remaining on ground after destruction, and Hover units becoming invulnerable and deselecting on click
# Game modes: RA2/YR/Ares/Phobos (all modes - no gamemode check)
# Uses: ::Checks::is_true, ::Checks::get_cached_property, ::Checks::get_all_techno_types

proc ::Checks::validate_crashable {} {
    upvar ::Data::gamemode gamemode
    set all_types [::Checks::get_all_techno_types]
    set is_ares [expr {$gamemode eq "ares" || $gamemode eq "phobos"}]
    foreach type $all_types {
        set crashable [::Checks::get_cached_property $type "Crashable"]
        if {$crashable eq ""} { set crashable yes }
        if {[::Checks::is_true $crashable]} continue

        set locomotor [::Checks::get_cached_property $type "Locomotor"]

        if {[string match "*{92612C46-F71F-11d1-AC9F-006008055BB5}*" $locomotor]} {
            if {$is_ares} {
                ::Logging::notice "Type \"$type\" has Crashable=no and Locomotor=Jumpjet. In Ares, units killed by weapons will explode mid-air, but loss of spawner/helipad still causes a crash."
            } else {
                ::Logging::warning "Type \"$type\" has Crashable=no and Locomotor=Jumpjet. After destruction it will remain on the ground and not function properly."
            }
        }

        if {[string match "*{4A582742-9839-11d1-B709-00A024DDAFD1}*" $locomotor]} {
            ::Logging::warning "Type \"$type\" has Crashable=no and Locomotor=Hover. The unit may become invulnerable, still granting experience, and when selected it will be deselected immediately. This also affects units in the air (paradrop etc.)."
        }
    }
}

# Register this check
::Checks::register_check "validate_crashable"