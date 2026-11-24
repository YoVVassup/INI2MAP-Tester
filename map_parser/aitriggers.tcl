#----------------------------------------------------------------------------------------------------------
# map_parser/aitriggers.tcl - Processing AI triggers
# Contains:
#   - process_aitrigger_enable: handles AITriggerTypesEnable section
#   - process_aitrigger_types: handles AITriggerTypes section
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

namespace eval ::MapParser {
    # Guard against double loading
    if {[info exists ::MapParser::aitriggers_loaded]} { return }
    variable aitriggers_loaded 1
}

# --- process_aitrigger_enable ---
# Validate AITriggerTypesEnable entries against known local and global AI triggers.
proc ::MapParser::process_aitrigger_enable {} {
    if {![info exists ::Data::rawmapdata(AITriggerTypesEnable)]} return
    foreach curline $::Data::rawmapdata(AITriggerTypesEnable) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set tag [lindex $kv 1]

        set is_local  [info exists ::Data::local_aitriggers($pfx)]
        set is_global [info exists ::Data::aitriggertypes($pfx)]

        if {!$is_local && !$is_global} {
            ::Logging::warning "AITriggerType \"$pfx\" listed in AITriggerTypesEnable does not exist either locally or in global rules."
        } elseif {$tag eq "yes"} {
            if {!$is_local && $is_global} {
                ::Logging::warning "AITriggerType \"$pfx\" is a global AI trigger and should not be explicitly enabled via AITriggerTypesEnable (global triggers are enabled by default). Use 'no' if you intended to disable it."
            }
        } elseif {$tag eq "no"} {
            if {$is_local && !$is_global} {
                ::Logging::warning "AITriggerType \"$pfx\" is a local AI trigger and should not be explicitly disabled via AITriggerTypesEnable (local triggers are disabled by default). Use 'yes' if you intended to enable it."
            }
        }
    }
    unset ::Data::rawmapdata(AITriggerTypesEnable)
}

# --- process_aitrigger_types ---
# Parse local AITriggerTypes, validating team types, condition objects, and owner countries.
proc ::MapParser::process_aitrigger_types {} {
    if {![info exists ::Data::rawmapdata(AITriggerTypes)]} return
    foreach curline $::Data::rawmapdata(AITriggerTypes) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set values [split [lindex $kv 1] ","]

        # B15: AITriggerTypes must have exactly 18 fields (WAE
        # AI_TRIGGER_PROPERTY_FIELD_COUNT). Warn but keep parsing - the
        # per-field checks below tolerate missing trailing fields.
        if {[llength $values] != 18} {
            ::Logging::warning "AITriggerType \"$pfx\" has invalid field count: [llength $values] (expected 18)"
        }

        if {[info exists ::Data::local_aitriggers($pfx)]} {
            ::Logging::warning "duplicate local AITriggerType ID: $pfx"
        }
        set ::Data::local_aitriggers($pfx) ""

        # According to ModEnc AITriggerTypes format (18 fields, indices 0-17):
        # 0: Name (unused)
        # 1: Team1 (primary TeamType)
        # 2: OwnerHouse (House)
        # 3: TechLevel
        # 4: ConditionType
        # 5: ConditionObject (target object)
        # 6: Comparator (hex string)
        # 7: StartingWeight
        # 8: MinimumWeight
        # 9: MaximumWeight
        # 10: IsForSkirmish
        # 11: unused
        # 12: Side
        # 13: IsBaseDefense
        # 14: Team2 (backup TeamType)
        # 15: EnabledInE
        # 16: EnabledInM
        # 17: EnabledInH

        set tt1       [lindex $values 1]   ;# primary TeamType
        set country   [lindex $values 2]   ;# OwnerHouse
        set techlevel [lindex $values 3]   ;# TechLevel (optional)
        set condtype  [lindex $values 4]   ;# ConditionType
        set tobj      [lindex $values 5]   ;# ConditionObject
        set tt2       [lindex $values 14]  ;# backup TeamType

        # Check TechLevel (if not -1, must be an integer)
        if {$techlevel ne "" && $techlevel != -1 && ![string is integer -strict $techlevel]} {
            ::Logging::warning "AITriggerType \"$pfx\" has non-integer TechLevel: $techlevel"
        }

        # Check ConditionType (optional)
        if {$condtype ne "" && ![string is integer -strict $condtype]} {
            ::Logging::warning "AITriggerType \"$pfx\" has non-integer ConditionType: $condtype"
        } elseif {$condtype ne "" && $condtype < 0} {
            ::Logging::warning "AITriggerType \"$pfx\" has ConditionType $condtype (<0). This may cause IE."
        }

        # Check primary TeamType
        if {![info exists ::Data::teamtypes($tt1)]} {
            ::Logging::error "AITriggerType \"$pfx\" has invalid primary TeamType: $tt1"
        } else {
            set ::Data::uteam($tt1) 1
        }

        # Check backup TeamType (if not "<none>" and field exists — RA2 format has fewer fields)
        if {[llength $values] > 14} {
            if {$tt2 ne "<none>" && ![info exists ::Data::teamtypes($tt2)]} {
                ::Logging::error "AITriggerType \"$pfx\" has invalid backup TeamType: $tt2"
            } elseif {$tt2 ne "<none>"} {
                set ::Data::uteam($tt2) 1
            }
        }

        # Check ConditionObject (if not "<none>")
        if {$tobj ne "<none>" && ![info exists ::Data::allobjects($tobj)]} {
            ::Logging::error "AITriggerType \"$pfx\" has invalid target object: $tobj"
        }

        # Check OwnerHouse (if not "<all>")
        if {$country ne "<all>" && ![info exists ::Data::countries($country)]} {
            ::Logging::warning "AITriggerType \"$pfx\" has invalid Country: $country"
        }
    }
    # NOTE: rawmapdata(AITriggerTypes) is intentionally kept: validators/
    # report_unused_extended.tcl reads TeamType references (fields 2/15) from it.
}