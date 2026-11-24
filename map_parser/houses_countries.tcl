#----------------------------------------------------------------------------------------------------------
# map_parser/houses_countries.tcl - Processing Houses, Countries, VariableNames, Waypoints, Header
# Contains:
#   - process_houses, process_countries, process_variablenames
#   - process_waypoints, process_header
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

namespace eval ::MapParser {
    # Guard against double loading
    if {[info exists ::MapParser::houses_countries_loaded]} { return }
    variable houses_countries_loaded 1
}

# --- process_houses ---
# Parse the [Houses] section and resolve each house's country assignment.
proc ::MapParser::process_houses {} {
    set ::Data::houselist {}
    set ::Data::housecnt 0
    if {![info exists ::Data::rawmapdata(Houses)]} return
    set temphouse {}
    foreach curline $::Data::rawmapdata(Houses) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set tag [lindex $kv 1]
        if {$tag eq ""} continue
        lappend temphouse $tag
        if {![info exists ::Data::houses($tag)]} {
            set ::Data::houses($tag) ""
        } else {
            # B12: duplicate house ININame corrupts the in-game house list
            # (WAE MapIssueChecker DuplicateHouseININame)
            ::Logging::notice "The map has multiple houses named \"$tag\"! This will result in a corrupted house list in-game!"
        }
    }
    # B24: keep count and order of the [Houses] entries - WAE
    # IsLikelyMultiplayer uses Houses.Count and Houses.Find returns the first
    # house whose HouseType matches, in list order.
    set ::Data::houselist $temphouse
    set ::Data::housecnt [llength $temphouse]
    unset ::Data::rawmapdata(Houses)
    if {[llength $temphouse] > 0} {
        set ::Data::mhouses 1
        foreach haus $temphouse {
            if {![info exists ::Data::rawmapdata($haus)]} {
                ::Logging::error "map defined House \"$haus\" not found or no data"
                continue
            }
            set has_country 0
            foreach curline $::Data::rawmapdata($haus) {
                set kv [::util::_parse_keyval $curline]
                if {$kv eq ""} continue
                foreach {pfx tag} $kv { break }
                if {$pfx eq "Country"} {
                    if {[info exists ::Data::countries($tag)]} {
                        set ::Data::changeidx($::Data::countries($tag)) $tag
                    } else {
                        incr ::Data::countrycnt
                        set ::Data::changeidx($::Data::countrycnt) $tag
                        if {![info exists ::Data::rawmapdata($tag)]} {
                            ::Logging::error "map defined House \"$haus\" has invalid Country specified: $tag"
                        }
                    }
                    set has_country 1
                    break
                }
            }
            # B14: section exists but never mentions Country= (WAE InvalidCountry)
            if {!$has_country} {
                ::Logging::warning "map defined House \"$haus\" has no Country= specified. This makes it default to the first standard Country."
            }
            # Second pass over the section: validate Allies= (WAE NonexistentAlliedHouse)
            foreach curline $::Data::rawmapdata($haus) {
                set kv [::util::_parse_keyval $curline]
                if {$kv eq ""} continue
                if {[lindex $kv 0] ne "Allies"} continue
                foreach ally [split [lindex $kv 1] ","] {
                    set ally [string trim $ally]
                    if {$ally eq ""} continue
                    if {![info exists ::Data::houses($ally)]} {
                        ::Logging::warning "House with name $ally was not found when loading up allies for the house $haus. Skipping the alliance."
                    }
                }
            }
        }
    } else {
        array set ::Data::houses [array get ::Data::countries]
        foreach haus [array names ::Data::countries] {set ::Data::rawmapdata($haus) ""}
    }
}

# --- process_countries ---
# Parse [Countries] and ParentCountry entries, building the country index mapping.
proc ::MapParser::process_countries {} {
    # First, process map-defined countries to fill changeidx with correct indices
    if {[info exists ::Data::rawmapdata(Countries)]} {
        foreach curline $::Data::rawmapdata(Countries) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            foreach {idx name} $kv { break }
            if {![info exists ::Data::countries($name)]} {
                set ::Data::countries($name) ""
            }
            # Store the mapping from numeric index to country name (for use in validate_country_index)
            if {[string is integer -strict $idx]} {
                set ::Data::changeidx($idx) $name
            } else {
                ::Logging::warning "[Countries] entry \"$curline\" has non-integer index: $idx"
            }
        }
        unset ::Data::rawmapdata(Countries)
    }

    # Then process ParentCountry for each country (if sections exist)
    foreach cunt [array names ::Data::countries] {
        if {![info exists ::Data::rawmapdata($cunt)]} {continue}
        foreach curline $::Data::rawmapdata($cunt) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            set pfx [lindex $kv 0]
            set tag [string trim [lindex $kv 1]]
            if {$pfx eq "ParentCountry"} {
                if {![info exists ::Data::countries($tag)]} {
                    ::Logging::error "map defined Country \"$cunt\" has invalid ParentCountry specified: $tag"
                } else {
                    set ::Data::parent($cunt) $tag
                }
                break
            }
        }
    }
}

# --- process_variablenames ---
# Parse [VariableNames] to register global and local named variables.
proc ::MapParser::process_variablenames {} {
    if {![info exists ::Data::rawmapdata(VariableNames)]} return
    array set seen_idx {}
    foreach curline $::Data::rawmapdata(VariableNames) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set tag [lindex $kv 0]
        set value [lindex $kv 1]
        # B19: index / duplicate / syntax validation (WAE ReadLocalVariables)
        if {![string is integer -strict $tag]} {
            ::Logging::warning "Invalid local variable index in entry $tag: $value, skipping reading local variable."
            continue
        }
        if {[info exists seen_idx($tag)]} {
            ::Logging::warning "Duplicate local variable index in entry $tag: $value, skipping reading local variable."
            continue
        }
        set varval [split $value ","]
        if {[llength $varval] != 2} {
            ::Logging::warning "Invalid local variable syntax in entry $tag: $value, skipping reading local variable."
            continue
        }
        set seen_idx($tag) 1
        set name [lindex $varval 0]
        if {[string match "Global.*" $name]} {
            set globalname [string range $name 7 end]
            if {![info exists ::Data::globalvars($tag)]} {set ::Data::globalvars($tag) $globalname}
            set ::Data::uglobal($tag) 0
        } else {
            if {![info exists ::Data::variables($tag)]} {set ::Data::variables($tag) $name}
            set ::Data::uvars($tag) 0
        }
    }
    unset ::Data::rawmapdata(VariableNames)
}

# --- process_waypoints ---
# Parse [Waypoints] section, registering waypoint usage and validating coordinates.
proc ::MapParser::process_waypoints {} {
    set ::Data::waypoints(A) 0
    set ::Data::wpcoords(999) "0,0"
    if {![info exists ::Data::rawmapdata(Waypoints)]} return
    foreach curline $::Data::rawmapdata(Waypoints) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set wp [lindex $kv 0]
        set pfx [lindex $kv 1]
        # B22: waypoint index must be a non-negative integer
        # (WAE Constants.MaxWaypoint / Waypoint.ParseWaypoint).
        # Range checks are delegated to num2wp() below, which already errors
        # on wp >= MAX_WAYPOINTS_YR (702) in every mode and on wp > 25 in
        # strict RA2 mode - together covering every index outside the mode's
        # limit (constants.tcl: MAX_WAYPOINTS_RA2 / MAX_WAYPOINTS_YR, selected
        # via the same ::Data::strictra2 switch as validators/report_unused.tcl).
        # Here only what num2wp() silently maps to "A" is reported: non-integer
        # and negative indices.
        set idx_ok 1
        if {![string is integer -strict $wp] || $wp < 0} {
            set idx_ok 0
        }
        set nom [::MapParser::num2wp $wp]
        if {![info exists ::Data::waypoints($nom)]} {set ::Data::waypoints($nom) 0}
        if {!$idx_ok} {
            ::Logging::warning "Invalid syntax encountered for waypoint: $wp=$pfx"
        }
        if {$::Data::newini} {
            # B22: coordinate string must satisfy Helpers.CoordStringToPoint:
            # a non-negative integer of at least 4 digits (last 3 = X, rest = Y)
            set coord_ok 1
            if {![string is integer -strict $pfx] || $pfx < 0 || [string length $pfx] < 4} {
                set coord_ok 0
            }
            if {!$coord_ok} {
                ::Logging::warning "Invalid syntax encountered for waypoint: $wp=$pfx"
            } else {
                set nx [scan [string range $pfx end-2 end] %d]
                set ny [scan [string range $pfx 0 end-3] %d]
                if {![::MapParser::locatrix $nx $ny]} {
                    ::Logging::warning "placed Waypoint \"$wp\" (coords: $nx,$ny) falls outside usable map area"
                }
                set ::Data::wpcoords($wp) "$nx,$ny"
            }
        }
    }
    unset ::Data::rawmapdata(Waypoints)
}

# --- process_header ---
# Parse [Header] section for multiplayer start waypoints and default house assignments.
proc ::MapParser::process_header {} {
    set ::Data::mphouses(9999) ""
    if {![info exists ::Data::rawmapdata(Header)]} {
        set ::Data::mismap 1
        return
    }
    foreach curline $::Data::rawmapdata(Header) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        foreach {pfx val} $kv { break }
        switch -- $pfx {
            "Waypoint1" - "Waypoint2" - "Waypoint3" - "Waypoint4" -
            "Waypoint5" - "Waypoint6" - "Waypoint7" - "Waypoint8" {
                if {$val ne "0,0"} {
                    scan $pfx "Waypoint%d" nom
                    incr nom -1
                    set wpname [::MapParser::num2wp $nom]
                    set ::Data::waypoints($wpname) 1
                }
            }
        }
    }
    unset ::Data::rawmapdata(Header)
    if {$::Data::mismap == 0 && [info exists ::Data::strictra2] && $::Data::strictra2 != 1} {
        array set ::Data::mphouses {4475 A 4476 B 4477 C 4478 D 4479 E 4480 F 4481 G 4482 H}
        unset ::Data::mphouses(9999)
        array set ::Data::countries "{<Player @ A>} {} {<Player @ B>} {} {<Player @ C>} {} {<Player @ D>} {} {<Player @ E>} {} {<Player @ F>} {} {<Player @ G>} {} {<Player @ H>} {}"
    }
}