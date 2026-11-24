# checks/temporal_particle.tcl
# Validates that Warheads with Temporal=yes do not rely on Particle system
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/Temporal
#
# Bug:
#   When a Warhead has Temporal=yes, the Particle system is disabled for any
#   weapon using that warhead. Particle effects (trails, impacts, ambient)
#   will not render. This is engine behavior, not a crash.

proc ::Checks::validate_temporal_particle {} {
    upvar ::Data::warheads warheads
    upvar ::Data::weapons weapons

    if {![info exists warheads]} return

    # Collect all warheads with Temporal=yes
    array set temporal_warheads {}
    foreach {idx wh_name} [array get warheads] {
        set temporal [::Checks::get_cached_property $wh_name "Temporal"]
        if {[string tolower $temporal] eq "yes"} {
            set temporal_warheads($wh_name) 1
        }
    }

    if {[array size temporal_warheads] == 0} return

    # Find weapons using temporal warheads that have Particle set
    if {[info exists weapons]} {
        foreach {idx wep_name} [array get weapons] {
            set wh [::Checks::get_cached_property $wep_name "Warhead"]
            if {$wh eq "" || ![info exists temporal_warheads($wh)]} continue

            set particle [::Checks::get_cached_property $wep_name "Particle"]
            if {$particle ne ""} {
                ::Logging::warning "Weapon \"$wep_name\" uses Temporal warhead \"$wh\" but has Particle=\"$particle\". Temporal=yes disables the Particle system — this effect will not render."
            }
        }
    }

    # Warn about all temporal warheads (particle system is always disabled)
    foreach wh_name [array names temporal_warheads] {
        ::Logging::notice "Warhead \"$wh_name\" has Temporal=yes. The Particle system will be disabled for any weapon using this warhead."
    }

    array unset temporal_warheads
}

# Register this check
::Checks::register_check "validate_temporal_particle"
