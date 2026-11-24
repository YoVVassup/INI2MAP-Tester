# checks/next_particle.tcl
# Validates NextParticle flag to prevent EIP when combined with BehavesLike=Smoke
# Game modes: RA2/YR/Ares/Phobos (all)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::_np_check {obj_name} {
    set next_particle [::Checks::get_cached_property $obj_name "NextParticle"]
    if {$next_particle eq ""} {
        return
    }
    set behaves_like [::Checks::get_cached_property $obj_name "BehavesLike"]
    if {[string equal -nocase $behaves_like "Smoke"]} {
        ::Logging::warning "Particle/System \"$obj_name\" has NextParticle=$next_particle and BehavesLike=Smoke. This combination can cause EIP. Avoid NextParticle on smoke-type particles."
    }
}

proc ::Checks::validate_next_particle {} {
    upvar ::Data::particles particles
    upvar ::Data::particlesys particlesys

    if {[info exists particles]} {
        foreach {idx name} [array get particles] {
            ::Checks::_np_check $name
        }
    }

    if {[info exists particlesys]} {
        foreach {idx name} [array get particlesys] {
            ::Checks::_np_check $name
        }
    }
}

::Checks::register_check "validate_next_particle"