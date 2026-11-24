# checks/attach_effects.tcl
# Validates AttachEffect.Animation and AttachEffect.Beacon references point to defined Animations or ParticleSystems, and flags their use outside Ares/Phobos where they are unsupported
# Game modes: RA2/YR/Ares/Phobos (AttachEffect validation only applies to Ares/Phobos)
# Uses: ::Checks::get_cached_property, ::Checks::get_all_techno_types

proc ::Checks::validate_attach_effects {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::anims anims
    upvar ::Data::particlesys particlesys
    upvar ::Data::buildings buildings

    set all_types [::Checks::get_all_techno_types]

    foreach type_name $all_types {
        set has_ae 0
        set anim_name   [::Checks::get_cached_property $type_name "AttachEffect.Animation"]
        set beacon_name [::Checks::get_cached_property $type_name "AttachEffect.Beacon"]
        set ae_general  [::Checks::get_cached_property $type_name "AttachEffect"]
        if {$anim_name ne "" || $beacon_name ne "" || $ae_general ne ""} {
            set has_ae 1
        }

        if {!$has_ae} continue

        if {$gamemode ne "ares" && $gamemode ne "phobos"} {
            ::Logging::warning "Type \"$type_name\" uses AttachEffect tags but gamemode is $gamemode (requires Ares/Phobos). These effects will be ignored."
            continue
        }

        if {$anim_name ne ""} {
            # AttachEffect.Animation can be either an Animation or a ParticleSystem
            if {![info exists anims($anim_name)] && ![info exists particlesys($anim_name)]} {
                ::Logging::warning "Type \"$type_name\" uses AttachEffect.Animation \"$anim_name\" which is not defined as Animation or ParticleSystem."
            }
        }
        if {$beacon_name ne ""} {
            # Beacon must be an Animation
            if {![info exists anims($beacon_name)]} {
                ::Logging::warning "Type \"$type_name\" uses AttachEffect.Beacon \"$beacon_name\" which is not defined as Animation."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_attach_effects"