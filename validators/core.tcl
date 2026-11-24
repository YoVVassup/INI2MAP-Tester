#----------------------------------------------------------------------------------------------------------
# validators_core.tcl - Core validation functions for INI2MAP Tester
# Contains:
#   - Unified code checks (event, action, script) with gamemode awareness
#   - Basic object validation (country, waypoint, sound, animation, voxelanim,
#     teamtype, technotype, particles, superweapon, local/global var)
#   - Helper procedures for action validation (to be used by validators_actions.tcl)
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace (no global variables)
# Logging uses ::Logging::error/warning/notice/info (defined in logging.tcl)
#----------------------------------------------------------------------------------------------------------

# Guard against double sourcing
if {[namespace exists ::Validators] && [info exists ::Validators::core_loaded]} {
    return
}
# Ensure the namespace exists
if {![namespace exists ::Validators]} {
    namespace eval ::Validators {}
}
set ::Validators::core_loaded 1

# --------------------------------------------------------------------------
# Unified code checks
# --------------------------------------------------------------------------
# Phobos is a superset of Ares: the classic 0-MAX codes stay valid and the
# Phobos extensions are listed in constants.tcl as flat (first last) pairs.
# --- validate_event_code ---
# Validates that an event code is within the allowed range for the current gamemode.
proc ::Validators::validate_event_code {trigger context code} {
    if {$::Data::gamemode eq "phobos"} {
        if {![::Constants::code_in_ranges $code $::Constants::PHOBOS_EVENT_RANGES]} {
            ::Logging::error "Trigger \"$trigger\" ($context) uses event code $code which is not defined in Phobos (valid: [::Validators::_ranges_str $::Constants::PHOBOS_EVENT_RANGES])"
            return 0
        }
        return 1
    }
    switch -exact -- $::Data::gamemode {
        "ra2"  { set maxcode $::Constants::MAX_EVENT_RA2 }
        "yr"   { set maxcode $::Constants::MAX_EVENT_YR }
        "ares" - default { set maxcode $::Constants::MAX_EVENT_ARES }
    }
    if {$code > $maxcode} {
        ::Logging::error "Trigger \"$trigger\" ($context) uses event code $code which exceeds maximum for $::Data::gamemode (max $maxcode)"
        return 0
    }
    return 1
}

# --- validate_action_code ---
# Validates that an action code is within the allowed range for the current gamemode.
proc ::Validators::validate_action_code {trigger context code} {
    if {$::Data::gamemode eq "phobos"} {
        if {![::Constants::code_in_ranges $code $::Constants::PHOBOS_ACTION_RANGES]} {
            ::Logging::error "Trigger \"$trigger\" ($context) uses action code $code which is not defined in Phobos (valid: [::Validators::_ranges_str $::Constants::PHOBOS_ACTION_RANGES])"
            return 0
        }
        return 1
    }
    switch -exact -- $::Data::gamemode {
        "ra2"  { set maxcode $::Constants::MAX_ACTION_RA2 }
        "yr"   { set maxcode $::Constants::MAX_ACTION_YR }
        "ares" - default { set maxcode $::Constants::MAX_ACTION_ARES }
    }
    if {$code > $maxcode} {
        ::Logging::error "Trigger \"$trigger\" ($context) uses action code $code which exceeds maximum for $::Data::gamemode (max $maxcode)"
        return 0
    }
    return 1
}

# --- validate_script_code ---
# Validates that a script command is within the allowed range for the current gamemode.
proc ::Validators::validate_script_code {script line_num code} {
    if {$::Data::gamemode eq "phobos"} {
        if {![::Constants::code_in_ranges $code $::Constants::PHOBOS_SCRIPT_RANGES]} {
            ::Logging::error "Script \"$script\" (line: $line_num) uses script command $code which is not defined in Phobos (valid: [::Validators::_ranges_str $::Constants::PHOBOS_SCRIPT_RANGES])"
            return 0
        }
        return 1
    }
    switch -exact -- $::Data::gamemode {
        "ra2"  { set maxcode $::Constants::MAX_SCRIPT_RA2 }
        "yr"   { set maxcode $::Constants::MAX_SCRIPT_YR }
        "ares" - default { set maxcode $::Constants::MAX_SCRIPT_ARES }
    }
    if {$code > $maxcode} {
        ::Logging::error "Script \"$script\" (line: $line_num) uses script command $code which exceeds maximum for $::Data::gamemode (max $maxcode)"
        return 0
    }
    return 1
}

# --------------------------------------------------------------------------
# Phobos parameter helpers
# --------------------------------------------------------------------------
# --- _ranges_str ---
# Renders a flat (first last) pair list as "0-88, 500-535, ..." for messages.
proc ::Validators::_ranges_str {ranges} {
    set out {}
    for {set i 0} {$i < [llength $ranges]} {incr i 2} {
        lappend out "[lindex $ranges $i]-[lindex $ranges $i+1]"
    }
    return [join $out ", "]
}

# --- _phobos_op ---
# Phobos operation codes 0..11 (assign, add, sub, ..., and).
proc ::Validators::_phobos_op {trigger context op} {
    if {![string is integer -strict $op]} {
        ::Logging::error "Trigger \"$trigger\" ($context) has non-integer Phobos Operation: $op"
        return 0
    }
    if {$op < 0 || $op > 11} {
        ::Logging::error "Trigger \"$trigger\" ($context) has Phobos Operation $op out of range (0-11)"
        return 0
    }
    return 1
}

# --- _phobos_scope_var ---
# $scope is the Phobos IsGlobalVariable flag: 0 = local variable, 1 = global.
proc ::Validators::_phobos_scope_var {trigger context val scope} {
    if {![string is integer -strict $scope] || ($scope != 0 && $scope != 1)} {
        ::Logging::error "Trigger \"$trigger\" ($context) has invalid IsGlobalVariable flag: $scope (must be 0 or 1)"
        return 0
    }
    if {$scope == 1} {
        return [::Validators::validate_global_var $trigger $context $val]
    }
    return [::Validators::validate_local_var $trigger $context $val]
}

# --- _phobos_int ---
# Generic "this parameter must be an integer" check.
# $kind prefixes the message ("Trigger" by default, "Script" for script actions).
proc ::Validators::_phobos_int {trigger context val what {kind "Trigger"}} {
    if {![string is integer -strict $val]} {
        ::Logging::error "$kind \"$trigger\" ($context) has non-integer $what: $val"
        return 0
    }
    return 1
}

# --- _phobos_int_range ---
# Integer check plus an inclusive range check.
proc ::Validators::_phobos_int_range {trigger context val what min max {kind "Trigger"}} {
    if {![string is integer -strict $val]} {
        ::Logging::error "$kind \"$trigger\" ($context) has non-integer $what: $val"
        return 0
    }
    if {$val < $min || $val > $max} {
        ::Logging::error "$kind \"$trigger\" ($context) has $what $val out of range ($min-$max)"
        return 0
    }
    return 1
}

# --- _phobos_packed_var ---
# Script commands 18000-18071 pack two 16-bit halves into one integer:
#   low16  = the variable being edited
#   high16 = operand (18000-18023), local variable (18024-18047)
#            or global variable (18048-18071)
# $high_kind is "number", "local" or "global".
proc ::Validators::_phobos_packed_var {script line_num cmd value high_kind} {
    if {![string is integer -strict $value] || $value < -2147483648 || $value > 4294967295} {
        ::Logging::error "Script \"$script\" (line: $line_num) has out-of-range packed value for command $cmd: $value"
        return 0
    }
    set low [expr {$value & 0xFFFF}]
    if {![info exists ::Data::variables($low)] && ![info exists ::Data::globalvars($low)]} {
        ::Logging::error "Script \"$script\" (line: $line_num) refers to invalid Variable index: $low"
        return 0
    }
    if {$high_kind eq "number"} {
        # The operand is an int16 held in the high half; its range is implied
        # by the bit layout, so there is nothing left to check.
        return 1
    }
    set high [expr {($value >> 16) & 0xFFFF}]
    if {$high >= 32768} { incr high -65536 }
    if {$high_kind eq "local"} {
        return [::Validators::validate_local_var $script "line: $line_num" $high]
    }
    return [::Validators::validate_global_var $script "line: $line_num" $high]
}

# --- _phobos_house ---
# $allow_neg is the list of negative sentinels this parameter accepts
# ({} = the parameter carries no house meaning). Non-negative values are
# checked against the country / multiplayer-house registry.
proc ::Validators::_phobos_house {trigger context val allow_neg} {
    if {![string is integer -strict $val]} {
        ::Logging::error "Trigger \"$trigger\" ($context) has non-integer House index: $val"
        return 0
    }
    if {$val < 0} {
        # {} means the code has no documented negative sentinels: don't judge.
        if {$allow_neg eq "" || [lsearch -exact $allow_neg $val] >= 0} {
            return 1
        }
        ::Logging::error "Trigger \"$trigger\" ($context) has invalid House index: $val (allowed: [join $allow_neg { }] or a house index)"
        return 0
    }
    return [::Validators::validate_country_index $trigger $context $val]
}

# --------------------------------------------------------------------------
# Basic object validation (direct access to ::Data)
# --------------------------------------------------------------------------
# --- validate_country_index ---
# Validates that a country index exists in the global or map-specific data.
proc ::Validators::validate_country_index {trigger context idx} {
    set global_valid 0
    if {[info exists ::Data::countrycnt]} {
        if {$idx >= 0 && $idx < $::Data::countrycnt} {
            set global_valid 1
        }
    }
    set map_valid 0
    if {[info exists ::Data::changeidx($idx)] || [info exists ::Data::mphouses($idx)]} {
        set map_valid 1
    }
    if {!$global_valid && !$map_valid} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid Country index: $idx"
        return 0
    }
    return 1
}

# --- validate_waypoint ---
# Validates that a waypoint reference exists in the waypoints data.
proc ::Validators::validate_waypoint {trigger context wp_ref} {
    if {[string is integer -strict $wp_ref]} {
        set nom [::MapParser::num2wp $wp_ref]
    } else {
        set nom [string toupper $wp_ref]
    }
    if {![info exists ::Data::waypoints($nom)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid Waypoint: $wp_ref"
        return 0
    }
    set ::Data::waypoints($nom) 1
    return 1
}

# --- validate_sound ---
# Validates that a sound ID exists in the sound list.
proc ::Validators::validate_sound {trigger context sound_id} {
    set sound_id_lower [string tolower $sound_id]
    if {![info exists ::Data::sndlist($sound_id_lower)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) cannot play invalid Sound: $sound_id"
        return 0
    }
    return 1
}

# --- validate_animation ---
# Validates that an animation ID exists and logs its use.
proc ::Validators::validate_animation {trigger context anim_id} {
    if {$anim_id eq ""} {
        ::Logging::error "Trigger \"$trigger\" ($context) cannot play blank Animation"
        return 0
    }
    if {![info exists ::Data::ianims($anim_id)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) cannot play invalid Animation: $anim_id"
        return 0
    }
    append ::Data::animlog "NOTICE -> Trigger \"$trigger\" ($context) plays Animation: $::Data::ianims($anim_id)\n"
    return 1
}

# --- validate_voxelanim ---
# Validates that a voxel animation ID exists and logs its use.
proc ::Validators::validate_voxelanim {trigger context anim_id} {
    if {$anim_id eq ""} {
        ::Logging::error "Trigger \"$trigger\" ($context) cannot play blank VoxelAnim"
        return 0
    }
    if {![info exists ::Data::vanims($anim_id)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) cannot play invalid VoxelAnim: $anim_id"
        return 0
    }
    append ::Data::animlog "NOTICE -> Trigger \"$trigger\" ($context) plays VoxelAnim: $::Data::vanims($anim_id)\n"
    return 1
}

# --- validate_teamtype ---
# Validates that a team type ID exists in the teamtypes data.
proc ::Validators::validate_teamtype {trigger context team_id} {
    if {![info exists ::Data::teamtypes($team_id)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid TeamType: $team_id"
        return 0
    }
    set ::Data::uteam($team_id) 1
    return 1
}

# --- validate_technotype ---
# Validates that a techno type ID exists in the units or buildings data.
proc ::Validators::validate_technotype {trigger context techno_id} {
    if {![info exists ::Data::allunits($techno_id)] && ![info exists ::Data::buildings($techno_id)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid TechnoType: $techno_id"
        return 0
    }
    return 1
}

# --- validate_particles ---
# Validates that a particle system ID exists.
proc ::Validators::validate_particles {trigger context part_id} {
    # Validate particle system ID (from [ParticleSystems])
    if {![info exists ::Data::particlesys($part_id)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid ParticleSys: $part_id"
        return 0
    }
    return 1
}

# --- validate_superweapon ---
# Validates that a super weapon index exists.
proc ::Validators::validate_superweapon {trigger context sw_idx} {
    if {![info exists ::Data::superweapons($sw_idx)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid Super Weapon: $sw_idx"
        return 0
    }
    return 1
}

# --- validate_local_var ---
# Validates that a local variable index exists.
proc ::Validators::validate_local_var {trigger context var_idx} {
    if {![info exists ::Data::variables($var_idx)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid local Variable: $var_idx"
        return 0
    }
    set ::Data::uvars($var_idx) 1
    return 1
}

# --- validate_global_var ---
# Validates that a global variable index exists and logs its use.
proc ::Validators::validate_global_var {trigger context var_idx} {
    if {![info exists ::Data::globalvars($var_idx)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid global Variable: $var_idx"
        return 0
    }
    set ::Data::uglobal($var_idx) 1
    append ::Data::animlog "NOTICE -> Trigger \"$trigger\" ($context) uses global Variable: $::Data::globalvars($var_idx) (index $var_idx)\n"
    return 1
}

# --------------------------------------------------------------------------
# Helper procedures for action validation (used by validators_actions.tcl)
# --------------------------------------------------------------------------
# --- _validate_action_country ---
# Helper to validate a country index for an action.
proc ::Validators::_validate_action_country {trigger context act3} {
    ::Validators::validate_country_index $trigger $context $act3
}

# --- _validate_action_team ---
# Helper to validate a team type for an action.
proc ::Validators::_validate_action_team {trigger context act3} {
    ::Validators::validate_teamtype $trigger $context $act3
}

# --- _validate_action_team_waypoint ---
# Helper to validate a team type and waypoint for an action.
proc ::Validators::_validate_action_team_waypoint {trigger context act3 act4} {
    ::Validators::validate_teamtype $trigger $context $act3
    ::Validators::validate_waypoint $trigger $context $act4
}

# --- _validate_action_waypoint ---
# Helper to validate a waypoint for an action.
proc ::Validators::_validate_action_waypoint {trigger context act4} {
    ::Validators::validate_waypoint $trigger $context $act4
}

# --- _validate_action_sound ---
# Helper to validate a sound for an action.
proc ::Validators::_validate_action_sound {trigger context act3} {
    ::Validators::validate_sound $trigger $context $act3
}

# --- _validate_action_movie ---
# Helper to validate a movie index for an action.
proc ::Validators::_validate_action_movie {trigger context act3} {
    if {![info exists ::Data::movies($act3)]} {
        ::Logging::warning "Trigger \"$trigger\" ($context) refers to invalid movie index: $act3"
    }
}

# --- _validate_action_trigger ---
# Helper to validate a trigger reference for an action.
proc ::Validators::_validate_action_trigger {trigger context act3} {
    if {![info exists ::Data::triggers($act3)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) cannot destroy invalid Trigger: $act3"
    }
}

# --- _validate_action_theme ---
# Helper to validate a music theme index for an action.
proc ::Validators::_validate_action_theme {trigger context act3} {
    if {![info exists ::Data::themes_by_name($act3)]} {
        ::Logging::warning "Trigger \"$trigger\" ($context) refers to invalid music theme index: $act3"
    }
}

# --- _validate_action_speech ---
# Helper to validate a speech index for an action.
proc ::Validators::_validate_action_speech {trigger context act3} {
    if {![info exists ::Data::dialogs_by_name($act3)]} {
        ::Logging::warning "Trigger \"$trigger\" ($context) refers to invalid speech index: $act3"
    }
}

# --- _validate_action_global_var ---
# Helper to validate a global variable for an action.
proc ::Validators::_validate_action_global_var {trigger context act3} {
    ::Validators::validate_global_var $trigger $context $act3
}

# --- _validate_action_local_var ---
# Helper to validate a local variable for an action.
proc ::Validators::_validate_action_local_var {trigger context act3} {
    ::Validators::validate_local_var $trigger $context $act3
}

# --- _validate_action_superweapon ---
# Helper to validate a super weapon and its parameters for an action.
proc ::Validators::_validate_action_superweapon {trigger context act3 act4 act1} {
    if {![info exists ::Data::superweapons($act3)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid Super Weapon index: $act3"
    }
    if {$act1 == $::Constants::ACTION_SW_CHARGE || $act1 == $::Constants::ACTION_SW_RECHARGE || $act1 == $::Constants::ACTION_SW_RECHARGE2} {
        if {![string is integer -strict $act4]} {
            ::Logging::error "Trigger \"$trigger\" ($context) has non-integer parameter: $act4"
        } elseif {$act1 == $::Constants::ACTION_SW_CHARGE && ($act4 < $::Constants::SW_CHARGE_MIN || $act4 > $::Constants::SW_CHARGE_MAX)} {
            ::Logging::error "Trigger \"$trigger\" ($context) Superweapon charge value out of range ($::Constants::SW_CHARGE_MIN-$::Constants::SW_CHARGE_MAX): $act4"
        } elseif {($act1 == $::Constants::ACTION_SW_RECHARGE || $act1 == $::Constants::ACTION_SW_RECHARGE2) && $act4 < 0} {
            ::Logging::error "Trigger \"$trigger\" ($context) recharge time cannot be negative: $act4"
        }
    }
}

# --- _validate_action_animation ---
# Helper to validate an animation and waypoint for an action.
proc ::Validators::_validate_action_animation {trigger context act3 act4} {
    ::Validators::validate_animation $trigger $context $act3
    ::Validators::validate_waypoint $trigger $context $act4
}

# --- _validate_action_weapon ---
# Helper to validate a weapon and waypoint for an action.
proc ::Validators::_validate_action_weapon {trigger context act3 act4} {
    if {![info exists ::Data::weapons($act3)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid Weapon index: $act3"
    }
    ::Validators::validate_waypoint $trigger $context $act4
}

# --- _validate_action_voxelanim ---
# Helper to validate a voxel animation and waypoint for an action.
proc ::Validators::_validate_action_voxelanim {trigger context act3 act4} {
    ::Validators::validate_voxelanim $trigger $context $act3
    ::Validators::validate_waypoint $trigger $context $act4
}

# --- _validate_action_particles ---
# Helper to validate a particle system and waypoint for an action.
proc ::Validators::_validate_action_particles {trigger context act3 act4} {
    ::Validators::validate_particles $trigger $context $act3
    ::Validators::validate_waypoint $trigger $context $act4
}

# --- _validate_action_techno ---
# Helper to validate a techno type for an action.
proc ::Validators::_validate_action_techno {trigger context act3} {
    ::Validators::validate_technotype $trigger $context $act3
}

# --- _validate_action_crate ---
# Helper to validate a crate type and waypoint for an action.
proc ::Validators::_validate_action_crate {trigger context act3 act4} {
    ::Validators::validate_waypoint $trigger $context $act4
    if {![string is integer -strict $act3] || $act3 < 0 || $act3 > $::Constants::MAX_CRATE_TYPE} {
        ::Logging::error "Trigger \"$trigger\" ($context) cannot create invalid Crate type: $act3"
    }
}

# --- _validate_action_building ---
# Helper to validate a building and waypoint for an action.
proc ::Validators::_validate_action_building {trigger context act3 act4} {
    if {![info exists ::Data::buildings($act3)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid Building: $act3"
    }
    ::Validators::validate_waypoint $trigger $context $act4
}

# --- _validate_action_flash_building ---
# Helper to validate a building type and flash duration for an action.
proc ::Validators::_validate_action_flash_building {trigger context act3 act4} {
    if {![info exists ::Data::buildings($act3)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) refers to invalid BuildingType: $act3"
    }
    if {![string is integer -strict $act4] || $act4 < 0} {
        ::Logging::error "Trigger \"$trigger\" ($context) Flash Buildings has invalid duration: $act4"
    }
}

# --- _validate_action_talkbubble ---
# Helper to validate a team type and frame number for a talk bubble action.
proc ::Validators::_validate_action_talkbubble {trigger context act3 act4} {
    if {![info exists ::Data::teamtypes($act3)]} {
        ::Logging::error "Trigger \"$trigger\" ($context) cannot show talk bubble for invalid TeamType: $act3"
    }
    if {![string is integer -strict $act4] || $act4 < 0} {
        ::Logging::error "Trigger \"$trigger\" ($context) Talk Bubble has invalid frame number: $act4"
    }
}

# --- _validate_action_auxpower ---
# Helper to validate a country index and power value for an auxiliary power action.
proc ::Validators::_validate_action_auxpower {trigger context act3 act4} {
    ::Validators::validate_country_index $trigger $context $act3
    if {![string is integer -strict $act4]} {
        ::Logging::error "Trigger \"$trigger\" ($context) Auxiliary Power has non-integer power value: $act4"
    }
}
