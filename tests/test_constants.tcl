#----------------------------------------------------------------------------------------------------------
# test_constants.tcl - Unit tests for constants.tcl
#----------------------------------------------------------------------------------------------------------
# Tests: All constants are defined and have correct values
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

# --------------------------------------------------------------------------
# Source required modules
# --------------------------------------------------------------------------
set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]

# --------------------------------------------------------------------------
# Event code limits
# --------------------------------------------------------------------------
test event-ra2 "MAX_EVENT_RA2" -body {
    expr {$::Constants::MAX_EVENT_RA2 == 59}
} -result 1

test event-yr "MAX_EVENT_YR" -body {
    expr {$::Constants::MAX_EVENT_YR == 61}
} -result 1

test event-ares "MAX_EVENT_ARES" -body {
    expr {$::Constants::MAX_EVENT_ARES == 88}
} -result 1

# --------------------------------------------------------------------------
# Action code limits
# --------------------------------------------------------------------------
test action-ra2 "MAX_ACTION_RA2" -body {
    expr {$::Constants::MAX_ACTION_RA2 == 117}
} -result 1

test action-yr "MAX_ACTION_YR" -body {
    expr {$::Constants::MAX_ACTION_YR == 145}
} -result 1

test action-ares "MAX_ACTION_ARES" -body {
    expr {$::Constants::MAX_ACTION_ARES == 149}
} -result 1

# --------------------------------------------------------------------------
# Script code limits
# --------------------------------------------------------------------------
test script-ra2 "MAX_SCRIPT_RA2" -body {
    expr {$::Constants::MAX_SCRIPT_RA2 == 58}
} -result 1

test script-yr "MAX_SCRIPT_YR" -body {
    expr {$::Constants::MAX_SCRIPT_YR == 64}
} -result 1

test script-ares "MAX_SCRIPT_ARES" -body {
    expr {$::Constants::MAX_SCRIPT_ARES == 70}
} -result 1

# --------------------------------------------------------------------------
# Waypoint limits
# --------------------------------------------------------------------------
test waypoint-ra2 "MAX_WAYPOINTS_RA2" -body {
    expr {$::Constants::MAX_WAYPOINTS_RA2 == 101}
} -result 1

test waypoint-yr "MAX_WAYPOINTS_YR" -body {
    expr {$::Constants::MAX_WAYPOINTS_YR == 702}
} -result 1

# --------------------------------------------------------------------------
# Superweapon action codes
# --------------------------------------------------------------------------
test sw-charge "ACTION_SW_CHARGE" -body {
    expr {$::Constants::ACTION_SW_CHARGE == 129}
} -result 1

test sw-recharge "ACTION_SW_RECHARGE" -body {
    expr {$::Constants::ACTION_SW_RECHARGE == 132}
} -result 1

test sw-recharge2 "ACTION_SW_RECHARGE2" -body {
    expr {$::Constants::ACTION_SW_RECHARGE2 == 133}
} -result 1

# --------------------------------------------------------------------------
# Game constants
# --------------------------------------------------------------------------
test crate-max "MAX_CRATE_TYPE" -body {
    expr {$::Constants::MAX_CRATE_TYPE == 17}
} -result 1

test veteran-rookie "VETERAN_ROOKIE" -body {
    expr {$::Constants::VETERAN_ROOKIE == 0}
} -result 1

test veteran-veteran "VETERAN_VETERAN" -body {
    expr {$::Constants::VETERAN_VETERAN == 100}
} -result 1

test veteran-elite "VETERAN_ELITE" -body {
    expr {$::Constants::VETERAN_ELITE == 200}
} -result 1

test subcell-min "MIN_SUBCELL" -body {
    expr {$::Constants::MIN_SUBCELL == 0}
} -result 1

test subcell-max "MAX_SUBCELL" -body {
    expr {$::Constants::MAX_SUBCELL == 4}
} -result 1

test guard-range "MAX_GUARD_RANGE" -body {
    expr {$::Constants::MAX_GUARD_RANGE == 16}
} -result 1

# --------------------------------------------------------------------------
# Exit codes
# --------------------------------------------------------------------------
test exit-ok "EXIT_OK" -body {
    expr {$::Constants::EXIT_OK == 0}
} -result 1

test exit-warn "EXIT_WARN" -body {
    expr {$::Constants::EXIT_WARN == 1}
} -result 1

test exit-error "EXIT_ERROR" -body {
    expr {$::Constants::EXIT_ERROR == 2}
} -result 1

test exit-fatal "EXIT_FATAL" -body {
    expr {$::Constants::EXIT_FATAL == 3}
} -result 1

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
