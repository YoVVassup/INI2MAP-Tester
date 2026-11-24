# checks/aggressive_transport_teams.tcl
# Validates that TeamTypes with Aggressive=yes do not contain armed transport units, which can trigger the Build Anywhere Bug
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_aggressive_transport_teams {} {
    upvar ::Data::teamtypes teamtypes
    upvar ::Data::rawmapdata rawmapdata
    upvar ::Data::taskforces taskforces

    if {![info exists teamtypes]} return

    foreach team [array names teamtypes] {
        if {![info exists rawmapdata($team)]} continue

        set ttask ""
        set aggressive "no"

        foreach curline $rawmapdata($team) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            set pfx [string trim [lindex $kv 0]]
            set tag [string trim [lindex $kv 1]]
            switch -- $pfx {
                "TaskForce" { set ttask $tag }
                "Aggressive" { set aggressive $tag }
            }
        }

        if {![::Checks::is_true $aggressive] || $ttask eq ""} continue
        if {![info exists taskforces($ttask)] || ![info exists rawmapdata($ttask)]} continue

        set has_transport 0
        set unit ""

        foreach curline $rawmapdata($ttask) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            set idx [lindex $kv 0]
            if {$idx eq "Name" || $idx eq "Group"} continue
            set line [split [lindex $kv 1] ","]
            set unit [lindex $line 1]
            set passengers [::Checks::get_cached_property $unit "Passengers"]
            if {[string is integer -strict $passengers] && $passengers > 0} {
                set has_transport 1
                break
            }
        }

        if {$has_transport} {
            ::Logging::warning "TeamType \"$team\" ($teamtypes($team)) has Aggressive=yes and contains at least one transport unit (e.g., $unit). This combination can cause the 'Build Anywhere Bug' if the transport is armed. Consider setting Aggressive=no or using unarmed transports."
        }
    }
}

# Register this check
::Checks::register_check "validate_aggressive_transport_teams"