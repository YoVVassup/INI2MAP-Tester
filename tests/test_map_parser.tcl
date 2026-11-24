#----------------------------------------------------------------------------------------------------------
# test_map_parser.tcl - Unit tests for map_parser/core.tcl functions
#----------------------------------------------------------------------------------------------------------
# Tests: num2wp, wp2num, locatrix, statetest, mphtest
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

# --------------------------------------------------------------------------
# Source required modules
# --------------------------------------------------------------------------
set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "map_parser" "core.tcl"]

# --------------------------------------------------------------------------
# num2wp tests
# --------------------------------------------------------------------------
test num2wp-0 "0 -> A" -body {
    ::MapParser::num2wp 0
} -result "A"

test num2wp-1 "1 -> B" -body {
    ::MapParser::num2wp 1
} -result "B"

test num2wp-25 "25 -> Z" -body {
    ::MapParser::num2wp 25
} -result "Z"

test num2wp-26 "26 -> AA" -body {
    ::MapParser::num2wp 26
} -result "AA"

test num2wp-27 "27 -> AB" -body {
    ::MapParser::num2wp 27
} -result "AB"

test num2wp-51 "51 -> AZ" -body {
    ::MapParser::num2wp 51
} -result "AZ"

test num2wp-negative "Negative -> A (default)" -body {
    ::MapParser::num2wp -1
} -result "A"

test num2wp-nonint "Non-integer -> A (default)" -body {
    ::MapParser::num2wp "abc"
} -result "A"

# --------------------------------------------------------------------------
# wp2num tests
# --------------------------------------------------------------------------
test wp2num-A "A -> 0" -body {
    ::MapParser::wp2num "A"
} -result 0

test wp2num-B "B -> 1" -body {
    ::MapParser::wp2num "B"
} -result 1

test wp2num-Z "Z -> 25" -body {
    ::MapParser::wp2num "Z"
} -result 25

test wp2num-AA "AA -> 26" -body {
    ::MapParser::wp2num "AA"
} -result 26

test wp2num-AB "AB -> 27" -body {
    ::MapParser::wp2num "AB"
} -result 27

test wp2num-lowercase "a -> 0 (case insensitive)" -body {
    ::MapParser::wp2num "a"
} -result 0

test wp2num-empty "Empty -> 0" -body {
    ::MapParser::wp2num ""
} -result 0

# --------------------------------------------------------------------------
# Roundtrip tests
# --------------------------------------------------------------------------
for {set i 0} {$i < 30} {incr i} {
    test roundtrip-$i "Roundtrip $i" -body {
        set wp [::MapParser::num2wp $i]
        set num [::MapParser::wp2num $wp]
        expr {$num == $i}
    } -result 1
}

# --------------------------------------------------------------------------
# statetest tests
# --------------------------------------------------------------------------
test statetest-sleep "Sleep is valid" -body {
    ::MapParser::statetest "Sleep" "TEST"
} -result 1

test statetest-sticky "Sticky is valid" -body {
    ::MapParser::statetest "Sticky" "TEST"
} -result 1

test statetest-guard "Guard is valid" -body {
    ::MapParser::statetest "Guard" "TEST"
} -result 1

test statetest-hunt "Hunt is valid" -body {
    ::MapParser::statetest "Hunt" "TEST"
} -result 1

test statetest-harmless "Harmless is valid" -body {
    ::MapParser::statetest "Harmless" "TEST"
} -result 1

test statetest-areaguard "Area Guard is valid" -body {
    ::MapParser::statetest "Area Guard" "TEST"
} -result 1

test statetest-harvest-valid "Harvest with harvy unit is valid" -body {
    set ::Data::harvy(HARVESTER) 1
    ::MapParser::statetest "Harvest" "HARVESTER"
} -result 1

test statetest-harvest-invalid "Harvest without harvy unit is invalid" -body {
    ::MapParser::statetest "Harvest" "TANK"
} -result 0

test statetest-invalid "Invalid state is invalid" -body {
    ::MapParser::statetest "InvalidState" "TEST"
} -result 0

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
