#----------------------------------------------------------------------------------------------------------
# validators_taskforce_teamtype.tcl - TaskForce and TeamType validation for INI2MAP Tester
# Contains:
#   - validate_taskforces procedure
#   - validate_teamtypes procedure
#   - Uses helper procedures and logging from validators_core.tcl
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------
# TaskForce validation
# --------------------------------------------------------------------------
# --- validate_taskforces ---
# Validates all task force definitions and their unit references.
proc ::Validators::validate_taskforces {} {
    foreach tf [array names ::Data::taskforces] {
        set ::Data::tfowner($tf) {}
        if {![info exists ::Data::rawmapdata($tf)]} continue
        foreach curline $::Data::rawmapdata($tf) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            set idx [lindex $kv 0]
            if {$idx eq "Name"} {
                set ::Data::taskforces($tf) [lindex $kv 1]
                continue
            }
            if {$idx eq "Group"} continue
            set curline [split [lindex $kv 1] ","]
            set qty [lindex $curline 0]
            set unit [lindex $curline 1]
            if {![string is integer -strict $qty]} {
                ::Logging::error "TaskForce \"$tf\" references invalid Unit quantity: $qty"
            } elseif {![info exists ::Data::allunits($unit)]} {
                ::Logging::error "TaskForce \"$tf\" references invalid Unit: $unit"
            }
            set unit_owner ""
            if {[info exists ::Data::rawmapdata($unit)]} {
                foreach uline $::Data::rawmapdata($unit) {
                    set ukv [::util::_parse_keyval $uline]
                    if {$ukv ne "" && [lindex $ukv 0] eq "Owner"} {
                        set unit_owner [lindex $ukv 1]
                        break
                    }
                }
            }
            if {$unit_owner eq "" && [info exists ::Data::owners($unit)]} {
                set unit_owner $::Data::owners($unit)
            }
            if {$unit_owner ne ""} {
                lappend ::Data::tfowner($tf) $unit_owner
            }
        }
    }
}

# --------------------------------------------------------------------------
# TeamType validation
# --------------------------------------------------------------------------
# --- validate_teamtypes ---
# Validates all team type definitions and their properties.
proc ::Validators::validate_teamtypes {} {
    foreach team [array names ::Data::teamtypes] {
        set tname ""
        set teamwp -1
        set tmowner ""
        set ttask ""
        set tscript ""
        if {![info exists ::Data::rawmapdata($team)]} continue
        foreach curline $::Data::rawmapdata($team) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            set pfx [string trim [lindex $kv 0]]
            set tag [string trim [lindex $kv 1]]
            switch -- $pfx {
                "Name" {
                    if {$tag eq ""} continue
                    set ::Data::teamtypes($team) $tag
                }
                "Waypoint" {
                    if {$tag eq ""} continue
                    if {![info exists ::Data::waypoints($tag)]} {
                        ::Logging::error "TeamType \"$team\" has invalid origin Waypoint: [::MapParser::wp2num $tag]"
                    } else {
                        set ::Data::waypoints($tag) 1
                        set teamwp [::MapParser::wp2num $tag]
                    }
                }
                "TransportWaypoint" {
                    if {$tag eq ""} continue
                    if {![info exists ::Data::waypoints($tag)]} {
                        ::Logging::error "TeamType \"$team\" has invalid transport origin Waypoint: [::MapParser::wp2num $tag]"
                    } else {
                        set ::Data::waypoints($tag) 1
                    }
                }
                "TaskForce" {
                    if {![info exists ::Data::taskforces($tag)]} {
                        ::Logging::error "TeamType \"$team\" has invalid TaskForce: $tag"
                    } else {
                        set ::Data::utask($tag) 1
                        set ttask $tag
                    }
                }
                "Script" {
                    if {![info exists ::Data::scripts($tag)]} {
                        ::Logging::error "TeamType \"$team\" has invalid Script: $tag"
                    } else {
                        set ::Data::uscript($tag) 1
                        set tscript $tag
                    }
                }
                "House" {
                    if {![info exists ::Data::countries($tag)]} {
                        ::Logging::error "TeamType \"$team\" has invalid Country: $tag"
                    } else {
                        if {[info exists ::Data::parent($tag)]} {
                            set tmowner $::Data::parent($tag)
                        } else {
                            set tmowner $tag
                        }
                    }
                }
                "Autocreate" {
                    if {$tag eq "yes" && $teamwp != -1} {
                        ::Logging::warning "TeamType \"$team\" is set to Autocreate but has origin Waypoint: $teamwp"
                    } elseif {$teamwp != -1} {
                        set ::Data::waypoints([::MapParser::num2wp $teamwp]) 1
                    }
                }
                "TechLevel" {
                    if {![string is integer -strict $tag] || $tag < -1} {
                        ::Logging::warning "TeamType \"$team\" has TechLevel that may prevent it being created: $tag"
                    }
                }
                "Max" {
                    if {![string is integer -strict $tag] || ($tag < -1 || $tag == 0)} {
                        ::Logging::warning "TeamType \"$team\" has Max value that may prevent it being created: $tag"
                    }
                }
            }
        }
        if {$tmowner eq ""} {
            ::Logging::error "TeamType \"$team\" has missing Country/House"
        }
        if {$tscript eq ""} {
            ::Logging::error "TeamType \"$team\" has missing Script"
        }
        if {$ttask eq ""} {
            ::Logging::error "TeamType \"$team\" has missing TaskForce"
        } elseif {$::Data::paranoid == 1} {
            if {$::Data::strictra2 == 1 || ![::MapParser::mphtest $tmowner $::Data::mismap]} {
                foreach ownset $::Data::tfowner($ttask) {
                    if {$ownset eq ""} continue
                    if {[lsearch -exact [split $ownset ","] $tmowner] == -1} {
                        ::Logging::warning "TeamType \"$team\" ($::Data::teamtypes($team)) has Owner mismatch for TaskForce unit(s): $ttask <-> $tmowner"
                        break
                    }
                }
            }
        }
    }
}