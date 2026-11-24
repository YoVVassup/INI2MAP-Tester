#----------------------------------------------------------------------------------------------------------
# test_validators_core.tcl - Unit tests for validators/core.tcl
# Tests: validate_event_code, validate_action_code, validate_script_code, validate_country_index
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
    array unset ::Data::rawmapdata
    array unset ::Data::changeidx
    array unset ::Data::mphouses
    unset -nocomplain ::Data::countrycnt
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
}

# Run one code-range check for $code of $kind under gamemode $mode.
# Returns 1 when the code is accepted, 0 when it is rejected.
proc check_code {mode kind code} {
    reset_state
    set ::Data::gamemode $mode
    switch -- $kind {
        event  { ::Validators::validate_event_code "T1" "test" $code }
        action { ::Validators::validate_action_code "T1" "test" $code }
        script { ::Validators::validate_script_code "S1" 1 $code }
    }
}

# --------------------------------------------------------------------------
# validate_event_code tests
# --------------------------------------------------------------------------
test event-code-valid-ra2 "event code 59 is valid in RA2" -body {
    reset_state
    set ::Data::gamemode "ra2"
    ::Validators::validate_event_code "T1" "test" 59
} -result 1

test event-code-invalid-ra2 "event code 60 is invalid in RA2" -body {
    reset_state
    set ::Data::gamemode "ra2"
    ::Validators::validate_event_code "T1" "test" 60
} -result 0

test event-code-valid-yr "event code 61 is valid in YR" -body {
    reset_state
    set ::Data::gamemode "yr"
    ::Validators::validate_event_code "T1" "test" 61
} -result 1

test event-code-invalid-yr "event code 62 is invalid in YR" -body {
    reset_state
    set ::Data::gamemode "yr"
    ::Validators::validate_event_code "T1" "test" 62
} -result 0

test event-code-valid-ares "event code 88 is valid in Ares" -body {
    reset_state
    set ::Data::gamemode "ares"
    ::Validators::validate_event_code "T1" "test" 88
} -result 1

test event-code-invalid-ares "event code 89 is invalid in Ares" -body {
    reset_state
    set ::Data::gamemode "ares"
    ::Validators::validate_event_code "T1" "test" 89
} -result 0

test event-code-phobos-classic "classic event code 88 stays valid in Phobos" -body {
    reset_state
    set ::Data::gamemode "phobos"
    ::Validators::validate_event_code "T1" "test" 88
} -result 1

# --------------------------------------------------------------------------
# validate_action_code tests
# --------------------------------------------------------------------------
test action-code-valid-ra2 "action code 117 is valid in RA2" -body {
    reset_state
    set ::Data::gamemode "ra2"
    ::Validators::validate_action_code "T1" "test" 117
} -result 1

test action-code-invalid-ra2 "action code 118 is invalid in RA2" -body {
    reset_state
    set ::Data::gamemode "ra2"
    ::Validators::validate_action_code "T1" "test" 118
} -result 0

test action-code-valid-yr "action code 145 is valid in YR" -body {
    reset_state
    set ::Data::gamemode "yr"
    ::Validators::validate_action_code "T1" "test" 145
} -result 1

test action-code-invalid-yr "action code 146 is invalid in YR" -body {
    reset_state
    set ::Data::gamemode "yr"
    ::Validators::validate_action_code "T1" "test" 146
} -result 0

test action-code-valid-ares "action code 149 is valid in Ares" -body {
    reset_state
    set ::Data::gamemode "ares"
    ::Validators::validate_action_code "T1" "test" 149
} -result 1

test action-code-invalid-ares "action code 150 is invalid in Ares" -body {
    reset_state
    set ::Data::gamemode "ares"
    ::Validators::validate_action_code "T1" "test" 150
} -result 0

# --------------------------------------------------------------------------
# validate_script_code tests
# --------------------------------------------------------------------------
test script-code-valid-ra2 "script code 58 is valid in RA2" -body {
    reset_state
    set ::Data::gamemode "ra2"
    ::Validators::validate_script_code "S1" 1 58
} -result 1

test script-code-invalid-ra2 "script code 59 is invalid in RA2" -body {
    reset_state
    set ::Data::gamemode "ra2"
    ::Validators::validate_script_code "S1" 1 59
} -result 0

test script-code-valid-yr "script code 64 is valid in YR" -body {
    reset_state
    set ::Data::gamemode "yr"
    ::Validators::validate_script_code "S1" 1 64
} -result 1

test script-code-invalid-yr "script code 65 is invalid in YR" -body {
    reset_state
    set ::Data::gamemode "yr"
    ::Validators::validate_script_code "S1" 1 65
} -result 0

test script-code-valid-ares "script code 70 is valid in Ares" -body {
    reset_state
    set ::Data::gamemode "ares"
    ::Validators::validate_script_code "S1" 1 70
} -result 1

test script-code-invalid-ares "script code 71 is invalid in Ares" -body {
    reset_state
    set ::Data::gamemode "ares"
    ::Validators::validate_script_code "S1" 1 71
} -result 0

# --------------------------------------------------------------------------
# Phobos code ranges (constants.tcl PHOBOS_*_RANGES)
# Every documented boundary must pass, every gap and every out-of-range
# value must fail, and Phobos IDs must stay invisible to the other modes.
# --------------------------------------------------------------------------
test phobos-event-ok-0 "event code 0 is valid in Phobos" -body {
    check_code phobos event 0
} -result 1

test phobos-event-ok-500 "event code 500 is valid in Phobos" -body {
    check_code phobos event 500
} -result 1

test phobos-event-ok-535 "event code 535 is valid in Phobos" -body {
    check_code phobos event 535
} -result 1

test phobos-event-ok-600 "event code 600 is valid in Phobos" -body {
    check_code phobos event 600
} -result 1

test phobos-event-ok-602 "event code 602 is valid in Phobos" -body {
    check_code phobos event 602
} -result 1

test phobos-event-ok-604 "event code 604 is valid in Phobos" -body {
    check_code phobos event 604
} -result 1

test phobos-event-ok-606 "event code 606 is valid in Phobos" -body {
    check_code phobos event 606
} -result 1

test phobos-event-bad-89 "event code 89 is not defined in Phobos" -body {
    check_code phobos event 89
} -result 0

test phobos-event-bad-499 "event code 499 is not defined in Phobos" -body {
    check_code phobos event 499
} -result 0

test phobos-event-bad-536 "event code 536 is not defined in Phobos" -body {
    check_code phobos event 536
} -result 0

test phobos-event-bad-603 "event code 603 is the documented gap" -body {
    check_code phobos event 603
} -result 0

test phobos-event-bad-607 "event code 607 is not defined in Phobos" -body {
    check_code phobos event 607
} -result 0

test phobos-event-ares-500 "Phobos event 500 is rejected in Ares" -body {
    check_code ares event 500
} -result 0

test phobos-event-ra2-500 "Phobos event 500 is rejected in RA2" -body {
    check_code ra2 event 500
} -result 0

test phobos-action-ok-149 "action code 149 is valid in Phobos" -body {
    check_code phobos action 149
} -result 1

test phobos-action-ok-500 "action code 500 is valid in Phobos" -body {
    check_code phobos action 500
} -result 1

test phobos-action-ok-506 "action code 506 is valid in Phobos" -body {
    check_code phobos action 506
} -result 1

test phobos-action-ok-510 "action code 510 is valid in Phobos" -body {
    check_code phobos action 510
} -result 1

test phobos-action-ok-513 "action code 513 is valid in Phobos" -body {
    check_code phobos action 513
} -result 1

test phobos-action-ok-600 "action code 600 is valid in Phobos" -body {
    check_code phobos action 600
} -result 1

test phobos-action-ok-606 "action code 606 is valid in Phobos" -body {
    check_code phobos action 606
} -result 1

test phobos-action-ok-611 "action code 611 is valid in Phobos" -body {
    check_code phobos action 611
} -result 1

test phobos-action-ok-800 "action code 800 is valid in Phobos" -body {
    check_code phobos action 800
} -result 1

test phobos-action-ok-802 "action code 802 is valid in Phobos" -body {
    check_code phobos action 802
} -result 1

test phobos-action-bad-150 "action code 150 is not defined in Phobos" -body {
    check_code phobos action 150
} -result 0

test phobos-action-bad-507 "action code 507 is a documented gap" -body {
    check_code phobos action 507
} -result 0

test phobos-action-bad-514 "action code 514 is a documented gap" -body {
    check_code phobos action 514
} -result 0

test phobos-action-bad-599 "action code 599 is a documented gap" -body {
    check_code phobos action 599
} -result 0

test phobos-action-bad-601 "action code 601 is a documented gap" -body {
    check_code phobos action 601
} -result 0

test phobos-action-bad-605 "action code 605 is a documented gap" -body {
    check_code phobos action 605
} -result 0

test phobos-action-bad-612 "action code 612 is a documented gap" -body {
    check_code phobos action 612
} -result 0

test phobos-action-bad-799 "action code 799 is a documented gap" -body {
    check_code phobos action 799
} -result 0

test phobos-action-bad-803 "action code 803 is a documented gap" -body {
    check_code phobos action 803
} -result 0

test phobos-action-ares-600 "Phobos action 600 is rejected in Ares" -body {
    check_code ares action 600
} -result 0

test phobos-action-ra2-600 "Phobos action 600 is rejected in RA2" -body {
    check_code ra2 action 600
} -result 0

test phobos-script-ok-70 "script code 70 is valid in Phobos" -body {
    check_code phobos script 70
} -result 1

test phobos-script-ok-10000 "script code 10000 is valid in Phobos" -body {
    check_code phobos script 10000
} -result 1

test phobos-script-ok-10017 "script code 10017 is valid in Phobos" -body {
    check_code phobos script 10017
} -result 1

test phobos-script-ok-10050 "script code 10050 is valid in Phobos" -body {
    check_code phobos script 10050
} -result 1

test phobos-script-ok-10061 "script code 10061 is valid in Phobos" -body {
    check_code phobos script 10061
} -result 1

test phobos-script-ok-10100 "script code 10100 is valid in Phobos" -body {
    check_code phobos script 10100
} -result 1

test phobos-script-ok-10104 "script code 10104 is valid in Phobos" -body {
    check_code phobos script 10104
} -result 1

test phobos-script-ok-12000 "script code 12000 is valid in Phobos" -body {
    check_code phobos script 12000
} -result 1

test phobos-script-ok-12002 "script code 12002 is valid in Phobos" -body {
    check_code phobos script 12002
} -result 1

test phobos-script-ok-14000 "script code 14000 is valid in Phobos" -body {
    check_code phobos script 14000
} -result 1

test phobos-script-ok-14004 "script code 14004 is valid in Phobos" -body {
    check_code phobos script 14004
} -result 1

test phobos-script-ok-16000 "script code 16000 is valid in Phobos" -body {
    check_code phobos script 16000
} -result 1

test phobos-script-ok-16005 "script code 16005 is valid in Phobos" -body {
    check_code phobos script 16005
} -result 1

test phobos-script-ok-18000 "script code 18000 is valid in Phobos" -body {
    check_code phobos script 18000
} -result 1

test phobos-script-ok-18071 "script code 18071 is valid in Phobos" -body {
    check_code phobos script 18071
} -result 1

test phobos-script-bad-71 "script code 71 is not defined in Phobos" -body {
    check_code phobos script 71
} -result 0

test phobos-script-bad-10018 "script code 10018 is not defined in Phobos" -body {
    check_code phobos script 10018
} -result 0

test phobos-script-bad-10062 "script code 10062 is not defined in Phobos" -body {
    check_code phobos script 10062
} -result 0

test phobos-script-bad-10105 "script code 10105 is not defined in Phobos" -body {
    check_code phobos script 10105
} -result 0

test phobos-script-bad-12003 "script code 12003 is not defined in Phobos" -body {
    check_code phobos script 12003
} -result 0

test phobos-script-bad-14005 "script code 14005 is not defined in Phobos" -body {
    check_code phobos script 14005
} -result 0

test phobos-script-bad-16006 "script code 16006 is not defined in Phobos" -body {
    check_code phobos script 16006
} -result 0

test phobos-script-bad-18072 "script code 18072 is not defined in Phobos" -body {
    check_code phobos script 18072
} -result 0

test phobos-script-bad-19000 "script code 19000 (empty category) is rejected" -body {
    check_code phobos script 19000
} -result 0

test phobos-script-ares-10000 "Phobos script 10000 is rejected in Ares" -body {
    check_code ares script 10000
} -result 0

test phobos-script-ra2-10000 "Phobos script 10000 is rejected in RA2" -body {
    check_code ra2 script 10000
} -result 0

# --------------------------------------------------------------------------
# validate_country_index tests
# --------------------------------------------------------------------------
test country-index-valid-global "valid global country index" -body {
    reset_state
    set ::Data::countrycnt 10
    ::Validators::validate_country_index "T1" "test" 5
} -result 1

test country-index-invalid-global "invalid global country index" -body {
    reset_state
    set ::Data::countrycnt 10
    ::Validators::validate_country_index "T1" "test" 15
} -result 0

test country-index-valid-map "valid map-specific country index" -body {
    reset_state
    set ::Data::countrycnt 0
    set ::Data::changeidx(4475) "PlayerA"
    ::Validators::validate_country_index "T1" "test" 4475
} -result 1

test country-index-negative "negative index is invalid" -body {
    reset_state
    set ::Data::countrycnt 10
    ::Validators::validate_country_index "T1" "test" -1
} -result 0

test country-index-zero "index 0 is valid when countrycnt > 0" -body {
    reset_state
    set ::Data::countrycnt 10
    ::Validators::validate_country_index "T1" "test" 0
} -result 1

test country-index-no-data "no country data means invalid" -body {
    reset_state
    ::Validators::validate_country_index "T1" "test" 0
} -result 0

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_state
cleanupTests
