#----------------------------------------------------------------------------------------------------------
# taglist/taglist.tcl - INI tag/property name validation module
#----------------------------------------------------------------------------------------------------------
# Validates property names used in map INI against known valid tags from MODENC categories.
# Whitelists (tags-ra2/tags-yr/tags-ares/tags-phobos.cfg) are generated from
# third_party\tag_reference\tag_reference.xlsx; tags-ext.cfg collects tags found at
# runtime. Regex lines (starting with ^) cover dynamic tag names.
# Categories: InfantryTypes, VehicleTypes, AircraftTypes, BuildingTypes,
#             Warheads, Weapons, Projectiles, ParticleSystems, Particles,
#             SuperWeaponTypes, Animations, VoxelAnims, AttachEffectTypes,
#             RadiationTypes, ShieldTypes

namespace eval ::TagList {
    variable tags_dict [dict create]
    variable regex_dict [dict create]
    variable tags_lower [dict create]
    variable tags_lower_valid 0
    variable loaded 0
    variable taglist_dir ""
    variable audit_mode 0
    variable warned_tags
    variable owner_map [dict create]
    variable owner_map_built 0
}

# Category -> type registry mapping
namespace eval ::TagList {
    variable categories {
        InfantryTypes  infantry
        VehicleTypes   vehicles
        AircraftTypes  aircraft
        BuildingTypes  buildings
        Warheads       warheads
        Weapons        weapons
        Projectiles    projectiles
        ParticleSystems particlesys
        Particles      particles
        SuperWeaponTypes superweapons
        Animations     anims
        VoxelAnims     vanims
        AttachEffectTypes attacheffects
        RadiationTypes radiationtypes
        ShieldTypes    shieldtypes
    }
}

set ::TagList::taglist_dir $::app_dir

# Load a tag whitelist config.
# Lines starting with "^" are regular expressions for dynamic tag names
# (e.g. ^Versus\.([A-Za-z0-9_-]+)$) and are kept in regex_dict.
# merge=1 appends to the already loaded config (tags-phobos.cfg over tags-ares.cfg).
proc ::TagList::_load_config {filepath {merge 0}} {
    variable tags_dict
    variable regex_dict
    variable tags_lower_valid

    set tags_lower_valid 0
    if {!$merge} {
        set tags_dict [dict create]
        set regex_dict [dict create]
    }

    if {![file exists $filepath]} {
        if {!$merge} {
            puts "WARNING: Tag config not found: $filepath"
        }
        return
    }

    set fh [open $filepath r]
    fconfigure $fh -encoding utf-8
    set content [read $fh]
    close $fh

    set current_section ""
    foreach line [split $content "\n"] {
        set line [string trim $line]
        if {$line eq "" || [string index $line 0] eq ";" || [string index $line 0] eq "\ufeff"} continue

        if {[regexp {^\[(\w+)\]$} $line -> section_name]} {
            set current_section $section_name
            continue
        }

        if {$current_section ne ""} {
            if {[string index $line 0] eq "^"} {
                if {[catch {regexp -- $line ""}]} {
                    puts "WARNING: Invalid tag pattern in $filepath: $line"
                    continue
                }
                if {![dict exists $regex_dict $current_section]} {
                    dict set regex_dict $current_section [list]
                }
                dict set regex_dict $current_section \
                    [linsert [dict get $regex_dict $current_section] end $line]
                continue
            }

            if {![dict exists $tags_dict $current_section]} {
                dict set tags_dict $current_section [dict create]
            }
            set section_dict [dict get $tags_dict $current_section]
            dict set section_dict $line 1
            dict set tags_dict $current_section $section_dict
        }
    }
}

proc ::TagList::_load_extended {filepath} {
    variable tags_dict
    variable regex_dict
    variable tags_lower_valid

    set tags_lower_valid 0
    if {![file exists $filepath]} return

    set fh [open $filepath r]
    fconfigure $fh -encoding utf-8
    set content [read $fh]
    close $fh

    set current_section ""
    foreach line [split $content "\n"] {
        set line [string trim $line]
        if {$line eq "" || [string index $line 0] eq ";" || [string index $line 0] eq "\ufeff"} continue

        if {[regexp {^\[(\w+)\]$} $line -> section_name]} {
            set current_section $section_name
            continue
        }

        if {$current_section ne ""} {
            set remove 0
            if {[string index $line 0] eq "-"} {
                set remove 1
                set line [string range $line 1 end]
            }

            if {[string index $line 0] eq "^" && !$remove} {
                if {![dict exists $regex_dict $current_section]} {
                    dict set regex_dict $current_section [list]
                }
                dict set regex_dict $current_section \
                    [linsert [dict get $regex_dict $current_section] end $line]
                continue
            }

            if {![dict exists $tags_dict $current_section]} {
                dict set tags_dict $current_section [dict create]
            }
            set section_dict [dict get $tags_dict $current_section]

            if {$remove} {
                dict unset section_dict $line
            } else {
                dict set section_dict $line 1
            }
            dict set tags_dict $current_section $section_dict
        }
    }
}

proc ::TagList::init {} {
    variable loaded
    variable taglist_dir
    if {$loaded} return

    set gamemode $::Data::gamemode
    switch -- $gamemode {
        "ra2" { ::TagList::_load_config [file join $taglist_dir "tags-ra2.cfg"] }
        "yr" { ::TagList::_load_config [file join $taglist_dir "tags-yr.cfg"] }
        "phobos" {
            # Phobos = Ares + Phobos-only tags (tags-phobos.cfg is a supplement)
            ::TagList::_load_config [file join $taglist_dir "tags-ares.cfg"]
            ::TagList::_load_config [file join $taglist_dir "tags-phobos.cfg"] 1
        }
        default {
            ::TagList::_load_config [file join $taglist_dir "tags-ares.cfg"]
        }
    }
    ::TagList::_load_extended [file join $taglist_dir "tags-ext.cfg"]
    set loaded 1
}

# Lazily build the lowercase mirror of tags_dict so case-insensitive
# lookups in check_tag are O(1) instead of a linear nocase scan.
proc ::TagList::_ensure_lower {} {
    variable tags_dict
    variable tags_lower
    variable tags_lower_valid
    if {$tags_lower_valid} return
    set tags_lower [dict create]
    dict for {cat sec} $tags_dict {
        set low [dict create]
        dict for {t _} $sec { dict set low [string tolower $t] 1 }
        dict set tags_lower $cat $low
    }
    set tags_lower_valid 1
}

proc ::TagList::check_tag {tag category} {
    variable tags_dict
    variable regex_dict
    variable tags_lower

    set have_literal [dict exists $tags_dict $category]
    set have_regex [dict exists $regex_dict $category]
    if {!$have_literal && !$have_regex} { return 3 }

    if {$have_literal} {
        set section_dict [dict get $tags_dict $category]

        if {[dict exists $section_dict $tag]} { return 1 }

        ::TagList::_ensure_lower
        if {[dict exists [dict get $tags_lower $category] [string tolower $tag]]} {
            return 2
        }
    }

    if {$have_regex} {
        foreach pat [dict get $regex_dict $category] {
            if {[regexp -- $pat $tag]} { return 1 }
        }
        foreach pat [dict get $regex_dict $category] {
            if {[regexp -nocase -- $pat $tag]} { return 2 }
        }
    }

    return 3
}

# Build the type name -> owning category map.
# Registries are scanned in priority order (TechnoTypes first, Animations last),
# so a name used both as a unit and as an animation - e.g. Mental Omega lists
# VENOM in [Animations] while also defining the aircraft section [VENOM] - is
# attributed to the TechnoType and its section is never judged by another
# category's whitelist. Integer keys mean the registry stores index -> name.
# Country/terrain/smudge registries are not validated themselves, but they are
# listed here because their sections share names with other registries: [Special]
# is a country while the Warheads registry also contains "Special".
proc ::TagList::_build_owner_map {} {
    variable owner_map
    variable owner_map_built

    set owner_map [dict create]
    foreach {category varname} {
        InfantryTypes     infantry
        AircraftTypes     aircraft
        BuildingTypes     buildings
        VehicleTypes      vehicles
        CountryTypes      countries
        TerrainTypes      terrains
        SmudgeTypes       smudges
        WeaponTypes       weapons
        Warheads          warheads
        Projectiles       projectiles
        SuperWeaponTypes  superweapons
        AttachEffectTypes attacheffects
        RadiationTypes    radiationtypes
        ShieldTypes       shieldtypes
        ParticleSystems   particlesys
        Particles         particles
        VoxelAnims        vanims
        Animations        anims
    } {
        if {![info exists ::Data::$varname]} continue
        foreach {key value} [array get ::Data::$varname] {
            if {[string is integer -strict $key]} {
                set name $value
            } else {
                set name $key
            }
            if {$name eq ""} continue
            set map_key [string tolower $name]
            if {![dict exists $owner_map $map_key]} {
                dict set owner_map $map_key $category
            }
        }
    }
    set owner_map_built 1
}

# Category that owns the section [type_name], or "" when nothing declares it.
proc ::TagList::_section_owner {type_name} {
    variable owner_map
    variable owner_map_built

    if {!$owner_map_built} {
        ::TagList::_build_owner_map
    }
    set map_key [string tolower $type_name]
    if {[dict exists $owner_map $map_key]} {
        return [dict get $owner_map $map_key]
    }
    return ""
}

# Collect all property names from a type's sections.
# Returns nothing when the section belongs to another category (see
# ::TagList::_section_owner), so tags are only checked against their own list.
proc ::TagList::_collect_tags {type_name category} {
    set owner [::TagList::_section_owner $type_name]
    if {$owner ne "" && $owner ne $category} {
        return [dict create]
    }

    set tags [dict create]

    if {[info exists ::Data::rawmapdata($type_name)]} {
        foreach line $::Data::rawmapdata($type_name) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set pfx [string trim [string range $line 0 [expr {$eq-1}]]]
            if {$pfx ne ""} {
                if {![dict exists $tags $pfx]} {
                    dict set tags $pfx $type_name
                }
            }
        }
    }
    if {[info exists ::Data::rulesdata($type_name)]} {
        foreach line $::Data::rulesdata($type_name) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set pfx [string trim [string range $line 0 [expr {$eq-1}]]]
            if {$pfx ne ""} {
                if {![dict exists $tags $pfx]} {
                    dict set tags $pfx $type_name
                }
            }
        }
    }
    return $tags
}

# Validate tags for a specific category
proc ::TagList::_validate_category {category data_array} {
    variable warned_tags
    variable audit_mode

    if {![info exists ::Data::$data_array]} return
    if {![array size ::Data::$data_array]} return

    set new_tags [list]

    if {$audit_mode} {
        ::Logging::notice "$category: [array size ::Data::$data_array] types found"
    }

    # Registries keyed by index store index -> name (see data.tcl); the section
    # to validate is the name, not the numeric key, so iterate values there.
    set type_names [list]
    foreach {key value} [array get ::Data::$data_array] {
        if {[string is integer -strict $key] && $value ne ""} {
            lappend type_names $value
        } else {
            lappend type_names $key
        }
    }

    foreach type_name $type_names {
        set tags [::TagList::_collect_tags $type_name $category]

        dict for {tag source_type} $tags {
            if {[dict exists $warned_tags "$category:$tag"]} continue

            set tcode [::TagList::check_tag $tag $category]
            if {$tcode == 2} {
                dict set warned_tags "$category:$tag" 1
                ::Logging::warning "${source_type} Improper tag capitalization: $tag (expected in $category)"
            } elseif {$tcode == 3} {
                dict set warned_tags "$category:$tag" 1
                lappend new_tags $tag
                ::Logging::notice "${source_type} Unknown tag: $tag (not in $category)"
            }
        }
    }
    return [lsort -unique $new_tags]
}

proc ::TagList::_write_new_tags {category new_tags} {
    if {[llength $new_tags] == 0} return

    variable taglist_dir
    set extfile [file join $taglist_dir "tags-ext.cfg"]

    set existing_tags [dict create]
    if {[file exists $extfile]} {
        if {[catch {open $extfile r} fh]} {
            ::Logging::warning "Cannot open $extfile for reading: $fh"
        } else {
            set content [read $fh]
            close $fh

            set current_section ""
            foreach line [split $content "\n"] {
                set line [string trim $line]
                if {$line eq "" || [string index $line 0] eq ";"} continue
                if {[regexp {^\[(\w+)\]$} $line -> section_name]} {
                    set current_section $section_name
                    continue
                }
                if {$current_section ne ""} {
                    dict set existing_tags "$current_section:$line" 1
                }
            }
        }
    }

    set to_write [list]
    foreach tag $new_tags {
        if {![dict exists $existing_tags "$category:$tag"]} {
            lappend to_write $tag
        }
    }

    if {[llength $to_write] == 0} return

    set fh [open $extfile a]
    puts $fh ""
    puts $fh "\[$category\]"
    foreach tag $to_write {
        puts $fh $tag
    }
    close $fh
}

proc ::TagList::validate_all {{audit 1}} {
    variable warned_tags
    variable categories
    variable owner_map_built
    variable audit_mode
    set audit_mode $audit
    set warned_tags [dict create]
    set owner_map_built 0

    ::TagList::init

    foreach {category data_array} $categories {
        set new_tags [::TagList::_validate_category $category $data_array]
        # In audit mode: unknown tags are only logged, not written to tags-ext.cfg
        if {!$audit_mode} {
            ::TagList::_write_new_tags $category $new_tags
        } elseif {[llength $new_tags] > 0} {
            ::Logging::notice "Audit: [llength $new_tags] unknown $category tags (not written to tags-ext.cfg): [join $new_tags {, }]"
        }
    }
}
