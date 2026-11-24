#----------------------------------------------------------------------------------------------------------
# map_parser/typedecl_units.tcl - Processing type declarations and unit owners
# Contains:
#   - process_typedecl: BuildingTypes, AircraftTypes, VehicleTypes, InfantryTypes
#   - process_unit_owners: extracts Owner= from unit sections
#   - process_infantry_flags_from_map: extracts Agent/Assaulter/Engineer from map infantry sections
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

namespace eval ::MapParser {
    # Guard against double loading
    if {[info exists ::MapParser::typedecl_units_loaded]} { return }
    variable typedecl_units_loaded 1
}

# --- process_typedecl ---
# Register BuildingTypes, AircraftTypes, VehicleTypes, and InfantryTypes from the map.
proc ::MapParser::process_typedecl {} {
    foreach sect {BuildingTypes AircraftTypes VehicleTypes InfantryTypes} {
        if {![info exists ::Data::rawmapdata($sect)]} continue
        foreach curline $::Data::rawmapdata($sect) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            set idx [string trim [lindex $kv 0]]
            set tag [string trim [lindex $kv 1]]
            if {$tag eq ""} continue
            switch -- $sect {
                "BuildingTypes" {
                    if {![info exists ::Data::buildings($tag)]} {
                        set ::Data::buildings($tag) ""
                    }
                    if {[string is integer -strict $idx]} {
                        if {![info exists ::Data::bidx($idx)]} {
                            set ::Data::bidx($idx) $tag
                        }
                    }
                }
                "AircraftTypes" {
                    if {![info exists ::Data::vehicles($tag)]} {
                        set ::Data::vehicles($tag) ""
                    }
                    set ::Data::allunits($tag) ""
                    lappend ::Data::mapunits $tag
                    if {[string is integer -strict $idx]} {
                        if {![info exists ::Data::aidx($idx)]} {
                            set ::Data::aidx($idx) $tag
                        }
                    }
                }
                "VehicleTypes" {
                    if {![info exists ::Data::vehicles($tag)]} {
                        set ::Data::vehicles($tag) ""
                    }
                    set ::Data::allunits($tag) ""
                    lappend ::Data::mapunits $tag
                    if {[string is integer -strict $idx]} {
                        if {![info exists ::Data::uidx($idx)]} {
                            set ::Data::uidx($idx) $tag
                        }
                    }
                }
                "InfantryTypes" {
                    if {![info exists ::Data::infantry($tag)]} {
                        set ::Data::infantry($tag) ""
                    }
                    set ::Data::allunits($tag) ""
                    lappend ::Data::mapunits $tag
                    if {[string is integer -strict $idx]} {
                        if {![info exists ::Data::iidx($idx)]} {
                            set ::Data::iidx($idx) $tag
                        }
                    }
                }
            }
        }
        unset ::Data::rawmapdata($sect)
    }
}

# --- process_unit_owners ---
# Extract Owner= values from each map-defined unit type section.
proc ::MapParser::process_unit_owners {} {
    if {![info exists ::Data::mapunits]} return
    foreach curtag $::Data::mapunits {
        if {![info exists ::Data::rawmapdata($curtag)]} continue
        foreach line $::Data::rawmapdata($curtag) {
            if {[string match "Owner=*" $line]} {
                set kv [::util::_parse_keyval $line]
                if {$kv ne ""} {
                    set tag [string trim [lindex $kv 1]]
                    set ::Data::owners($curtag) $tag
                }
                break
            }
        }
    }
}

# --- process_infantry_flags_from_map ---
# Extract Agent, Assaulter, and Engineer flags from map infantry sections.
proc ::MapParser::process_infantry_flags_from_map {} {
    foreach inf [array names ::Data::infantry] {
        if {![info exists ::Data::rawmapdata($inf)]} continue
        foreach line $::Data::rawmapdata($inf) {
            set kv [::util::_parse_keyval $line]
            if {$kv eq ""} continue
            set pfx [lindex $kv 0]
            set val [lindex $kv 1]
            if {$pfx eq "Agent" && $val eq "yes"} {set ::Data::agent($inf) 1}
            if {$pfx eq "Assaulter" && $val eq "yes"} {set ::Data::assaulter($inf) 1}
            if {$pfx eq "Engineer" && $val eq "yes"} {set ::Data::engineer($inf) 1}
        }
    }
}