#----------------------------------------------------------------------------------------------------------
# map_parser.tcl - Aggregator for map parsing submodules
#----------------------------------------------------------------------------------------------------------

# Ensure the namespace exists
namespace eval ::MapParser {}

# Core helpers
source [file join [file dirname [info script]] "map_parser" "core.tcl"]

# Load map file
source [file join [file dirname [info script]] "map_parser" "load_map.tcl"]

# Process Basic and Map sections
source [file join [file dirname [info script]] "map_parser" "basic_map.tcl"]

# Process CellTags and house building data
source [file join [file dirname [info script]] "map_parser" "celltags_house_data.tcl"]

# Process Houses, Countries, Variables, Waypoints, Header
source [file join [file dirname [info script]] "map_parser" "houses_countries.tcl"]

# Process placed structures, units, infantry, smudge, terrain
source [file join [file dirname [info script]] "map_parser" "structures_units_infantry.tcl"]

# Process TeamTypes, ScriptTypes, TaskForces, Triggers, Events, Actions, Tags
source [file join [file dirname [info script]] "map_parser" "team_script_taskforce_triggers.tcl"]

# Process type declarations from map (BuildingTypes, AircraftTypes, VehicleTypes, InfantryTypes)
source [file join [file dirname [info script]] "map_parser" "typedecl_units.tcl"]

# Process other type declarations (WeaponTypes, Warheads, Projectiles, Animations, etc.)
source [file join [file dirname [info script]] "map_parser" "typedecl_others.tcl"]

# Process AI triggers
source [file join [file dirname [info script]] "map_parser" "aitriggers.tcl"]

# --------------------------------------------------------------------------
# Main map parsing orchestration
# --------------------------------------------------------------------------
proc ::MapParser::parse_map {filename} {
    ::MapParser::load_map_file $filename

    ::MapParser::process_basic
    ::MapParser::process_map
    ::MapParser::process_typedecl
    ::MapParser::process_typedecl_others
    ::MapParser::process_unit_owners
    ::MapParser::process_infantry_flags_from_map
    ::MapParser::process_houses
    ::MapParser::check_basic_player
    ::MapParser::process_countries
    ::MapParser::process_variablenames
    ::MapParser::process_waypoints
    ::MapParser::process_header
    ::MapParser::process_teamtypes
    ::MapParser::process_scripttypes
    ::MapParser::process_taskforces
    ::MapParser::process_triggers
    ::MapParser::process_events
    ::MapParser::process_actions
    ::MapParser::process_tags
    ::MapParser::process_structures
    ::MapParser::process_aircraft
    ::MapParser::process_units
    ::MapParser::process_infantry
    ::MapParser::process_smudge
    ::MapParser::process_terrain
    ::MapParser::process_celltags
    ::MapParser::process_aitrigger_types
    ::MapParser::process_aitrigger_enable

    if {[info exists ::Data::houses]} {
        foreach country_id [array names ::Data::houses] {
            ::MapParser::process_house_data $country_id
        }
    }
}

return