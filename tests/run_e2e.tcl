#----------------------------------------------------------------------------------------------------------
# run_e2e.tcl - End-to-end baseline gate for INI2MAP Tester (slow, run separately)
#----------------------------------------------------------------------------------------------------------
# Runs the control maps through main.tcl (default) or through the built starpack
# Build\MOMT\MOMT.exe (with -exe, used as the post-build smoke test) and compares
# Errors / Warnings / Notices + exit code against numeric baselines.
#
# The baselines are numeric on purpose: they also catch checks that silently
# disappear from the output. Update the table consciously when findings change.
#
#   Usage: tclsh tests/run_e2e.tcl [-exe] [-k <substring>] [-t <seconds per map>]
#     -exe            run Build\MOMT\MOMT.exe instead of "tclsh main.tcl"
#     -k <substring>  only maps whose file name contains <substring>
#     -t <seconds>    per-map timeout, default 600
#
# Exit code: 0 = every baseline matched, 1 = mismatch/failure, 2 = usage error.
#----------------------------------------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir "runlib.tcl"]

set baselines {
    {sov01.map 305 420 709 2}
    {TEST.map  333 513 797 2}
    {all01.map 308 434 701 2}
}

set exe_mode 0
set filter ""
set timeout_s 600
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    if {$arg eq "-exe"} {
        set exe_mode 1
    } elseif {$arg eq "-k" && [expr {$i + 1}] < [llength $argv]} {
        incr i
        set filter [lindex $argv $i]
    } elseif {$arg eq "-t" && [expr {$i + 1}] < [llength $argv]} {
        incr i
        set timeout_s [lindex $argv $i]
        if {![string is integer -strict $timeout_s] || $timeout_s <= 0} {
            puts stderr "-t requires a positive integer (seconds)"
            exit 2
        }
    } else {
        puts "Usage: tclsh86 tests/run_e2e.tcl \[-exe\] \[-k <substring>\] \[-t <seconds>\]"
        exit 2
    }
}

set root [::Runlib::project_root]
set tclsh [info nameofexecutable]
set exe [file join $root "Build" "MOMT" "MOMT.exe"]
set log [file join $root "mission.log"]

if {$exe_mode && ![file exists $exe]} {
    puts stderr "FAIL Build\\MOMT\\MOMT.exe not found (run build.bat first)"
    exit 1
}

set ran 0
set ok 0
set failed 0
foreach b $baselines {
    lassign $b map exp_err exp_warn exp_not exp_rc
    if {$filter ne "" && ![string match "*$filter*" $map]} continue

    incr ran
    set abs_map [file join $root $map]
    if {![file exists $abs_map]} {
        puts "FAIL $map: map file not found ($abs_map)"
        incr failed
        continue
    }

    if {$exe_mode} {
        set cwd [file join $root "Build"]
        set cmd [list $exe --quiet --no-log-open --format text $abs_map]
        set label "exe"
    } else {
        set cwd $root
        set cmd [list $tclsh [file join $root "main.tcl"] --quiet --no-log-open --format text $map]
        set label "tclsh"
    }

    catch {file delete -force $log}
    set start [clock milliseconds]
    set res [::Runlib::exec_timeout $cwd [expr {$timeout_s * 1000}] $cmd]
    set secs [format "%.1f" [expr {([clock milliseconds] - $start) / 1000.0}]]

    if {[dict get $res timedout]} {
        puts "FAIL $map ($label): hung for ${timeout_s}s, process tree killed"
        incr failed
        continue
    }

    set code [dict get $res code]
    set summary [::Runlib::read_summary $log]
    if {$summary eq {}} {
        puts "FAIL $map ($label): mission.log missing or has no parsable summary (exit=$code)"
        set tail [string range [dict get $res output] end-300 end]
        if {$tail ne ""} { puts "     last output: [string map [list \n " | "] $tail]" }
        incr failed
        continue
    }

    set got [list [dict get $summary errors] [dict get $summary warnings] \
                   [dict get $summary notices] $code]
    set exp [list $exp_err $exp_warn $exp_not $exp_rc]
    if {$got eq $exp} {
        puts "OK   $map ($label): errors=$exp_err warnings=$exp_warn notices=$exp_not exit=$exp_rc (${secs}s)"
        incr ok
    } else {
        puts [format "FAIL %s (%s): got %s/%s/%s/%s (expected %s/%s/%s/%s, %ss)" \
            $map $label [lindex $got 0] [lindex $got 1] [lindex $got 2] [lindex $got 3] \
            $exp_err $exp_warn $exp_not $exp_rc $secs]
        incr failed
    }
}

if {$ran == 0} {
    puts "No map matched filter '$filter'"
    exit 2
}
if {$failed == 0} {
    puts "E2E: $ok/$ran"
    exit 0
}
puts "E2E: $ok/$ran - $failed FAILED"
exit 1
