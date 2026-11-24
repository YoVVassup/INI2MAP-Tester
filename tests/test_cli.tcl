#----------------------------------------------------------------------------------------------------------
# test_cli.tcl - Unit tests for cli.tcl
# Tests: CLI::parse (valid args), CLI::resolve_batch, CLI::show_help
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
set test_tmpdir [file join $script_dir "tests" "_tmp"]
file mkdir $test_tmpdir
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]

set ::app_dir $script_dir
source [file join $script_dir cli.tcl]

# Initialize CLI namespace variables (normally set by parse)
# Note: cli.tcl must be sourced first (its guard checks ::CLI::loaded)
namespace eval ::CLI {
    variable cfg_file ""
    variable cmd_gamemode ""
    variable cmd_no_log_open 0
    variable cmd_quiet 0
    variable cmd_format "text"
    variable cmd_timing 0
    variable map_file ""
    variable batch_mode 0
    variable batch_pattern ""
    variable salt ""
    variable baseline_mode 0
    variable baseline_filter ""
}

proc reset_cli {} {
    set ::CLI::cfg_file ""
    set ::CLI::cmd_gamemode ""
    set ::CLI::cmd_no_log_open 0
    set ::CLI::cmd_quiet 0
    set ::CLI::cmd_format "text"
    set ::CLI::cmd_timing 0
    set ::CLI::map_file ""
    set ::CLI::batch_mode 0
    set ::CLI::batch_pattern ""
    set ::CLI::salt ""
    set ::CLI::baseline_mode 0
    set ::CLI::baseline_filter ""
}

# --------------------------------------------------------------------------
# Test 1: parse sets map_file
# --------------------------------------------------------------------------
test cli-map-file "parse sets map_file" -body {
    reset_cli
    ::CLI::parse [list "test.map"]
    set ::CLI::map_file
} -result "test.map"

# --------------------------------------------------------------------------
# Test 2: parse sets cfg_file
# --------------------------------------------------------------------------
test cli-cfg-file "parse sets cfg_file" -body {
    reset_cli
    ::CLI::parse [list "--cfg" "custom.cfg" "test.map"]
    set ::CLI::cfg_file
} -result "custom.cfg"

# --------------------------------------------------------------------------
# Test 3: parse sets mode
# --------------------------------------------------------------------------
test cli-mode "parse sets gamemode" -body {
    reset_cli
    ::CLI::parse [list "--mode" "yr" "test.map"]
    set ::CLI::cmd_gamemode
} -result "yr"

# --------------------------------------------------------------------------
# Test 4: parse sets format json
# --------------------------------------------------------------------------
test cli-format-json "parse sets format json" -body {
    reset_cli
    ::CLI::parse [list "--format" "json" "test.map"]
    set ::CLI::cmd_format
} -result "json"

# --------------------------------------------------------------------------
# Test 5: parse sets format text
# --------------------------------------------------------------------------
test cli-format-text "parse sets format text" -body {
    reset_cli
    ::CLI::parse [list "--format" "text" "test.map"]
    set ::CLI::cmd_format
} -result "text"

# --------------------------------------------------------------------------
# Test 6: parse sets no_log_open
# --------------------------------------------------------------------------
test cli-no-log-open "parse sets no_log_open" -body {
    reset_cli
    ::CLI::parse [list "--no-log-open" "test.map"]
    set ::CLI::cmd_no_log_open
} -result 1

# --------------------------------------------------------------------------
# Test 7: parse sets quiet
# --------------------------------------------------------------------------
test cli-quiet "parse sets quiet" -body {
    reset_cli
    ::CLI::parse [list "--quiet" "test.map"]
    set ::CLI::cmd_quiet
} -result 1

# --------------------------------------------------------------------------
# Test 8: parse sets timing
# --------------------------------------------------------------------------
test cli-timing "parse sets timing" -body {
    reset_cli
    ::CLI::parse [list "--timing" "test.map"]
    set ::CLI::cmd_timing
} -result 1

# --------------------------------------------------------------------------
# Test 9: parse sets salt
# --------------------------------------------------------------------------
test cli-salt "parse sets salt" -body {
    reset_cli
    ::CLI::parse [list "--salt" "abcdef1234567890" "test.map"]
    set ::CLI::salt
} -result "abcdef1234567890"

# --------------------------------------------------------------------------
# Test 10: parse sets baseline_mode
# --------------------------------------------------------------------------
test cli-baseline "parse sets baseline_mode" -body {
    reset_cli
    ::CLI::parse [list "--baseline"]
    set ::CLI::baseline_mode
} -result 1

# --------------------------------------------------------------------------
# Test 11: parse sets baseline_filter
# --------------------------------------------------------------------------
test cli-baseline-filter "parse sets baseline_filter" -body {
    reset_cli
    ::CLI::parse [list "--baseline-filter" "bl.cfg" "test.map"]
    set ::CLI::baseline_filter
} -result "bl.cfg"

# --------------------------------------------------------------------------
# Test 12: parse sets batch_mode
# --------------------------------------------------------------------------
test cli-batch "parse sets batch_mode" -body {
    reset_cli
    ::CLI::parse [list "--batch" "*.map"]
    list $::CLI::batch_mode $::CLI::batch_pattern
} -result {1 *.map}

# --------------------------------------------------------------------------
# Test 13: parse sets batch_mode without pattern
# --------------------------------------------------------------------------
test cli-batch-no-pattern "parse sets batch_mode without pattern" -body {
    reset_cli
    ::CLI::parse [list "--batch"]
    set ::CLI::batch_mode
} -result 1

# --------------------------------------------------------------------------
# Test 14: resolve_batch with single map_file
# --------------------------------------------------------------------------
test cli-resolve-single "resolve_batch with single map_file" -body {
    reset_cli
    set ::CLI::map_file "test.map"
    ::CLI::resolve_batch
} -result {test.map}

# --------------------------------------------------------------------------
# Test 15: resolve_batch with existing file
# --------------------------------------------------------------------------
test cli-resolve-existing "resolve_batch with existing file" -body {
    reset_cli
    set tmpfile [file join $test_tmpdir "momt_test_resolve.map"]
    set fh [open $tmpfile w]
    puts $fh "\[BasicMap\]"
    puts $fh "Size=10,10"
    close $fh
    set ::CLI::batch_pattern $tmpfile
    set result [::CLI::resolve_batch]
    file delete -force $tmpfile
    set result
} -result [file join $test_tmpdir "momt_test_resolve.map"]

# --------------------------------------------------------------------------
# Test 16: resolve_batch with directory
# --------------------------------------------------------------------------
test cli-resolve-directory "resolve_batch with directory" -body {
    reset_cli
    set tmpdir [file join $test_tmpdir "momt_test_batch_dir"]
    file delete -force $tmpdir
    file mkdir $tmpdir
    foreach name {a.map b.map c.yrm} {
        set fh [open [file join $tmpdir $name] w]
        puts $fh "\[BasicMap\]"
        close $fh
    }
    set ::CLI::batch_pattern $tmpdir
    set result [::CLI::resolve_batch]
    file delete -force $tmpdir
    llength $result
} -result 3

# --------------------------------------------------------------------------
# Test 17: resolve_batch removes duplicates
# --------------------------------------------------------------------------
test cli-resolve-dedup "resolve_batch removes duplicates" -body {
    reset_cli
    set tmpfile [file join $test_tmpdir "momt_dedup_test.map"]
    set fh [open $tmpfile w]
    puts $fh "\[BasicMap\]"
    close $fh
    set ::CLI::batch_pattern $tmpfile
    set result [::CLI::resolve_batch]
    file delete -force $tmpfile
    llength $result
} -result 1

# --------------------------------------------------------------------------
# Test 18: resolve_batch sorts results
# --------------------------------------------------------------------------
test cli-resolve-sorted "resolve_batch returns sorted results" -body {
    reset_cli
    set tmpdir [file join $test_tmpdir "momt_test_sorted"]
    file delete -force $tmpdir
    file mkdir $tmpdir
    foreach name {c.map a.map b.map} {
        set fh [open [file join $tmpdir $name] w]
        puts $fh "\[BasicMap\]"
        close $fh
    }
    set ::CLI::batch_pattern $tmpdir
    set result [::CLI::resolve_batch]
    file delete -force $tmpdir
    expr {$result eq [lsort $result]}
} -result 1

# --------------------------------------------------------------------------
# Test 19: show_help outputs usage
# --------------------------------------------------------------------------
test cli-help "show_help outputs usage" -body {
    reset_cli
    set output [catch {::CLI::show_help} msg]
    expr {$output == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 20: show_help_short outputs usage
# --------------------------------------------------------------------------
test cli-help-short "show_help_short outputs usage" -body {
    reset_cli
    set output [catch {::CLI::show_help_short} msg]
    expr {$output == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_cli
cleanupTests
