#----------------------------------------------------------------------------------------------------------
# test_report_unused.tcl - Unit tests for validators/report_unused.tcl
# Tests: report_unused (unused teamtypes, taskforces, scripts, waypoints, variables)
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir map_parser.tcl]
source [file join $script_dir validators.tcl]

proc reset_state {} {
    array unset ::Data::teamtypes
    array unset ::Data::taskforces
    array unset ::Data::scripts
    array unset ::Data::waypoints
    array unset ::Data::variables
    array unset ::Data::globalvars
    array unset ::Data::uteam
    array unset ::Data::utask
    array unset ::Data::uscript
    array unset ::Data::uvars
    array unset ::Data::uglobal
    array unset ::Data::ai_defs
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    set ::Data::strictra2 0
}

proc has_notice {pattern} {
    foreach msg $::Data::maperr {
        if {[string match $pattern $msg]} { return 1 }
    }
    return 0
}

# --------------------------------------------------------------------------
# Test 1: Unused teamtype reported
# --------------------------------------------------------------------------
test ru-unused-teamtype "unused teamtype is reported" -body {
    reset_state
    set ::Data::teamtypes(TT1) "Team One"
    ::Validators::report_unused
    has_notice "NOTICE -> unused TeamType: TT1*"
} -result 1

# --------------------------------------------------------------------------
# Test 2: Used teamtype not reported
# --------------------------------------------------------------------------
test ru-used-teamtype "used teamtype is not reported" -body {
    reset_state
    set ::Data::teamtypes(TT1) "Team One"
    set ::Data::uteam(TT1) 1
    ::Validators::report_unused
    expr {![has_notice "NOTICE -> unused TeamType: TT1*"]}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Unused taskforce reported
# --------------------------------------------------------------------------
test ru-unused-taskforce "unused taskforce is reported" -body {
    reset_state
    set ::Data::taskforces(TF1) "Force One"
    ::Validators::report_unused
    has_notice "NOTICE -> unused TaskForce: TF1*"
} -result 1

# --------------------------------------------------------------------------
# Test 4: Unused script reported
# --------------------------------------------------------------------------
test ru-unused-script "unused script is reported" -body {
    reset_state
    set ::Data::scripts(S1) "Script One"
    ::Validators::report_unused
    has_notice "NOTICE -> unused Script: S1*"
} -result 1

# --------------------------------------------------------------------------
# Test 5: Waypoint capacity reported (YR mode)
# --------------------------------------------------------------------------
test ru-waypoint-capacity-yr "waypoint capacity reported in YR mode" -body {
    reset_state
    set ::Data::strictra2 0
    ::Validators::report_unused
    has_notice "NOTICE -> available Waypoints remaining:*"
} -result 1

# --------------------------------------------------------------------------
# Test 6: Waypoint capacity reported (RA2 mode)
# --------------------------------------------------------------------------
test ru-waypoint-capacity-ra2 "waypoint capacity reported in RA2 mode" -body {
    reset_state
    set ::Data::strictra2 1
    ::Validators::report_unused
    has_notice "NOTICE -> available Waypoints remaining:*"
} -result 1

# --------------------------------------------------------------------------
# Test 7: Unused variable reported
# --------------------------------------------------------------------------
test ru-unused-variable "unused variable is reported" -body {
    reset_state
    set ::Data::variables(0) "Alpha"
    ::Validators::report_unused
    has_notice "NOTICE -> unused Variable: 0*"
} -result 1

# --------------------------------------------------------------------------
# Test 8: Unused global variable reported
# --------------------------------------------------------------------------
test ru-unused-global "unused global variable is reported" -body {
    reset_state
    set ::Data::globalvars(0) "Alpha"
    ::Validators::report_unused
    has_notice "NOTICE -> unused Global Variable: 0*"
} -result 1

# --------------------------------------------------------------------------
# Test 9: AI-module (aimo/rules) definitions are never reported as unused
# --------------------------------------------------------------------------
test ru-ai-teamtype "AI-module teamtype is not reported" -body {
    reset_state
    set ::Data::teamtypes(05FC075C-G) "Global Team"
    set ::Data::ai_defs(05FC075C-G) 1
    ::Validators::report_unused
    expr {![has_notice "NOTICE -> unused TeamType: 05FC075C-G*"]}
} -result 1

test ru-ai-taskforce "AI-module taskforce is not reported" -body {
    reset_state
    set ::Data::taskforces(FOETF061-G) "Global Force"
    set ::Data::ai_defs(FOETF061-G) 1
    ::Validators::report_unused
    expr {![has_notice "NOTICE -> unused TaskForce: FOETF061-G*"]}
} -result 1

test ru-ai-script "AI-module script is not reported" -body {
    reset_state
    set ::Data::scripts(08A29DBC-G) "Global Script"
    set ::Data::ai_defs(08A29DBC-G) 1
    ::Validators::report_unused
    expr {![has_notice "NOTICE -> unused Script: 08A29DBC-G*"]}
} -result 1

test ru-ai-globalvar "rules-defined global variable is not reported" -body {
    reset_state
    set ::Data::globalvars(0) "Alpha"
    set ::Data::ai_defs(0) 1
    ::Validators::report_unused
    expr {![has_notice "NOTICE -> unused Global Variable: 0*"]}
} -result 1

# --------------------------------------------------------------------------
# Test 10: Empty state - only capacity notice
# --------------------------------------------------------------------------
test ru-empty "empty state produces only capacity notice" -body {
    reset_state
    ::Validators::report_unused
    expr {$::Logging::notice_count == 1 && [has_notice "NOTICE -> available Waypoints remaining:*"]}
} -result 1

# --------------------------------------------------------------------------
# Test 11: Used waypoint not reported
# --------------------------------------------------------------------------
test ru-used-waypoint "used waypoint is not reported" -body {
    reset_state
    set ::Data::waypoints(A) 1
    set ::Data::waypoints(B) 0
    ::Validators::report_unused
    list [expr {![has_notice "NOTICE -> unused Waypoint: 0 (A)"]}] \
         [has_notice "NOTICE -> unused Waypoint: 1 (B)"]
} -result {1 1}

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
