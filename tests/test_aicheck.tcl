#----------------------------------------------------------------------------------------------------------
# test_aicheck.tcl - Unit tests for aicheck/core.tcl
#----------------------------------------------------------------------------------------------------------
# Tests: _is_int, _is_float helper functions
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]

# --------------------------------------------------------------------------
# Source required modules
# --------------------------------------------------------------------------
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "aicheck" "aicheck.tcl"]

# --------------------------------------------------------------------------
# _is_int tests
# --------------------------------------------------------------------------
test is-int-positive "positive integer" -body {
    ::AICheck::_is_int "42"
} -result 1

test is-int-negative "negative integer" -body {
    ::AICheck::_is_int "-7"
} -result 1

test is-int-zero "zero" -body {
    ::AICheck::_is_int "0"
} -result 1

test is-int-large "large integer" -body {
    ::AICheck::_is_int "999999999"
} -result 1

test is-int-float "float is not int" -body {
    ::AICheck::_is_int "3.14"
} -result 0

test is-int-string "string is not int" -body {
    ::AICheck::_is_int "abc"
} -result 0

test is-int-empty "empty string is not int" -body {
    ::AICheck::_is_int ""
} -result 0

test is-int-mixed "mixed alphanumeric is not int" -body {
    ::AICheck::_is_int "12abc"
} -result 0

test is-int-spaces "string with leading space" -body {
    # Tcl's string is integer accepts leading spaces
    ::AICheck::_is_int " 42"
} -result 1

test is-int-plus "plus sign prefix" -body {
    # Tcl's string is integer accepts + prefix
    ::AICheck::_is_int "+5"
} -result 1

# --------------------------------------------------------------------------
# _is_float tests
# --------------------------------------------------------------------------
test is-float-positive "positive float" -body {
    ::AICheck::_is_float "3.14"
} -result 1

test is-float-negative "negative float" -body {
    ::AICheck::_is_float "-2.5"
} -result 1

test is-float-integer "integer is also float" -body {
    ::AICheck::_is_float "42"
} -result 1

test is-float-zero "zero float" -body {
    ::AICheck::_is_float "0.0"
} -result 1

test is-float-scientific "scientific notation" -body {
    ::AICheck::_is_float "1e5"
} -result 1

test is-float-string "string is not float" -body {
    ::AICheck::_is_float "abc"
} -result 0

test is-float-empty "empty string is not float" -body {
    ::AICheck::_is_float ""
} -result 0

test is-float-dot-only "dot only is not float" -body {
    ::AICheck::_is_float "."
} -result 0

test is-float-commas "commas not supported" -body {
    ::AICheck::_is_float "1,5"
} -result 0

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
