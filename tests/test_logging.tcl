#----------------------------------------------------------------------------------------------------------
# test_logging.tcl - Unit tests for logging.tcl
# Tests: logputs_impl, reset_counts, get_exit_code, baseline filter, severity counting
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
set test_tmpdir [file join $script_dir "tests" "_tmp"]
file mkdir $test_tmpdir
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]

proc reset_logging {} {
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    set ::Data::quiet_mode 1
    # Reset baseline state
    set ::Logging::baseline_loaded 0
    set ::Logging::baseline_messages {}
}

# --------------------------------------------------------------------------
# Test 1: error message increments error_count
# --------------------------------------------------------------------------
test log-error "error increments error_count" -body {
    reset_logging
    ::Logging::error "test error"
    list $::Logging::error_count [llength $::Data::maperr]
} -result {1 1}

# --------------------------------------------------------------------------
# Test 2: warning message increments warning_count
# --------------------------------------------------------------------------
test log-warning "warning increments warning_count" -body {
    reset_logging
    ::Logging::warning "test warning"
    list $::Logging::warning_count [llength $::Data::maperr]
} -result {1 1}

# --------------------------------------------------------------------------
# Test 3: notice message increments notice_count
# --------------------------------------------------------------------------
test log-notice "notice increments notice_count" -body {
    reset_logging
    ::Logging::notice "test notice"
    list $::Logging::notice_count [llength $::Data::maperr]
} -result {1 1}

# --------------------------------------------------------------------------
# Test 4: message format has severity prefix
# --------------------------------------------------------------------------
test log-format "message has correct prefix" -body {
    reset_logging
    ::Logging::error "something bad"
    lindex $::Data::maperr 0
} -result "ERROR -> something bad"

# --------------------------------------------------------------------------
# Test 5: reset_counts clears all counters
# --------------------------------------------------------------------------
test log-reset "reset clears all counters" -body {
    reset_logging
    ::Logging::error "e1"
    ::Logging::warning "w1"
    ::Logging::notice "n1"
    ::Logging::reset_counts
    list $::Logging::error_count $::Logging::warning_count $::Logging::notice_count
} -result {0 0 0}

# --------------------------------------------------------------------------
# Test 6: get_exit_code = 0 when no messages
# --------------------------------------------------------------------------
test log-exit-0 "exit code 0 with no messages" -body {
    reset_logging
    ::Logging::get_exit_code
} -result 0

# --------------------------------------------------------------------------
# Test 7: get_exit_code = 1 when only warnings
# --------------------------------------------------------------------------
test log-exit-1 "exit code 1 with warnings only" -body {
    reset_logging
    ::Logging::warning "w1"
    ::Logging::get_exit_code
} -result 1

# --------------------------------------------------------------------------
# Test 8: get_exit_code = 2 when errors present
# --------------------------------------------------------------------------
test log-exit-2 "exit code 2 with errors" -body {
    reset_logging
    ::Logging::warning "w1"
    ::Logging::error "e1"
    ::Logging::get_exit_code
} -result 2

# --------------------------------------------------------------------------
# Test 9: baseline filter suppresses matching messages
# --------------------------------------------------------------------------
test log-baseline-suppress "baseline suppresses matching message" -body {
    reset_logging
    set ::Logging::baseline_messages [list "ERROR -> known issue"]
    set ::Logging::baseline_loaded 1
    ::Logging::error "known issue"
    list $::Logging::error_count $::Logging::suppressed_count [llength $::Data::maperr]
} -result {0 1 0}

# --------------------------------------------------------------------------
# Test 10: baseline filter does not suppress non-matching messages
# --------------------------------------------------------------------------
test log-baseline-nomatch "baseline does not suppress non-matching" -body {
    reset_logging
    set ::Logging::baseline_messages [list "ERROR -> known issue"]
    set ::Logging::baseline_loaded 1
    ::Logging::error "new issue"
    list $::Logging::error_count $::Logging::suppressed_count [llength $::Data::maperr]
} -result {1 0 1}

# --------------------------------------------------------------------------
# Test 11: baseline filter inactive when not loaded
# --------------------------------------------------------------------------
test log-baseline-inactive "baseline inactive when not loaded" -body {
    reset_logging
    set ::Logging::baseline_loaded 0
    ::Logging::error "any error"
    list $::Logging::error_count $::Logging::suppressed_count
} -result {1 0}

# --------------------------------------------------------------------------
# Test 12: multiple messages counted correctly
# --------------------------------------------------------------------------
test log-multi "multiple messages counted correctly" -body {
    reset_logging
    ::Logging::error "e1"
    ::Logging::error "e2"
    ::Logging::warning "w1"
    ::Logging::notice "n1"
    ::Logging::notice "n2"
    list $::Logging::error_count $::Logging::warning_count $::Logging::notice_count
} -result {2 1 2}

# --------------------------------------------------------------------------
# Test 13: load_baseline reads file correctly
# --------------------------------------------------------------------------
test log-load-baseline "load_baseline reads file" -body {
    reset_logging
    set tmpfile [file join $test_tmpdir "momt_baseline_test.txt"]
    set fh [open $tmpfile w]
    puts $fh "# Comment line"
    puts $fh ""
    puts $fh "ERROR -> msg1"
    puts $fh "WARNING -> msg2"
    close $fh
    set result [::Logging::load_baseline $tmpfile]
    file delete -force $tmpfile
    list $result $::Logging::baseline_loaded [llength $::Logging::baseline_messages]
} -result {1 1 2}

# --------------------------------------------------------------------------
# Test 14: load_baseline returns 0 for missing file
# --------------------------------------------------------------------------
test log-load-baseline-missing "load_baseline returns 0 for missing file" -body {
    reset_logging
    set ::Data::quiet_mode 1
    ::Logging::load_baseline [file join $test_tmpdir "_no_such" "baseline.log"]
} -result 0

# --------------------------------------------------------------------------
# Test 15: save_baseline writes file
# --------------------------------------------------------------------------
test log-save-baseline "save_baseline writes file" -body {
    reset_logging
    ::Logging::error "e1"
    ::Logging::warning "w1"
    set tmpfile [file join $test_tmpdir "momt_baseline_save.txt"]
    set result [::Logging::save_baseline $tmpfile]
    set exists [file exists $tmpfile]
    set fh [open $tmpfile r]
    set content [read $fh]
    close $fh
    file delete -force $tmpfile
    list $result $exists [string match "*e1*" $content] [string match "*w1*" $content]
} -result {1 1 1 1}

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_logging
cleanupTests
