#----------------------------------------------------------------------------------------------------------
# validators_report_unused.tcl - Reporting unused elements for INI2MAP Tester
# Contains:
#   - report_unused procedure
#   - Optimized reporting for waypoints, teamtypes, taskforces, scripts, variables
#   - Shows remaining waypoint capacity based on strict RA2 mode or YR/Ares
#   - Uses helper procedures and logging from validators_core.tcl
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Report of unused elements (optimized for large waypoint arrays)
# --------------------------------------------------------------------------
# --- report_unused ---
# Reports unused elements like team types, task forces, scripts, and waypoints.
proc ::Validators::report_unused {} {
    # Only map-declared elements are reported: definitions coming from the AI
    # module (aimo) or the global rules are consumed by global AITriggers and
    # engine side, they are not expected to be referenced by the map itself.
    foreach tag [lsort [array names ::Data::teamtypes]] {
        if {[info exists ::Data::ai_defs($tag)]} continue
        if {![info exists ::Data::uteam($tag)]} {
            ::Logging::notice "unused TeamType: $tag ($::Data::teamtypes($tag))"
        }
    }
    foreach tag [lsort [array names ::Data::taskforces]] {
        if {[info exists ::Data::ai_defs($tag)]} continue
        if {![info exists ::Data::utask($tag)]} {
            ::Logging::notice "unused TaskForce: $tag ($::Data::taskforces($tag))"
        }
    }
    foreach tag [lsort [array names ::Data::scripts]] {
        if {[info exists ::Data::ai_defs($tag)]} continue
        if {![info exists ::Data::uscript($tag)]} {
            ::Logging::notice "unused Script: $tag ($::Data::scripts($tag))"
        }
    }

    # Optimized waypoint reporting: get sorted keys, then check values
    set wp_keys [lsort [array names ::Data::waypoints]]
    set single_wps {}
    set double_wps {}
    foreach wp $wp_keys {
        if {[string length $wp] == 1 && $::Data::waypoints($wp) != 1} {
            lappend single_wps $wp
        } elseif {[string length $wp] == 2 && $::Data::waypoints($wp) != 1} {
            lappend double_wps $wp
        }
    }
    foreach wp $single_wps {
        ::Logging::notice "unused Waypoint: [::MapParser::wp2num $wp] ($wp)"
    }
    foreach wp $double_wps {
        ::Logging::notice "unused Waypoint: [::MapParser::wp2num $wp] ($wp)"
    }

    if {[info exists ::Data::strictra2] && $::Data::strictra2} {
        set wps [array size ::Data::waypoints]
        ::Logging::notice "available Waypoints remaining: [expr {max(0, $::Constants::MAX_WAYPOINTS_RA2 - $wps)}]"
    } else {
        set wps [array size ::Data::waypoints]
        ::Logging::notice "available Waypoints remaining: [expr {max(0, $::Constants::MAX_WAYPOINTS_YR - $wps)}]"
    }

    if {[info exists ::Data::variables]} {
        foreach var [lsort [array names ::Data::variables]] {
            if {[info exists ::Data::ai_defs($var)]} continue
            if {![info exists ::Data::uvars($var)]} {
                ::Logging::notice "unused Variable: $var ($::Data::variables($var))"
            }
        }
    }
    if {[info exists ::Data::globalvars]} {
        foreach var [lsort [array names ::Data::globalvars]] {
            if {[info exists ::Data::ai_defs($var)]} continue
            if {![info exists ::Data::uglobal($var)]} {
                ::Logging::notice "unused Global Variable: $var ($::Data::globalvars($var))"
            }
        }
    }
}