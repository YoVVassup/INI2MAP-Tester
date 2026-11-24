# checks/damage_particle_systems_infantry.tcl
# Validates that Cyborg=yes InfantryTypes have DamageParticleSystems defined to avoid disabled spark particles
# Game modes: RA2/YR/Ares/Phobos
# Uses: is_true, get_cached_property

proc ::Checks::validate_damage_particle_systems_infantry {} {
    upvar ::Data::rawmapdata rawmapdata
    upvar ::Data::infantry infantry

    if {![info exists infantry]} return

    foreach inf [array names infantry] {
        set cyborg [::Checks::get_cached_property $inf "Cyborg"]
        if {![::Checks::is_true $cyborg]} continue

        set dps_from_map ""
        if {[info exists rawmapdata($inf)]} {
            foreach line $rawmapdata($inf) {
                set eq [string first "=" $line]
                if {$eq == -1} continue
                set k [string trim [string range $line 0 [expr {$eq-1}]]]
                if {$k eq "DamageParticleSystems"} {
                    set dps_from_map [string trim [string range $line [expr {$eq+1}] end]]
                    break
                }
            }
        }

        if {$dps_from_map eq ""} {
            ::Logging::warning "Infantry type \"$inf\" has Cyborg=yes but its map section does not contain 'DamageParticleSystems'. Spark damage particles will be disabled unless a section with this flag is added to the map. (This is hardcoded behavior.)"
        }
    }
}

# Register this check
::Checks::register_check "validate_damage_particle_systems_infantry"