# checks/armor_types.tcl
# Validates [ArmorTypes] section (Ares/Phobos)
# Game modes: Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Armor_types
# Checks:
#   1. Armor type chain validity (parent must exist)
#   2. Unused registered armor types (registered but never used by any TechnoType)
#   3. Unregistered armor types (used by TechnoType but not in [ArmorTypes])

proc ::Checks::validate_armor_types {} {
    upvar ::Data::buildings buildings
    upvar ::Data::vehicles vehicles
    upvar ::Data::infantry infantry
    upvar ::Data::aircraft aircraft

    # 11 original RA2/YR armor types (lowercase)
    set original_armor {
        none flak plate light medium heavy
        wood steel concrete special_1 special_2
    }

    # --- Phase 1: Parse ArmorTypes from rules (in order) ---
    array set registered {}
    set order {}

    if {[info exists ::Data::armortypes_order]} {
        foreach name $::Data::armortypes_order {
            set registered($name) $::Data::armortypes($name)
            lappend order $name
        }
    } elseif {[info exists ::Data::armortypes]} {
        foreach name [array names ::Data::armortypes] {
            set registered($name) $::Data::armortypes($name)
            lappend order $name
        }
    }

    # --- Phase 2: Also parse ArmorTypes from map (rawmapdata) ---
    if {[info exists ::Data::rawmapdata(ArmorTypes)]} {
        foreach curline $::Data::rawmapdata(ArmorTypes) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            set pfx [lindex $kv 0]
            set val_raw [lindex $kv 1]
            set semi [string first ";" $val_raw]
            if {$semi != -1} { set val_raw [string trim [string range $val_raw 0 [expr {$semi - 1}]]] }
            set name [string tolower $pfx]
            set parent [string tolower $val_raw]
            if {$name eq "" || $parent eq ""} continue
            set registered($name) $parent
            lappend order $name
        }
        unset ::Data::rawmapdata(ArmorTypes)
    }

    # If no ArmorTypes section found, this is not an Ares/Phobos mod - skip check
    if {[array size registered] == 0} {
        ::Logging::notice "No \[ArmorTypes\] section found (not an Ares/Phobos mod). Skipping armor type validation."
        return
    }

    # --- Phase 3: Validate parent chain ---
    set all_known $original_armor
    foreach name $order {
        set parent $registered($name)
        # Parent can be: original armor type, previously registered custom type, or a percentage (e.g. "0%", "11%")
        set is_pct [regexp {^[0-9]+%$} $parent]
        if {!$is_pct && $parent ni $all_known} {
            ::Logging::error "Armor type \"$name\" has unknown parent \"$parent\". Parent must be an original armor type, a previously registered custom type, or a percentage (e.g. 0%)."
        }
        lappend all_known $name
    }

    # --- Phase 4: Collect all Armor= values from TechnoTypes ---
    set used_armors {}
    foreach {category arr_name} {
        Building buildings
        Vehicle vehicles
        Infantry infantry
        Aircraft aircraft
    } {
        if {![info exists $arr_name]} continue
        foreach name [array names $arr_name] {
            set armor [::Checks::get_cached_property $name "Armor"]
            if {$armor eq ""} continue
            set semi [string first ";" $armor]
            if {$semi != -1} { set armor [string trim [string range $armor 0 [expr {$semi - 1}]]] }
            set armor_lower [string tolower $armor]
            if {$armor_lower ni $original_armor && ![info exists registered($armor_lower)]} {
                ::Logging::warning "$category \"$name\" uses Armor=\"$armor\" which is not registered in \[ArmorTypes\]."
            }
            dict set used_armors $armor_lower 1
        }
    }

    # --- Phase 5: Check for unused registered armor types ---
    set has_usage 0
    foreach name $order {
        if {[dict exists $used_armors $name]} {
            set has_usage 1
        } else {
            ::Logging::notice "Registered armor type \"$name\" is not used by any TechnoType."
        }
    }

    if {!$has_usage} {
        ::Logging::notice "No custom armor types from \[ArmorTypes\] are used by any TechnoType."
    }
}

# Register this check
::Checks::register_check "validate_armor_types"
