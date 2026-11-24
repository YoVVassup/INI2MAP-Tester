#----------------------------------------------------------------------------------------------------------
# constants.tcl - Centralized constants for INI2MAP Tester
#----------------------------------------------------------------------------------------------------------
# All game-mode-specific limits and magic numbers are defined here.
# Modules should reference these instead of hardcoding values.
#----------------------------------------------------------------------------------------------------------

namespace eval ::Constants {

    # ==========================================================================
    # EVENT CODE LIMITS (per game mode)
    # ==========================================================================
    variable MAX_EVENT_RA2  59
    variable MAX_EVENT_YR   61
    variable MAX_EVENT_ARES 88

    # ==========================================================================
    # ACTION CODE LIMITS (per game mode)
    # ==========================================================================
    variable MAX_ACTION_RA2  117
    variable MAX_ACTION_YR   145
    variable MAX_ACTION_ARES 149

    # ==========================================================================
    # SCRIPT CODE LIMITS (per game mode)
    # ==========================================================================
    variable MAX_SCRIPT_RA2  58
    variable MAX_SCRIPT_YR   64
    variable MAX_SCRIPT_ARES 70

    # ==========================================================================
    # PHOBOS CODE RANGES (official Phobos documentation)
    # ==========================================================================
    # Phobos keeps every classic RA2/YR/Ares code valid and adds its own IDs,
    # so each list is the 0-MAX range plus the Phobos extensions.
    # Flat list of (first last) pairs; gaps are NOT defined and must fail:
    #   events   603
    #   actions  507-509, 514-599, 601-605, 612-799, 803+
    #   scripts  10018-10049, 10062-10099, 10105-11999, 12003-13999,
    #            14005-15999, 16006-17999, 18072-18999, 19000-19999 (empty)
    # Source: Phobos "AI Scripting and Mapping" -> Script Actions,
    # Trigger Actions and Trigger events sections.
    variable PHOBOS_EVENT_RANGES  {0 88 500 535 600 602 604 606}
    variable PHOBOS_ACTION_RANGES {0 149 500 506 510 513 600 600 606 611 800 802}
    variable PHOBOS_SCRIPT_RANGES {0 70 10000 10017 10050 10061 10100 10104 \
        12000 12002 14000 14004 16000 16005 18000 18071}
    # Phobos trigger events always carry three parameters (WAE writes them with
    # P1=2 so the game reads a third one); every other event code keeps two.
    variable PHOBOS_EVENT_PARAM3_RANGES {500 535 600 602 604 606}

    # ==========================================================================
    # WAYPOINT LIMITS
    # ==========================================================================
    variable MAX_WAYPOINTS_RA2  101
    variable MAX_WAYPOINTS_YR   702

    # ==========================================================================
    # SUPERWEAPON ACTION CODES
    # ==========================================================================
    variable ACTION_SW_CHARGE      129
    variable ACTION_SW_RECHARGE    132
    variable ACTION_SW_RECHARGE2   133

    # ==========================================================================
    # CRATE TYPES
    # ==========================================================================
    variable MAX_CRATE_TYPE 17

    # ==========================================================================
    # VETERAN STATUS VALUES
    # ==========================================================================
    variable VETERAN_ROOKIE  0
    variable VETERAN_VETERAN 100
    variable VETERAN_ELITE   200

    # ==========================================================================
    # INFANTRY SUB-CELL POSITIONS
    # ==========================================================================
    variable MIN_SUBCELL 0
    variable MAX_SUBCELL 4

    # ==========================================================================
    # GUARD RANGE LIMITS
    # ==========================================================================
    variable MAX_GUARD_RANGE 16

    # ==========================================================================
    # SOUND PARAMETER RANGES
    # ==========================================================================
    variable SOUND_RANGE_MIN  1
    variable SOUND_RANGE_MAX  50
    variable SOUND_VOLUME_MIN 0
    variable SOUND_VOLUME_MAX 100
    variable SOUND_LIMIT_MIN  0
    variable SOUND_LIMIT_MAX  10
    variable SOUND_PARAM_MIN  -50
    variable SOUND_PARAM_MAX  50

    # ==========================================================================
    # SUPERWEAPON CHARGE RANGE
    # ==========================================================================
    variable SW_CHARGE_MIN 0
    variable SW_CHARGE_MAX 100

    # ==========================================================================
    # MAP DIMENSIONS
    # ==========================================================================
    variable MAP_MAX_SUM       512
    variable MAP_FA2_MIN       16
    variable MAP_FA2_MAX       200
    variable MAP_FA2SP_MAX     256
    variable MAP_FA2_PATCH_MIN 20
    variable MAP_FA2_PATCH_MAX 492
    variable MAP_WAE_MIN       50
    variable MAP_WAE_MAX_WIDTH 273

    # ==========================================================================
    # EXIT CODES
    # ==========================================================================
    variable EXIT_OK      0
    variable EXIT_WARN    1
    variable EXIT_ERROR   2
    variable EXIT_FATAL   3

    # ==========================================================================
    # RANGE HELPERS
    # ==========================================================================
    # --- code_in_ranges ---
    # Returns 1 when $code falls into any (first last) pair of $ranges.
    # Shared by validators/core.tcl and map_parser/core.tcl so both sides
    # interpret the PHOBOS_*_RANGES lists identically.
    proc code_in_ranges {code ranges} {
        if {![string is integer -strict $code]} {
            return 0
        }
        for {set i 0} {$i < [llength $ranges]} {incr i 2} {
            if {$code >= [lindex $ranges $i] && $code <= [lindex $ranges $i+1]} {
                return 1
            }
        }
        return 0
    }
}
