#----------------------------------------------------------------------------------------------------------
# runlib.tcl - Shared helpers for the slow runners (run_e2e.tcl, fuzz_maps.tcl)
#----------------------------------------------------------------------------------------------------------
# NOT a test_*.tcl file on purpose: run_all.tcl only globs test_*.tcl.
# Provides:
#   ::Runlib::project_root            -> project root directory
#   ::Runlib::exec_timeout cwd ms cmd -> dict {code timedout output}
#   ::Runlib::read_summary logpath    -> dict {errors warnings notices} or {} (text mission.log)
#   ::Runlib::lcg state               -> next state of the shared 31-bit LCG (deterministic fuzzing)
#----------------------------------------------------------------------------------------------------------

namespace eval ::Runlib {
    variable root [file dirname [file dirname [file normalize [info script]]]]
}

# --- Project root (parent of tests/) ---
proc ::Runlib::project_root {} {
    return $::Runlib::root
}

# --- Deterministic 31-bit LCG: same seed -> same sequence on every run ---
proc ::Runlib::lcg {state} {
    expr {($state * 1103515245 + 12345) % 2147483648}
}

# --- Run a command in a pipeline with a timeout ---
# cwd        : working directory of the child process
# timeout_ms : kill the whole process tree after this many milliseconds
# cmdlist    : Tcl list, e.g. [list $tclsh main.tcl --quiet map.map]
# Returns: dict {code <int exit code, -1 if unknown>, timedout <0|1>, output <stdout+stderr>}
proc ::Runlib::exec_timeout {cwd timeout_ms cmdlist} {
    set pipeline [concat $cmdlist [list 2>@1]]

    set oldpwd [pwd]
    cd $cwd
    if {[catch {open |$pipeline r} ch]} {
        cd $oldpwd
        return [dict create code -1 timedout 0 output "spawn failed: $ch"]
    }
    cd $oldpwd

    fconfigure $ch -blocking 0
    set pids [pid $ch]
    set out ""
    set timedout 0
    set t0 [clock milliseconds]
    while {1} {
        append out [read $ch]
        if {[eof $ch]} break
        if {[clock milliseconds] - $t0 > $timeout_ms} { set timedout 1; break }
        after 40
    }

    if {$timedout} {
        foreach p $pids { catch {exec taskkill /F /T /PID $p} }
        # drain whatever the dying children flush, bounded
        set t1 [clock milliseconds]
        while {![eof $ch] && [clock milliseconds] - $t1 < 5000} {
            append out [read $ch]
            after 40
        }
        catch {close $ch}
        return [dict create code -1 timedout 1 output $out]
    }

    # close() only reports CHILDSTATUS on a blocking channel (probe verified)
    set code 0
    fconfigure $ch -blocking 1
    if {[catch {close $ch} cerr]} {
        if {[lindex $::errorCode 0] eq "CHILDSTATUS"} {
            set code [lindex $::errorCode 2]
        } else {
            set code -1
            append out "\nclose failed: $cerr"
        }
    }
    return [dict create code $code timedout 0 output $out]
}

# --- Parse the SUMMARY block of a text-format mission.log ---
# Returns dict {errors warnings notices}, or {} when the log is missing or
# does not contain a parsable summary (JSON-format logs included).
proc ::Runlib::read_summary {logpath} {
    if {![file exists $logpath]} { return {} }
    if {[catch {open $logpath r} fh]} { return {} }
    set txt [read $fh]
    close $fh
    set idx [string last "---- SUMMARY ----" $txt]
    if {$idx < 0} { return {} }
    set tail [string range $txt $idx end]
    set d {}
    foreach {key re} {
        errors   {(?m)^Errors:[ \t]*(\d+)}
        warnings {(?m)^Warnings:[ \t]*(\d+)}
        notices  {(?m)^Notices:[ \t]*(\d+)}
    } {
        if {![regexp $re $tail -> v]} { return {} }
        dict set d $key $v
    }
    return $d
}
