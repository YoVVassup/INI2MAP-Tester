# checks/powered_unit.tcl
# Validates PoweredUnit flag on vehicles with incompatible locomotors
# Game modes: YR/Ares/Phobos (excludes RA2)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
# that ignore this flag:
#   - Rocket (CLSID {B7B49766-E576-11d3-9BD9-00104B972FE8})
#   - Ballistic (CLSID {4A582746-9839-11d1-B709-00A024DDAFD1})
#   - Jumpjet (CLSID {92612C46-F71F-11d1-AC9F-006008055BB5}) only when Naval=yes
# Uses ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_powered_unit {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::vehicles vehicles

    # PoweredUnit exists in YR and its mods (Ares/Phobos), not in RA2
    if {$gamemode eq "ra2"} {
        return
    }

    if {![info exists vehicles]} {
        return
    }

    # CLSIDs of locomotor types that ignore PoweredUnit
    set locomotor_rocket   "{B7B49766-E576-11d3-9BD9-00104B972FE8}"
    set locomotor_ballistic "{4A582746-9839-11d1-B709-00A024DDAFD1}"
    set locomotor_jumpjet   "{92612C46-F71F-11d1-AC9F-006008055BB5}"

    foreach veh [array names vehicles] {
        set powered_unit [::Checks::get_cached_property $veh "PoweredUnit"]
        if {![::Checks::is_true $powered_unit]} {
            continue
        }

        set locomotor [::Checks::get_cached_property $veh "Locomotor"]
        set ignore 0
        set reason ""

        if {[string match $locomotor_rocket $locomotor]} {
            set ignore 1
            set reason "Rocket locomotor"
        } elseif {[string match $locomotor_ballistic $locomotor]} {
            set ignore 1
            set reason "Ballistic locomotor"
        } elseif {[string match $locomotor_jumpjet $locomotor]} {
            # For Jumpjet, check Naval flag
            set naval [::Checks::is_true [::Checks::get_cached_property $veh "Naval"]]
            if {$naval} {
                set ignore 1
                set reason "Jumpjet locomotor with Naval=yes (floating units)"
            }
        }

        if {$ignore} {
            ::Logging::warning "Vehicle \"$veh\" has PoweredUnit=yes but uses $reason, which ignores this flag. The unit will not behave as a powered unit."
        }
    }
}

::Checks::register_check "validate_powered_unit"