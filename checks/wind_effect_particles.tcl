# checks/wind_effect_particles.tcl
# Validates WindEffect on ParticleTypes does not exceed 10
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/WindEffect
#
# Bug:
#   If WindEffect > 10, the modulus operation will divide by 0,
#   triggering EIP#0062D2E8 crash.

proc ::Checks::validate_wind_effect_particles {} {
    upvar ::Data::particlesys particlesys

    if {![info exists particlesys]} return

    foreach {idx ps_name} [array get particlesys] {
        set we [::Checks::get_cached_property $ps_name "WindEffect"]
        if {$we eq ""} continue

        if {$we > 10} {
            ::Logging::error "ParticleSystem \"$ps_name\" has WindEffect=$we. Values greater than 10 cause a divide-by-zero crash (EIP#0062D2E8). Maximum safe value is 10."
        }
    }
}

# Register this check
::Checks::register_check "validate_wind_effect_particles"
