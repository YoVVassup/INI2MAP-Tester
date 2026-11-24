# checks/spysat_bugs.tcl
# Validates SpySat usage in BuildingTypes
# Game modes: All except Phobos (fixed in Phobos Build#49)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/SpySat
# Bugs in vanilla RA2/YR/Ares:
#   1. Not affected by Powered=yes and TogglePower
#   2. Incompatible with FogOfWar and ShroudGrow
#   3. Event 4/5 irreversibly bugged for remainder of mission
#   4. Interaction with GapGenerator leads to desync

proc ::Checks::validate_spysat_bugs {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings

    # Not applicable to Phobos (fixed in Build#49)
    if {$gamemode eq "phobos"} return

    if {![info exists buildings]} return

    # Check for FogOfWar/ShroudGrow in [General]
    set fog_of_war [::Checks::get_cached_property "General" "FogOfWar"]
    set shroud_grow [::Checks::get_cached_property "General" "ShroudGrow"]
    set has_fog [::Checks::is_true $fog_of_war]
    set has_shroud [::Checks::is_true $shroud_grow]

    foreach bldg [array names buildings] {
        set spysat [::Checks::get_cached_property $bldg "SpySat"]
        if {![::Checks::is_true $spysat]} continue

        # Warn about general SpySat bugs in vanilla
        ::Logging::notice "Building \"$bldg\" has SpySat=yes. In vanilla RA2/YR/Ares, SpySat has known bugs: not affected by Powered=yes/TogglePower, Event 4/5 irreversibly bugged for mission."

        # Warn about FogOfWar incompatibility
        if {$has_fog} {
            ::Logging::warning "Building \"$bldg\" has SpySat=yes but FogOfWar=yes is enabled. SpySat is incompatible with FogOfWar — entities may not display and effects may be overridden."
        }

        # Warn about ShroudGrow incompatibility
        if {$has_shroud} {
            ::Logging::warning "Building \"$bldg\" has SpySat=yes but ShroudGrow=yes is enabled. SpySat is incompatible with ShroudGrow — effects may be overridden unless all SpySat buildings are first turned off and re-enabled."
        }

        # Warn about GapGenerator interaction
        set gap_generator [::Checks::get_cached_property $bldg "GapGenerator"]
        if {[::Checks::is_true $gap_generator]} {
            ::Logging::warning "Building \"$bldg\" has SpySat=yes and GapGenerator=yes. Interaction between SpySat and GapGenerator leads to inconsistent shroud state and desync."
        }
    }
}

# Register this check
::Checks::register_check "validate_spysat_bugs"
