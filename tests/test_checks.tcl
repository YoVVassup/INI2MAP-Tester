#----------------------------------------------------------------------------------------------------------
# test_checks.tcl - Unit tests for checks.tcl functions
#----------------------------------------------------------------------------------------------------------
# Tests: is_true, is_false, _find_property, get_cached_property, build_index
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
source [file join $script_dir "checks.tcl"]

# --------------------------------------------------------------------------
# is_true tests
# --------------------------------------------------------------------------
test is_true-yes "is_true yes" -body {
    ::Checks::is_true "yes"
} -result 1

test is_true-true "is_true true" -body {
    ::Checks::is_true "true"
} -result 1

test is_true-1 "is_true 1" -body {
    ::Checks::is_true "1"
} -result 1

test is_true-no "is_true no" -body {
    ::Checks::is_true "no"
} -result 0

test is_true-false "is_true false" -body {
    ::Checks::is_true "false"
} -result 0

test is_true-0 "is_true 0" -body {
    ::Checks::is_true "0"
} -result 0

test is_true-empty "is_true empty" -body {
    ::Checks::is_true ""
} -result 0

# --------------------------------------------------------------------------
# is_false tests
# --------------------------------------------------------------------------
test is_false-no "is_false no" -body {
    ::Checks::is_false "no"
} -result 1

test is_false-false "is_false false" -body {
    ::Checks::is_false "false"
} -result 1

test is_false-0 "is_false 0" -body {
    ::Checks::is_false "0"
} -result 1

test is_false-yes "is_false yes" -body {
    ::Checks::is_false "yes"
} -result 0

# --------------------------------------------------------------------------
# _find_property tests (uses pre-built index)
# --------------------------------------------------------------------------
test find-property-raw "Find in rawmapdata" -body {
    set ::Data::rawmapdata(TEST_SECTION) {Speed=10 Armor=5}
    ::Checks::build_index
    ::Checks::_find_property "TEST_SECTION" "Speed"
} -result "10"

test find-property-rules "Find in rulesdata" -body {
    set ::Data::rulesdata(TEST_SECTION2) {Range=100 Damage=50}
    ::Checks::build_index
    ::Checks::_find_property "TEST_SECTION2" "Range"
} -result "100"

test find-property-raw-priority "Rawmapdata has priority" -body {
    set ::Data::rawmapdata(TEST_SECTION3) {Speed=20}
    set ::Data::rulesdata(TEST_SECTION3) {Speed=10}
    ::Checks::build_index
    ::Checks::_find_property "TEST_SECTION3" "Speed"
} -result "20"

test find-property-notfound "Key not found" -body {
    set ::Data::rawmapdata(TEST_SECTION4) {Speed=10}
    ::Checks::build_index
    ::Checks::_find_property "TEST_SECTION4" "Nonexistent"
} -result ""

test find-property-nosection "Section not found" -body {
    ::Checks::build_index
    ::Checks::_find_property "NONEXISTENT_SECTION" "Speed"
} -result ""

# --------------------------------------------------------------------------
# get_cached_property tests
# --------------------------------------------------------------------------
test cached-property-basic "Cached property lookup" -body {
    set ::Data::rawmapdata(CACHED_TEST) {Speed=42}
    ::Checks::build_index
    ::Checks::get_cached_property "CACHED_TEST" "Speed"
} -result "42"

test cached-property-cache "Cached property uses cache" -body {
    set ::Data::rawmapdata(CACHED_TEST2) {Speed=99}
    ::Checks::build_index
    set val1 [::Checks::get_cached_property "CACHED_TEST2" "Speed"]
    set val2 [::Checks::get_cached_property "CACHED_TEST2" "Speed"]
    expr {$val1 eq $val2}
} -result 1

test cached-property-clear "Clear cache forces re-read" -body {
    set ::Data::rawmapdata(CACHED_TEST3) {Speed=111}
    ::Checks::build_index
    set val1 [::Checks::get_cached_property "CACHED_TEST3" "Speed"]
    ::Checks::clear_cache
    ::Checks::build_index
    set ::Data::rawmapdata(CACHED_TEST3) {Speed=222}
    ::Checks::build_index
    set val2 [::Checks::get_cached_property "CACHED_TEST3" "Speed"]
    expr {$val1 ne $val2}
} -result 1

# --------------------------------------------------------------------------
# build_index tests
# --------------------------------------------------------------------------
test build-index-populate "Index built from rawmapdata" -body {
    array unset ::Data::rawmapdata
    set ::Data::rawmapdata(BLDG1) {Name=Tank Strength=100}
    ::Checks::build_index
    ::Checks::_find_property "BLDG1" "Name"
} -result "Tank"

test build-index-overwrite "Index updates on rebuild" -body {
    array unset ::Data::rawmapdata
    set ::Data::rawmapdata(BLDG2) {Speed=10}
    ::Checks::build_index
    set v1 [::Checks::_find_property "BLDG2" "Speed"]
    set ::Data::rawmapdata(BLDG2) {Speed=20}
    ::Checks::build_index
    set v2 [::Checks::_find_property "BLDG2" "Speed"]
    expr {$v1 ne $v2}
} -result 1

# --------------------------------------------------------------------------
# Cleanup test data
# --------------------------------------------------------------------------
array unset ::Data::rawmapdata
array unset ::Data::rulesdata
::Checks::clear_cache

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
