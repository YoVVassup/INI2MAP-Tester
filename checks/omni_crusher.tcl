# checks/omni_crusher.tcl
# Validates OmniCrusher flag requires Crusher=yes to function correctly
# Game modes: YR/Ares/Phobos (excludes RA2)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
# According to ModEnc, OmniCrusher only takes effect when Crusher=yes.
# Uses ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_omni_crusher {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::vehicles vehicles

    # This flag is only available in Yuri's Revenge and its mods (Ares/Phobos)
    if {$gamemode eq "ra2"} {
        return
    }

    if {![info exists vehicles]} {
        return
    }

    foreach veh [array names vehicles] {
        set omni_crusher [::Checks::get_cached_property $veh "OmniCrusher"]
        if {![::Checks::is_true $omni_crusher]} {
            continue
        }

        set crusher [::Checks::get_cached_property $veh "Crusher"]
        if {![::Checks::is_true $crusher]} {
            ::Logging::warning "Vehicle \"$veh\" has OmniCrusher=yes but Crusher=no (or missing). OmniCrusher only takes effect when Crusher=yes, so this vehicle will not crush objects as intended."
        }
    }
}

::Checks::register_check "validate_omni_crusher"