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

# The tests below cover the maintainer-only options (--salt / --show-salt), so
# maintainer mode is forced on here. The release side of the gate (both options
# rejected, help without those lines) is covered by the cli-release-* probes.
set ::CLI::maintainer_mode 1

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
    variable show_salt 0
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
    set ::CLI::show_salt 0
    set ::CLI::baseline_mode 0
    set ::CLI::baseline_filter ""
}

# --------------------------------------------------------------------------
# Release-mode probe: ::CLI::parse calls exit 1 on a rejected option, which
# would kill the test interpreter, so the release paths run in a subprocess
# with maintainer_mode forced to 0. Returns {catch_code exit_status output}.
# --------------------------------------------------------------------------
proc release_cli_probe {args} {
    global test_tmpdir script_dir
    set helper [file join $test_tmpdir "cli_release_probe.tcl"]
    set fh [open $helper w]
    puts $fh {set root [lindex $argv 0]
set ::app_dir $root
source [file join $root cli.tcl]
set ::CLI::maintainer_mode 0
if {[lindex $argv 1] eq "help"} {
    ::CLI::show_help
    exit 0
}
::CLI::parse [lrange $argv 1 end]}
    close $fh
    set code [catch {exec [info nameofexecutable] $helper $script_dir {*}$args 2>@1} out opts]
    file delete -force $helper
    set exitcode 0
    if {$code} {
        set exitcode [lindex [dict get $opts -errorcode] end]
    }
    return [list $code $exitcode [string trim $out]]
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
# Test 10a: parse sets show_salt (works without a map file)
# --------------------------------------------------------------------------
test cli-show-salt "parse sets show_salt without map file" -body {
    reset_cli
    ::CLI::parse [list "--show-salt"]
    list $::CLI::show_salt $::CLI::map_file
} -result {1 {}}

# --------------------------------------------------------------------------
# Test 10b: --show-salt combined with other options still parses
# --------------------------------------------------------------------------
test cli-show-salt-with-salt "parse --show-salt with --salt" -body {
    reset_cli
    ::CLI::parse [list "--salt" "0011" "--show-salt"]
    list $::CLI::show_salt $::CLI::salt
} -result {1 0011}

# --------------------------------------------------------------------------
# Test 10c: release build rejects --salt (Unknown option, exit 1)
# --------------------------------------------------------------------------
test cli-release-salt-rejected "--salt is rejected without maintainer mode" -body {
    lassign [release_cli_probe --salt 0011 test.map] code exitcode out
    list $code $exitcode [string match {*ERROR: Unknown option: --salt*} $out]
} -result {1 1 1}

# --------------------------------------------------------------------------
# Test 10d: release build rejects --show-salt (Unknown option, exit 1)
# --------------------------------------------------------------------------
test cli-release-show-salt-rejected "--show-salt is rejected without maintainer mode" -body {
    lassign [release_cli_probe --show-salt test.map] code exitcode out
    list $code $exitcode [string match {*ERROR: Unknown option: --show-salt*} $out]
} -result {1 1 1}

# --------------------------------------------------------------------------
# Test 10e: release help does not advertise the maintainer options
# --------------------------------------------------------------------------
test cli-release-help-hides-salt "release help hides the maintainer options" -body {
    lassign [release_cli_probe help] code exitcode out
    list $code $exitcode [string match {*--salt*} $out] [string match {*--baseline*} $out]
} -result {0 0 0 1}

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
