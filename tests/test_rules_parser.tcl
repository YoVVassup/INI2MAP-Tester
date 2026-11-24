#----------------------------------------------------------------------------------------------------------
# test_rules_parser.tcl - Unit tests for rules_parser/core.tcl functions
#----------------------------------------------------------------------------------------------------------
# Tests: _strip_line, _parse_section, _parse_keyval
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
source [file join $script_dir "utils.tcl"]
namespace eval ::Rules { variable loaded 0 }
source [file join $script_dir "rules_parser" "core.tcl"]

# --------------------------------------------------------------------------
# _strip_line tests
# --------------------------------------------------------------------------
test strip-empty "Empty line" -body {
    ::Rules::_strip_line ""
} -result ""

test strip-blank "Whitespace only" -body {
    ::Rules::_strip_line "   \t  "
} -result ""

test strip-comment "Comment line" -body {
    ::Rules::_strip_line "; this is a comment"
} -result ""

test strip-inline-comment "Inline comment" -body {
    ::Rules::_strip_line "key=value ; comment"
} -result "key=value"

test strip-section "Section header" -body {
    ::Rules::_strip_line "\[General\]"
} -result "\[General\]"

test strip-keyval "Key=value pair" -body {
    ::Rules::_strip_line "Speed=10"
} -result "Speed=10"

test strip-trim "Whitespace trimming" -body {
    ::Rules::_strip_line "  key = value  "
} -result "key = value"

test strip-multiple-eq "Multiple equals" -body {
    ::Rules::_strip_line "key=val=ue"
} -result "key=val=ue"

# --------------------------------------------------------------------------
# _parse_section tests
# --------------------------------------------------------------------------
test parse-section-valid "Valid section" -body {
    ::Rules::_parse_section "\[General\]"
} -result "General"

test parse-section-nested "Nested brackets" -body {
    ::Rules::_parse_section "\[Audio\]"
} -result "Audio"

test parse-section-not-section "Not a section" -body {
    ::Rules::_parse_section "key=value"
} -result ""

test parse-section-empty "Empty string" -body {
    ::Rules::_parse_section ""
} -result ""

test parse-section-no-close "No closing bracket" -body {
    ::Rules::_parse_section "\[General"
} -result ""

test parse-section-special "Section with spaces" -body {
    ::Rules::_parse_section "\[SoundList\]"
} -result "SoundList"

# --------------------------------------------------------------------------
# _parse_keyval tests
# --------------------------------------------------------------------------
test parse-keyval-valid "Valid key=value" -body {
    ::util::_parse_keyval "Speed=10"
} -result "Speed 10"

test parse-keyval-spaces "Key with spaces" -body {
    ::util::_parse_keyval "  Speed = 10  "
} -result "Speed 10"

test parse-keyval-empty-value "Empty value" -body {
    ::util::_parse_keyval "Key="
} -result "Key {}"

test parse-keyval-no-equals "No equals" -body {
    ::util::_parse_keyval "just a line"
} -result ""

test parse-keyval-multiple-eq "Multiple equals" -body {
    ::util::_parse_keyval "key=val=ue"
} -result "key val=ue"

test parse-keyval-empty "Empty string" -body {
    ::util::_parse_keyval ""
} -result ""

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
