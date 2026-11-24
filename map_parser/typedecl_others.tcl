#----------------------------------------------------------------------------------------------------------
# map_parser/typedecl_others.tcl - Processing other type declarations from map
# Handles: WeaponTypes, Warheads, Projectiles, Animations, VoxelAnims,
#          ParticleSystems, SuperWeaponTypes, TerrainTypes, SmudgeTypes
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

namespace eval ::MapParser {
    # Guard against double loading
    if {[info exists ::MapParser::typedecl_others_loaded]} { return }
    variable typedecl_others_loaded 1
}

# --- Helper: add items from a map section to an array ---
# array_name     receives numeric-index -> name (convention: weapons, vanims, ...)
# idx_array_name receives name -> numeric-index (convention: anims, terrains, ...)
# keep_raw 1: do not consume the raw section (checks read it after parsing).
proc ::MapParser::_add_to_array {sect array_name idx_array_name {keep_raw 0}} {
    if {![info exists ::Data::rawmapdata($sect)]} { return }

    upvar 0 ::Data::$array_name arr
    upvar 0 ::Data::$idx_array_name idx_arr

    foreach curline $::Data::rawmapdata($sect) {
        set eq [string first "=" $curline]
        if {$eq == -1} continue
        set pfx [string range $curline 0 [expr {$eq - 1}]]
        set pfx [string trim $pfx]
        set val [string range $curline [expr {$eq + 1}] end]
        set val [string trim $val]
        if {$val eq "" || $pfx eq ""} continue

        if {![info exists idx_arr($val)]} {
            set next_idx [array size arr]
            set arr($next_idx) $val
            set idx_arr($val) $next_idx
        }
    }
    if {!$keep_raw} {
        unset ::Data::rawmapdata($sect)
    }
}

# --- process_typedecl_others ---
# Register secondary type declarations (weapons, warheads, animations, terrains, smudges, etc.).
# Argument sides follow the load_rules.tcl conventions:
#   numeric-keyed (idx -> name): weapons, warheads, projectiles, vanims,
#                                particlesys, superweapons
#   name-keyed:                  anims (load_rules:119), ianims = idx -> name (:120),
#                                terrains (:131), smudges (:137)
proc ::MapParser::process_typedecl_others {} {
    ::MapParser::_add_to_array "WeaponTypes"      weapons      weapons_idx
    ::MapParser::_add_to_array "Warheads"         warheads     warheads_idx
    ::MapParser::_add_to_array "Projectiles"      projectiles  projectiles_idx
    ::MapParser::_add_to_array "Animations"       ianims       anims
    ::MapParser::_add_to_array "VoxelAnims"       vanims       vanims_idx
    ::MapParser::_add_to_array "ParticleSystems"  particlesys  particlesys_idx
    # keep_raw: checks/auxbuilding_superweapons.tcl:23 reads the raw section
    ::MapParser::_add_to_array "SuperWeaponTypes" superweapons superweapons_idx 1
    ::MapParser::_add_to_array "TerrainTypes"     terrains_idx terrains
    ::MapParser::_add_to_array "SmudgeTypes"      smudges_idx  smudges
}
