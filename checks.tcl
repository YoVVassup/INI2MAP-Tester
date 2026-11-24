#----------------------------------------------------------------------------------------------------------
# checks.tcl - Game logic check framework for INI2MAP Tester
#----------------------------------------------------------------------------------------------------------
# Loads and executes individual check modules from the checks/ directory.
# Each check registers itself via ::Checks::register_check and is executed by run_all.
#----------------------------------------------------------------------------------------------------------

namespace eval ::Checks {
    variable loaded 0
    variable property_cache {}
    variable property_index {}
    variable registered_checks [list]
}

# --------------------------------------------------------------------------
# Build property index for O(1) lookups
# Called once after rulesdata is loaded
# --------------------------------------------------------------------------
proc ::Checks::build_index {} {
    variable property_index
    set property_index [dict create]

    foreach section [array names ::Data::rawmapdata] {
        set idx [dict create]
        foreach line $::Data::rawmapdata($section) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set k [string range $line 0 [expr {$eq-1}]]
            set k [string trim $k]
            if {$k eq ""} continue
            dict set idx $k [string range $line [expr {$eq+1}] end]
        }
        dict set property_index "${section},raw" $idx
    }

    foreach section [array names ::Data::rulesdata] {
        set idx [dict create]
        foreach line $::Data::rulesdata($section) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set k [string range $line 0 [expr {$eq-1}]]
            set k [string trim $k]
            if {$k eq ""} continue
            dict set idx $k [string range $line [expr {$eq+1}] end]
        }
        dict set property_index "${section},rules" $idx
    }
}

# --------------------------------------------------------------------------
# Clear property cache (called before each run_all)
# --------------------------------------------------------------------------
proc ::Checks::clear_cache {} {
    variable property_cache
    variable bh_lists_ready
    variable bh_dock
    variable bh_repair
    variable bh_heli
    variable inviso_idx_ready
    variable inviso_idx
    variable limbo_idx_ready
    variable limbo_idx
    set property_cache {}
    # Derived indexes built lazily by checks from property data -
    # must be invalidated together with property_cache
    set bh_lists_ready 0
    set bh_dock {}
    set bh_repair {}
    set bh_heli {}
    set inviso_idx_ready 0
    set inviso_idx {}
    set limbo_idx_ready 0
    set limbo_idx {}
    catch {array unset ::Checks::_mc_wep_wh}
    catch {array unset ::Checks::_mc_wh_weps}
}

# --------------------------------------------------------------------------
# Register a check procedure to be executed by run_all
# --------------------------------------------------------------------------
proc ::Checks::register_check {proc_name} {
    variable registered_checks
    if {$proc_name ni $registered_checks} {
        lappend registered_checks $proc_name
    }
}

# --------------------------------------------------------------------------
# Boolean helpers
# --------------------------------------------------------------------------
proc ::Checks::is_true {val} {
    set lv [string tolower $val]
    expr {$lv eq "yes" || $lv eq "true" || $lv eq "1" || $lv eq "on"}
}

proc ::Checks::is_false {val} {
    set lv [string tolower $val]
    expr {$lv eq "no" || $lv eq "false" || $lv eq "0" || $lv eq "off"}
}

# --------------------------------------------------------------------------
# Search for a key using pre-built index (O(1))
# --------------------------------------------------------------------------
proc ::Checks::_find_property {section key} {
    variable property_index

    set raw_key "${section},raw"
    if {[dict exists $property_index $raw_key]} {
        set idx [dict get $property_index $raw_key]
        if {[dict exists $idx $key]} {
            return [string trim [dict get $idx $key]]
        }
    }

    set rules_key "${section},rules"
    if {[dict exists $property_index $rules_key]} {
        set idx [dict get $property_index $rules_key]
        if {[dict exists $idx $key]} {
            return [string trim [dict get $idx $key]]
        }
    }

    return ""
}

# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Cached property lookup (O(1) after first access)
# --------------------------------------------------------------------------
proc ::Checks::get_cached_property {type_name key} {
    variable property_cache
    set cache_key "${type_name},${key}"
    if {[dict exists $property_cache $cache_key]} {
        return [dict get $property_cache $cache_key]
    }
    set value [::Checks::_find_property $type_name $key]
    dict set property_cache $cache_key $value
    return $value
}

# --------------------------------------------------------------------------
# Get property from a named section (General, Sides, etc.)
# --------------------------------------------------------------------------
proc ::Checks::get_section_property {section key} {
    ::Checks::_find_property $section $key
}

# --------------------------------------------------------------------------
# Returns combined list of all Techno types (Infantry, Vehicle, Aircraft)
# --------------------------------------------------------------------------
proc ::Checks::get_all_techno_types {} {
    set seen [dict create]
    set all_types [list]
    foreach arr_name {infantry vehicles aircraft} {
        if {[info exists ::Data::$arr_name]} {
            foreach n [array names ::Data::$arr_name] {
                if {![dict exists $seen $n]} {
                    dict set seen $n 1
                    lappend all_types $n
                }
            }
        }
    }
    return $all_types
}

# --------------------------------------------------------------------------
# Load all check modules from the checks/ subdirectory
# --------------------------------------------------------------------------
proc ::Checks::load_modules {} {
    set script_dir [file dirname [info script]]
    set checks_dir [file join $script_dir "checks"]

    # Try explicit loader first (works in freewrap VFS where glob/file isdirectory fail)
    set loader [file join $checks_dir "load_all_checks.tcl"]
    if {[catch {source $loader} err] == 0} {
        return
    }

    # Fallback to glob (works in normal tclsh)
    if {[file isdirectory $checks_dir]} {
        foreach file [glob -nocomplain [file join $checks_dir "*.tcl"]] {
            if {[catch {source $file} err]} {
                ::Logging::warning "Failed to load check module [file tail $file]: $err"
            }
        }
    }
}

# --------------------------------------------------------------------------
# Run all registered checks
# --------------------------------------------------------------------------
proc ::Checks::run_all {} {
    variable registered_checks
    variable loaded

    if {!$loaded} {
        ::Checks::load_modules
        set loaded 1
    }

    ::Checks::clear_cache
    ::Checks::build_index

    foreach check_proc $registered_checks {
        if {[catch {::Checks::$check_proc} err]} {
            ::Logging::error "Check procedure '$check_proc' failed: $err"
        }
    }
}

return
