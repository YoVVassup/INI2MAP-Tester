#----------------------------------------------------------------------------------------------------------
# aicheck/art_check.tcl - ART data validation
#----------------------------------------------------------------------------------------------------------

proc ::AICheck::check_art_data {} {
    set all_objects [dict create]
    foreach arr_name {infantry vehicles aircraft buildings} {
        if {[info exists ::Data::$arr_name]} {
            foreach n [array names ::Data::$arr_name] {
                dict set all_objects $n 1
            }
        }
    }

    set missing_art 0
    dict for {obj _} $all_objects {
        if {![info exists ::Data::rulesdata($obj)]} {
            ::Logging::warning "Object \"$obj\" has no rules data"
            incr missing_art
            continue
        }
        if {[llength $::Data::rulesdata($obj)] == 0} {
            ::Logging::warning "Object \"$obj\" has empty rules data"
            incr missing_art
        }
    }

    set art_objects [dict create]
    if {[info exists ::Data::rulesdata]} {
        foreach section [array names ::Data::rulesdata] {
            if {$section eq ""} continue
            if {[dict exists $all_objects $section]} {
                dict set art_objects $section 1
            }
        }
    }

    dict for {obj _} $all_objects {
        if {[dict exists $art_objects $obj]} {
            set in_art [info exists ::Data::art_sections($obj)]
            if {!$in_art} {
                set image_name [::AICheck::_get_image_from_rules $obj]
                if {$image_name ne ""} {
                    continue
                }
                ::Logging::warning "Object \"$obj\" has missing ART data"
            }
            continue
        }

        set has_map [info exists ::Data::rawmapdata($obj)]
        if {!$has_map} {
            ::Logging::warning "Object \"$obj\" has missing ART data"
            continue
        }

        set in_art [info exists ::Data::art_sections($obj)]
        if {$in_art} {
            continue
        }

        set image_name [::AICheck::_get_image_from_map $obj]
        if {$image_name ne ""} {
            continue
        }

        ::Logging::warning "Object \"$obj\" has missing ART data"
    }

    return $missing_art
}

proc ::AICheck::_get_image_from_rules {obj} {
    if {![info exists ::Data::rulesdata($obj)]} { return "" }
    foreach line $::Data::rulesdata($obj) {
        set kv [::util::_parse_keyval $line]
        if {$kv ne "" && [lindex $kv 0] eq "Image"} {
            return [lindex $kv 1]
        }
    }
    return ""
}

proc ::AICheck::_get_image_from_map {obj} {
    if {![info exists ::Data::rawmapdata($obj)]} { return "" }
    foreach line $::Data::rawmapdata($obj) {
        set kv [::util::_parse_keyval $line]
        if {$kv ne "" && [lindex $kv 0] eq "Image"} {
            return [lindex $kv 1]
        }
    }
    return ""
}
