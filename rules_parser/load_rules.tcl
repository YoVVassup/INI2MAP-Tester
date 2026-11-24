#----------------------------------------------------------------------------------------------------------
# rules_parser/load_rules.tcl - Parse rulesmo.enc (main game rules)
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Rules::load_rules_loaded]} { return }
set ::Rules::load_rules_loaded 1

# --- Rules Parser ---
# Parse rulesmo.enc and populate all game-data arrays (units, buildings, weapons, etc.).
proc ::Rules::load_rules {filepath} {
    set content [::Rules::_load_ini $filepath]

    set lines [split $content "\n"]
    set cmode 0
    set curtag ""
    set var_idx 0
    set idx 0
    set country_count 0

    foreach arr {infantry vehicles aircraft buildings vanims anims ianims particles particlesys
        terrains smudges countries superweapons weapons globalvars
        owners art paddies harvy agent assaulter engineer transport
        allunits allobjects bidx uidx iidx aidx warheads projectiles
        attacheffects radiationtypes shieldtypes rulesdata} {
        array unset ::Data::$arr
    }

    foreach rawline $lines {
        set line [::Rules::_strip_line $rawline]
        if {$line eq ""} continue

        set newtag [::Rules::_parse_section $line]
        if {$newtag ne ""} {
            set curtag $newtag
            if {[info exists ::Data::rulesdata($curtag)] && [llength $::Data::rulesdata($curtag)] > 0} {
                ::Logging::warning "Duplicate section $curtag in rules file"
            }
            if {![info exists ::Data::rulesdata($curtag)]} {
                set ::Data::rulesdata($curtag) {}
            }
            set idx 0
            set var_idx 0
            switch -- $curtag {
                "InfantryTypes"   { set cmode 1 }
                "VehicleTypes"    { set cmode 2 }
                "AircraftTypes"   { set cmode 3 }
                "BuildingTypes"   { set cmode 4 }
                "VoxelAnims"      { set cmode 6 }
                "Animations"      { set cmode 7 }
                "ParticleSystems" { set cmode 8 }
                "Particles"       { set cmode 25 }
                "TerrainTypes"    { set cmode 12 }
                "SmudgeTypes"     { set cmode 13 }
                "Countries"       { set cmode 20 }
                "SuperWeaponTypes" { set cmode 21 }
                "WeaponTypes"     { set cmode 22 }
                "Warheads"        { set cmode 23 }
                "Projectiles"     { set cmode 24 }
                "AttachEffectTypes" { set cmode 26 }
                "RadiationTypes"  { set cmode 27 }
                "ShieldTypes"     { set cmode 28 }
                "General"         { set cmode 49 }
                "VariableNames"   { set cmode 50 }
                "ArmorTypes"      { set cmode 52 }
                default           { set cmode 51 }
            }
            continue
        }

        lappend ::Data::rulesdata($curtag) $line

        set kv [::util::_parse_keyval $line]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set val [lindex $kv 1]

        switch -exact -- $cmode {
            1 {
                if {[info exists ::Data::infantry($val)]} {
                    ::Logging::warning "Duplicate InfantryType: $val (index $idx)"
                }
                set ::Data::infantry($val) ""
                set ::Data::iidx($idx) $val
                incr idx
            }
            2 {
                if {[info exists ::Data::vehicles($val)]} {
                    ::Logging::warning "Duplicate VehicleType: $val (index $idx)"
                }
                set ::Data::vehicles($val) ""
                set ::Data::uidx($idx) $val
                incr idx
            }
            3 {
                if {[info exists ::Data::aircraft($val)]} {
                    ::Logging::warning "Duplicate AircraftType: $val (index $idx)"
                }
                set ::Data::aircraft($val) ""
                set ::Data::aidx($idx) $val
                incr idx
            }
            4 {
                if {[info exists ::Data::buildings($val)]} {
                    ::Logging::warning "Duplicate BuildingType: $val (index $idx)"
                }
                set ::Data::buildings($val) ""
                set ::Data::bidx($idx) $val
                incr idx
            }
            6 {
                set ::Data::vanims($idx) $val
                incr idx
            }
            7 {
                if {[info exists ::Data::anims($val)]} {
                    ::Logging::warning "Duplicate Animation: $val (index $idx)"
                }
                set ::Data::anims($val) ""
                set ::Data::ianims($idx) $val
                incr idx
            }
            8 {
                set ::Data::particlesys($idx) $val
                incr idx
            }
            12 {
                if {[info exists ::Data::terrains($val)]} {
                    ::Logging::warning "Duplicate TerrainType: $val"
                }
                set ::Data::terrains($val) ""
            }
            13 {
                if {[info exists ::Data::smudges($val)]} {
                    ::Logging::warning "Duplicate SmudgeType: $val"
                }
                set ::Data::smudges($val) ""
            }
            20 {
                if {[info exists ::Data::countries($val)]} {
                    ::Logging::warning "Duplicate Country: $val (index $idx)"
                }
                set ::Data::countries($val) $idx
                incr country_count
                incr idx
            }
            21 {
                set ::Data::superweapons($idx) $val
                incr idx
            }
            22 {
                set ::Data::weapons($idx) $val
                incr idx
            }
            23 {
                set ::Data::warheads($idx) $val
                incr idx
            }
            24 {
                set ::Data::projectiles($idx) $val
                incr idx
            }
            25 {
                set ::Data::particles($idx) $val
                incr idx
            }
            26 {
                set ::Data::attacheffects($idx) $val
                incr idx
            }
            27 {
                set ::Data::radiationtypes($idx) $val
                incr idx
            }
            28 {
                set ::Data::shieldtypes($idx) $val
                incr idx
            }
            49 {
                if {$pfx eq "PadAircraft" || $pfx eq "HarvesterUnit"} {
                    foreach item [split $val ","] {
                        set ::Data::paddies([string trim $item]) "x"
                    }
                }
            }
            50 {
                if {[string is integer -strict $pfx]} {
                    set ::Data::globalvars($pfx) $val
                    # rules-defined global variable - not map content, skip
                    # unused reporting for it
                    set ::Data::ai_defs($pfx) 1
                } else {
                    set ::Data::globalvars($var_idx) $val
                    set ::Data::ai_defs($var_idx) 1
                    incr var_idx
                }
            }
            52 {
                set rawval $val
                set semi [string first ";" $rawval]
                if {$semi != -1} { set rawval [string trim [string range $rawval 0 [expr {$semi - 1}]]] }
                set ::Data::armortypes([string tolower $pfx]) [string tolower $rawval]
                if {![info exists ::Data::armortypes_order]} { set ::Data::armortypes_order {} }
                lappend ::Data::armortypes_order [string tolower $pfx]
            }
            default {
                switch -exact -- $pfx {
                    "Owner" {
                        if {![info exists ::Data::owners($curtag)]} {
                            set ::Data::owners($curtag) $val
                        }
                    }
                    "Image" {
                        if {[info exists ::Data::buildings($curtag)]} {
                            set ::Data::art($curtag) $val
                        }
                    }
                    "Harvester" {
                        if {$val eq "yes"} { set ::Data::harvy($curtag) 1 }
                    }
                    "Passengers" {
                        if {[string is integer -strict $val] && $val > 0} {
                            set ::Data::transport($curtag) 1
                        }
                    }
                    default {
                        switch -exact -- $pfx {
                            "Agent"     { if {$val eq "yes"} { set ::Data::agent($curtag) 1 } }
                            "Assaulter" { if {$val eq "yes"} { set ::Data::assaulter($curtag) 1 } }
                            "Engineer"  { if {$val eq "yes"} { set ::Data::engineer($curtag) 1 } }
                        }
                    }
                }
            }
        }
    }

    array set ::Data::allunits [array get ::Data::infantry]
    array set ::Data::allunits [array get ::Data::vehicles]
    array set ::Data::allunits [array get ::Data::aircraft]
    array set ::Data::allobjects [array get ::Data::allunits]
    array set ::Data::allobjects [array get ::Data::buildings]

    set ::Data::countrycnt $country_count

    if {![info exists ::Data::infantry] || [array size ::Data::infantry] == 0} {
        return -code error "Failed to load any InfantryTypes from rules file."
    }
    if {![info exists ::Data::vehicles] || [array size ::Data::vehicles] == 0} {
        return -code error "Failed to load any VehicleTypes from rules file."
    }
    if {![info exists ::Data::aircraft] || [array size ::Data::aircraft] == 0} {
        ::Logging::warning "No AircraftTypes loaded from rules file."
    }
    if {![info exists ::Data::buildings] || [array size ::Data::buildings] == 0} {
        return -code error "Failed to load any BuildingTypes from rules file."
    }
    if {![info exists ::Data::warheads] || [array size ::Data::warheads] == 0} {
        ::Logging::warning "No Warheads loaded from rules file."
    }
    if {![info exists ::Data::projectiles] || [array size ::Data::projectiles] == 0} {
        ::Logging::warning "No Projectiles loaded from rules file."
    }
    return 1
}
