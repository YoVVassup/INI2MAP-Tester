#----------------------------------------------------------------------------------------------------------
# map_parser/core.tcl - Core helper functions for map parsing
# Contains:
#   - num2wp, wp2num
#   - mapbounds, locatrix
#   - statetest, mphtest
#----------------------------------------------------------------------------------------------------------
# All global state is taken from ::Data namespace
#----------------------------------------------------------------------------------------------------------

namespace eval ::MapParser {
    # Guard against double loading
    if {[info exists ::MapParser::core_loaded]} { return }
    variable core_loaded 1
}

# --- num2wp ---
# Convert a numeric waypoint index to its letter designation (e.g. 0->A, 25->Z, 26->AA).
proc ::MapParser::num2wp {waypoint} {
    set orig_wp $waypoint
    if {![string is integer $waypoint] || $waypoint < 0} {return "A"}

    if {$::Data::strictra2 && $waypoint > 25} {
        ::Logging::error "strict RA2: Waypoint $waypoint > 25"
        return "A"
    }

    if {$waypoint < 26} {
        return [format %c [expr {65 + $waypoint}]]
    }

    set waypoint [expr {$waypoint - 26}]
    set first [expr {$waypoint / 26}]
    set second [expr {$waypoint % 26}]

    if {$first > 25} {
        ::Logging::error "invalid Waypoint $orig_wp"
        return "AAA"
    }

    return [format %c [expr {65 + $first}]][format %c [expr {65 + $second}]]
}

# --- wp2num ---
# Convert a waypoint letter designation back to its numeric index.
proc ::MapParser::wp2num {waypoint} {
    set waypoint [string toupper $waypoint]
    set len [string length $waypoint]
    if {$len == 0} {return 0}

    set first [scan [string index $waypoint 0] %c]
    if {$first < 65 || $first > 90} {return 0}

    if {$len == 1} {
        return [expr {$first - 65}]
    }

    set second [scan [string index $waypoint 1] %c]
    if {$second < 65 || $second > 90} {return 0}

    return [expr {($first - 65 + 1) * 26 + ($second - 65)}]
}

# --- is_phobos_event_code ---
# Phobos trigger events always carry three parameters (WAE writes them with
# P1=2 so the game reads a third one); every other event code keeps two.
# Shares the PHOBOS_EVENT_PARAM3_RANGES list with validators/core.tcl.
proc ::MapParser::is_phobos_event_code {code} {
    return [::Constants::code_in_ranges $code $::Constants::PHOBOS_EVENT_PARAM3_RANGES]
}

# --- mapbounds ---
# Compute map boundaries and playable area from the map size string.
proc ::MapParser::mapbounds {msize} {
    set msize [split $msize ","]
    if {[llength $msize] < 4} {
        ::Logging::error "Invalid map size format: expected at least 4 comma-separated values"
        return
    }
    set mapx [lindex $msize 2]
    set mapy [lindex $msize 3]
    if {![string is integer -strict $mapx] || ![string is integer -strict $mapy]} {
        ::Logging::error "Invalid map size values: X=$mapx, Y=$mapy (must be integers)"
        return
    }

    if {$mapx == $mapy} {
        set ::Data::maspect 0
    } elseif {$mapx > $mapy} {
        set ::Data::maspect 1
        set ::Data::minx [expr {$mapy - 1}]
        set ::Data::miny [expr {$mapy - 1}]
        set ::Data::maxx [expr {$mapx + 1}]
        set ::Data::maxy [expr {$mapx + 1}]
    } else {
        set ::Data::maspect 1
        set ::Data::minx [expr {$mapx - 1}]
        set ::Data::miny [expr {$mapx - 1}]
        set ::Data::maxx [expr {$mapy + 1}]
        set ::Data::maxy [expr {$mapy + 1}]
    }

    set ::Data::corner(tlx) 1
    set ::Data::corner(tly) $mapx
    set ::Data::corner(trx) $mapx
    set ::Data::corner(try) 1
    set ::Data::corner(blx) $mapy
    set ::Data::corner(bly) [expr {$mapx + $mapy}]
    set ::Data::corner(brx) [expr {$mapx + $mapy}]
    set ::Data::corner(bry) $mapy

    set oddx [expr {$mapx % 2}]
    set oddy [expr {$mapy % 2}]
    if {!$oddx && !$oddy} {
        incr ::Data::corner(bly) -1
        incr ::Data::corner(brx) -1
    } elseif {!$oddx && $oddy} {
        incr ::Data::corner(brx) -1
    } elseif {$oddx && !$oddy} {
        incr ::Data::corner(brx) -1
    } elseif {$oddx && $oddy} {
        incr ::Data::corner(bly)
        incr ::Data::corner(brx)
    }
}

# --- locatrix ---
# Test whether a coordinate pair falls within the playable map area.
proc ::MapParser::locatrix {testx testy} {
    # corner[] is only populated by mapbounds; when [Map] is absent or Size is
    # broken the old guard (maspect only - data.tcl initializes it to 0) did not
    # trip and $::Data::corner(brx) threw "no such array element", aborting the
    # whole map parse via the orchestrator catch. Be permissive instead.
    if {![info exists ::Data::maspect] || ![info exists ::Data::corner(brx)]} {return 1}

    if {![string is integer $testx] || ![string is integer $testy]} {
        return 0
    } elseif {$testx < 0 || $testy < 0} {
        return 0
    } elseif {$testx > $::Data::corner(brx) || $testy > $::Data::corner(bly)} {
        return 0
    }

    set ttype ""
    if {$::Data::maspect} {
        if {$testx > $::Data::minx && $testx < $::Data::maxx && $testy > $::Data::miny && $testy < $::Data::maxy} {
            return 1
        }
    }

    if {$testx <= $::Data::corner(trx) && $testy <= $::Data::corner(tly)} {
        set ttype "a"
    } elseif {$testx > $::Data::corner(trx) && $testy <= $::Data::corner(bry)} {
        set ttype "b"
    } elseif {$testx > $::Data::corner(blx) && $testy > $::Data::corner(bry)} {
        set ttype "c"
    } elseif {$testx <= $::Data::corner(blx) && $testy > $::Data::corner(tly)} {
        set ttype "d"
    }

    switch -- $ttype {
        a {
            set foo [expr {$::Data::corner(trx) - $testx}]
            if {$testy > $foo} {return 1}
        }
        b {
            set foo [expr {$testx - $::Data::corner(trx)}]
            if {$testy > $foo} {return 1}
        }
        c {
            set foo [expr {$::Data::corner(bly) - $testy}]
            set bar [expr {$testx - $::Data::corner(blx)}]
            if {$foo > $bar} {return 1}
        }
        d {
            set foo [expr {$testy - $::Data::corner(tly)}]
            if {$testx > $foo} {return 1}
        }
    }
    return 0
}

# --- statetest ---
# Validate that a unit placement state is permissible for the given unit type.
proc ::MapParser::statetest {{state "none"} {unit "dummy"}} {
    if {![info exists ::Data::harvy]} { array set ::Data::harvy [list] }
    switch -exact -- $state {
        "Sleep" - "Sticky" - "Guard" - "Hunt" - "Harmless" - "Area Guard" {
            return 1
        }
        "Harvest" {
            if {[info exists ::Data::harvy($unit)]} {return 1}
        }
    }
    return 0
}

# --- mphtest ---
# Check whether a house is valid for the current multiplayer map type.
proc ::MapParser::mphtest {house mismap} {
    if {$mismap == 0 && ![string match {<Player @ ?>} $house]} {return 0}
    return 1
}