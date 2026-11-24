# checks/light_size.tcl
# Validates LightSize on ParticleSystems and errors on non-numeric values or
#   values exceeding 75, which cause EI crashes
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property

proc ::Checks::validate_light_size {} {
    upvar ::Data::particlesys particlesys

    if {![info exists particlesys]} return

    foreach {idx particle_name} [array get particlesys] {
        set light_size [::Checks::get_cached_property $particle_name "LightSize"]
        if {$light_size eq ""} continue
        if {![string is double -strict $light_size]} {
            ::Logging::error "ParticleSystem \"$particle_name\" has non-numeric LightSize: $light_size"
            continue
        }
        if {$light_size > 75} {
            ::Logging::error "ParticleSystem \"$particle_name\" has LightSize=$light_size (> 75). This will cause EI crash when the particle system is used."
        }
    }
}

# Register this check
::Checks::register_check "validate_light_size"