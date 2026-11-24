#----------------------------------------------------------------------------------------------------------
# run_all.tcl - Test suite runner for INI2MAP Tester
#----------------------------------------------------------------------------------------------------------
# Runs every tests/test_*.tcl in a separate tclsh process, parses the tcltest summary
# line and reports a single overall result.
#
#   Usage: tclsh86 tests/run_all.tcl [-v] [-k <substring>]
#     -v             show output of every test file (default: only failures)
#     -k <substring> run only files whose name contains <substring>
#
# Exit code: 0 = all tests passed, 1 = at least one failure.
#----------------------------------------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file dirname $script_dir]
set tclsh      [info nameofexecutable]

set verbose 0
set filter  ""
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    if {$arg eq "-v"} {
        set verbose 1
    } elseif {$arg eq "-k" && [expr {$i + 1}] < [llength $argv]} {
        incr i
        set filter [lindex $argv $i]
    } else {
        puts "Usage: tclsh86 tests/run_all.tcl \[-v\] \[-k <substring>\]"
        exit 2
    }
}

set files [lsort [glob -nocomplain [file join $script_dir "test_*.tcl"]]]
if {$filter ne ""} {
    set filtered {}
    foreach f $files {
        if {[string match "*$filter*" [file tail $f]]} { lappend filtered $f }
    }
    set files $filtered
}
if {[llength $files] == 0} {
    puts "No test files found in $script_dir"
    exit 2
}

set summary_re {Total\s+(\d+)\s+Passed\s+(\d+)\s+Skipped\s+(\d+)\s+Failed\s+(\d+)}

set total_tests 0
set total_passed 0
set total_skipped 0
set total_failed 0
set files_ok 0
set files_bad 0
set files_plain 0
set start_ms [clock milliseconds]
set failures {}

foreach f $files {
    set name [file tail $f]
    set output ""
    set exit_code 0
    # 2>@1 merges stderr into stdout so exec only throws on a non-zero exit code
    if {[catch {set output [exec -- $tclsh $f 2>@1]} exec_err]} {
        # exec throws when the child exits non-zero; the error message carries its output
        set output $exec_err
        # exec appends "child process exited abnormally" - keep it out of the report
        regsub {\nchild process exited abnormally$} $output "" output
        set exit_code 1
    }

    # Standalone script tests (no tcltest summary) must not report error markers
    set suspicious [regexp {(^|\n)[^\n]*(FAILED|ERROR:|LOAD ERROR|PACKAGE ERROR)} $output]
    if {$verbose || $exit_code != 0 || $suspicious} {
        puts "----- $name -----"
        puts $output
        puts "-----"
    }

    set matched [regexp -all $summary_re $output]
    if {$matched > 0} {
        # A file may run several tcltest batches - sum them up
        set nums [regexp -all -inline $summary_re $output]
        set ftot 0; set fpass 0; set fskip 0; set ffail 0
        foreach {all t p s fl} $nums {
            incr ftot $t; incr fpass $p; incr fskip $s; incr ffail $fl
        }
        incr total_tests $ftot
        incr total_passed $fpass
        incr total_skipped $fskip
        incr total_failed $ffail
        if {$ffail > 0 || $exit_code != 0} {
            incr files_bad
            lappend failures "$name ($ffail failed)"
        } else {
            incr files_ok
        }
    } elseif {$exit_code == 0 && !$suspicious} {
        # Standalone script test (no tcltest summary) that exited cleanly
        incr files_plain
        incr files_ok
    } else {
        incr files_bad
        lappend failures "$name (script error)"
    }
}

set elapsed [expr {[clock milliseconds] - $start_ms}]

# Shared workspace used by the test files (_tmp): drop it after a fully green
# run, keep it for inspection when something failed
set tmp_dir [file join $script_dir "_tmp"]
if {[file isdirectory $tmp_dir]} {
    if {$files_bad == 0} {
        catch {file delete -force $tmp_dir}
    } else {
        puts "Note: keeping $tmp_dir for inspection (test failures reported below)"
    }
}

puts ""
puts "=============================================="
puts [format "  Files:  %d ok, %d failed  (%d total)" $files_ok $files_bad [llength $files]]
if {$files_plain > 0} {
    puts [format "          %d standalone script tests" $files_plain]
}
puts [format "  Tests:  %d total, %d passed, %d skipped, %d failed" \
    $total_tests $total_passed $total_skipped $total_failed]
puts [format "  Time:   %.1f s" [expr {$elapsed / 1000.0}]]
if {[llength $failures] > 0} {
    puts "----------------------------------------------"
    puts "  FAILED:"
    foreach msg $failures { puts "    - $msg" }
}
puts "=============================================="

exit [expr {$files_bad > 0 ? 1 : 0}]
