#----------------------------------------------------------------------------------------------------------
# map_parser/celltags_house_data.tcl - Processing CellTags and per-house building data
# Contains:
#   - process_celltags
#   - process_house_data
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

namespace eval ::MapParser {
    # Guard against double loading
    if {[info exists ::MapParser::celltags_house_loaded]} { return }
    variable celltags_house_loaded 1
}

# --- process_celltags ---
# Validate CellTag entries, checking that attached tags exist and coordinates are in-bounds.
proc ::MapParser::process_celltags {} {
    if {![info exists ::Data::rawmapdata(CellTags)]} return
    foreach curline $::Data::rawmapdata(CellTags) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set coords [lindex $kv 0]
        set tag [string trim [lindex $kv 1]]
        if {$tag eq "" || ![info exists ::Data::tags($tag)]} {
            ::Logging::error "Celltag \"$coords\" has invalid attached Tag: $tag"
        } else {
            # Collected for the event-attachment checks (validators/trigger_integrity.tcl)
            set ::Data::tagcelltags($tag) ""
        }
        if {$::Data::newini} {
            set newk [scan $coords %d]
            # scan gives "" for a non-numeric key; skip the bounds check
            # instead of crashing expr (which aborts the whole map parse)
            if {[string is integer -strict $newk]} {
                set ny [expr {$newk / 1000}]
                set nx [expr {$newk % 1000}]
                if {![::MapParser::locatrix $nx $ny]} {
                    ::Logging::warning "placed CellTag \"$coords\" falls outside usable map area"
                }
            }
        }
    }
    unset ::Data::rawmapdata(CellTags)
}

# --- process_house_data ---
# Validate per-house building node data, checking building types and coordinates.
proc ::MapParser::process_house_data {cunt} {
    if {![info exists ::Data::rawmapdata($cunt)]} return
    # B24 (WAE event 32): capture Country / PlayerControl / base nodes while
    # the house section is still live. WAE House.ReadFromIniSection reads the
    # D3 keys (000..999) sequentially until the first missing one; NodeCount
    # does not take part in reading.
    set ::Data::house_country($cunt) ""
    set ::Data::house_playerctl($cunt) 0
    set ::Data::house_basenodes($cunt) {}
    array set hsect {}
    foreach curline $::Data::rawmapdata($cunt) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        # first occurrence wins (same as the Country= pass in process_houses)
        set hkey [lindex $kv 0]
        if {![info exists hsect($hkey)]} {
            set hsect($hkey) [lindex $kv 1]
        }
    }
    if {[info exists hsect(Country)]} {
        set ::Data::house_country($cunt) [string trim $hsect(Country)]
    }
    if {[info exists hsect(PlayerControl)]} {
        set ::Data::house_playerctl($cunt) [string is true -strict [string trim $hsect(PlayerControl)]]
    }
    for {set nidx 0} {$nidx < 1000} {incr nidx} {
        set nkey [format %03d $nidx]
        if {![info exists hsect($nkey)]} break
        set node [split $hsect($nkey) ","]
        if {[llength $node] == 3} {
            lappend ::Data::house_basenodes($cunt) [string trim [lindex $node 0]]
        }
    }
    array unset hsect
    set nodes 0
    foreach curline $::Data::rawmapdata($cunt) {
        set kv [::util::_parse_keyval $curline]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set tag [lindex $kv 1]
        if {$pfx eq "NodeCount" && $tag > 0} {
            set nodes $tag
        }
    }
    if {$nodes > 0} {
        set ncnt 0
        foreach curline $::Data::rawmapdata($cunt) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            set pfx [lindex $kv 0]
            if {[string match {[0-9][0-9][0-9]} $pfx]} {
                if {[scan $pfx %d] > $nodes} {
                    ::Logging::warning "House \"$cunt\" building node (index: $pfx) exceeds NodeCount"
                }
                incr ncnt
                set tag [split [lindex $kv 1] ","]
                if {[llength $tag] != 3} {
                    ::Logging::error "House \"$cunt\" building Node (index: $pfx) has missing values"
                    continue
                }
                set bldg [lindex $tag 0]
                if {![info exists ::Data::buildings($bldg)]} {
                    ::Logging::error "House \"$cunt\" building Node (index: $pfx) refers to invalid BuildingType: $bldg"
                    continue
                }
                set nx [lindex $tag 1]
                set ny [lindex $tag 2]
                if {![string is integer $nx] || ![string is integer $ny]} {
                    ::Logging::error "House \"$cunt\" building Node (index: $pfx) has non-numeric coordinate values"
                    continue
                }
                if {![::MapParser::locatrix $nx $ny]} {
                    ::Logging::warning "House \"$cunt\" building Node (coords: $nx,$ny) falls outside usable map area"
                }
            }
        }
        if {$ncnt < $nodes} {
            ::Logging::warning "House \"$cunt\" building nodes insufficient for NodeCount: $ncnt <-> $nodes"
        }
    }
    unset ::Data::rawmapdata($cunt)
}