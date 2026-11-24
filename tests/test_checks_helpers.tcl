#----------------------------------------------------------------------------------------------------------
# test_checks_helpers.tcl - Unit tests for checks.tcl helper functions
#----------------------------------------------------------------------------------------------------------
# Tests: is_true, is_false, build_index, get_cached_property
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]

# --------------------------------------------------------------------------
# Source required modules
# --------------------------------------------------------------------------
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "checks.tcl"]

# --------------------------------------------------------------------------
# is_true tests
# --------------------------------------------------------------------------
test is-true-yes "is_true yes" -body {
    ::Checks::is_true "yes"
} -result 1

test is-true-Yes "is_true Yes (case-insensitive)" -body {
    ::Checks::is_true "Yes"
} -result 1

test is-true-YES "is_true YES (case-insensitive)" -body {
    ::Checks::is_true "YES"
} -result 1

test is-true-true "is_true true" -body {
    ::Checks::is_true "true"
} -result 1

test is-true-True "is_true True (case-insensitive)" -body {
    ::Checks::is_true "True"
} -result 1

test is-true-1 "is_true 1" -body {
    ::Checks::is_true "1"
} -result 1

test is-true-on "is_true on" -body {
    ::Checks::is_true "on"
} -result 1

test is-true-On "is_true On (case-insensitive)" -body {
    ::Checks::is_true "On"
} -result 1

test is-true-no "is_true no" -body {
    ::Checks::is_true "no"
} -result 0

test is-true-false "is_true false" -body {
    ::Checks::is_true "false"
} -result 0

test is-true-0 "is_true 0" -body {
    ::Checks::is_true "0"
} -result 0

test is-true-empty "is_true empty" -body {
    ::Checks::is_true ""
} -result 0

test is-true-random "is_true random string" -body {
    ::Checks::is_true "maybe"
} -result 0

# --------------------------------------------------------------------------
# is_false tests
# --------------------------------------------------------------------------
test is-false-no "is_false no" -body {
    ::Checks::is_false "no"
} -result 1

test is-false-No "is_false No (case-insensitive)" -body {
    ::Checks::is_false "No"
} -result 1

test is-false-NO "is_false NO (case-insensitive)" -body {
    ::Checks::is_false "NO"
} -result 1

test is-false-false "is_false false" -body {
    ::Checks::is_false "false"
} -result 1

test is-false-False "is_false False (case-insensitive)" -body {
    ::Checks::is_false "False"
} -result 1

test is-false-0 "is_false 0" -body {
    ::Checks::is_false "0"
} -result 1

test is-false-off "is_false off" -body {
    ::Checks::is_false "off"
} -result 1

test is-false-Off "is_false Off (case-insensitive)" -body {
    ::Checks::is_false "Off"
} -result 1

test is-false-yes "is_false yes" -body {
    ::Checks::is_false "yes"
} -result 0

test is-false-true "is_false true" -body {
    ::Checks::is_false "true"
} -result 0

test is-false-1 "is_false 1" -body {
    ::Checks::is_false "1"
} -result 0

test is-false-empty "is_false empty" -body {
    ::Checks::is_false ""
} -result 0

# --------------------------------------------------------------------------
# build_index tests
# --------------------------------------------------------------------------
test build-index-basic "build index from rawmapdata" -body {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    set ::Data::rawmapdata(TestSection) [list "Key1=Value1" "Key2=Value2"]
    ::Checks::build_index
    variable ::Checks::property_index
    set idx [dict get $::Checks::property_index "TestSection,raw"]
    expr {[dict get $idx "Key1"] eq "Value1" && [dict get $idx "Key2"] eq "Value2"}
} -result 1

test build-index-overwrite "last value wins for duplicate keys" -body {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    set ::Data::rawmapdata(DupSection) [list "Key=First" "Key=Second"]
    ::Checks::build_index
    variable ::Checks::property_index
    set idx [dict get $::Checks::property_index "DupSection,raw"]
    dict get $idx "Key"
} -result "Second"

test build-index-trim "keys are trimmed, values preserved" -body {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    set ::Data::rawmapdata(TrimSection) [list "Key = Value "]
    ::Checks::build_index
    variable ::Checks::property_index
    set idx [dict get $::Checks::property_index "TrimSection,raw"]
    # Keys are trimmed, values are NOT trimmed
    dict get $idx "Key"
} -result " Value "

test build-index-no-equal "lines without = are skipped" -body {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    set ::Data::rawmapdata(SkipSection) [list "NoEquals" "Key=Value"]
    ::Checks::build_index
    variable ::Checks::property_index
    set idx [dict get $::Checks::property_index "SkipSection,raw"]
    dict exists $idx "NoEquals"
} -result 0

test build-index-empty-key "empty key is skipped" -body {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    set ::Data::rawmapdata(EmptyKey) [list "=Value" "Key2=Value2"]
    ::Checks::build_index
    variable ::Checks::property_index
    set idx [dict get $::Checks::property_index "EmptyKey,raw"]
    dict exists $idx ""
} -result 0

test build-index-rules "rulesdata is indexed with ,rules suffix" -body {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    set ::Data::rulesdata(RulesSection) [list "Prop=Val"]
    ::Checks::build_index
    variable ::Checks::property_index
    set idx [dict get $::Checks::property_index "RulesSection,rules"]
    dict get $idx "Prop"
} -result "Val"

# --------------------------------------------------------------------------
# get_cached_property tests
# --------------------------------------------------------------------------
test get-cached-basic "get property from index" -body {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    set ::Data::rawmapdata(TestUnit) [list "Primary=TestWeapon"]
    ::Checks::build_index
    ::Checks::get_cached_property "TestUnit" "Primary"
} -result "TestWeapon"

test get-cached-missing "get missing property returns empty" -body {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    set ::Data::rawmapdata(EmptyUnit) [list "Other=Value"]
    ::Checks::build_index
    ::Checks::get_cached_property "EmptyUnit" "Primary"
} -result ""

test get-cached-nonexistent "get property for nonexistent section" -body {
    array unset ::Data::rawmapdata
    array unset ::Data::rulesdata
    ::Checks::build_index
    ::Checks::get_cached_property "Nonexistent" "Key"
} -result ""

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
