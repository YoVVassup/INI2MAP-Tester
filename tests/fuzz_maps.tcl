#----------------------------------------------------------------------------------------------------------
# fuzz_maps.tcl - Slow map fuzzing: mutated control maps through the full CLI
#----------------------------------------------------------------------------------------------------------
# NOT a test_*.tcl file on purpose - run_all.tcl must not pick it up. Run it as
# a separate slow gate:  tclsh tests/fuzz_maps.tcl
#
#   Usage: tclsh tests/fuzz_maps.tcl [-n <count>] [-m <map>] [-s <seed>] [-t <seconds>]
#     -n <count>    number of mutants (default 10)
#     -m <map>      base map file relative to the project root (default TEST.map)
#     -s <seed>     LCG seed (default 20261120) - rerun with the same seed to reproduce
#     -t <seconds>  per-mutant timeout (default 120)
#
# Invariant per mutant: the process must terminate inside the documented exit
# code range {0,1,2} with no unhandled exception (exit 3, or "unhandled
# exception" in stdout/stderr or in the written mission.log).
#
# Failing mutants are kept (together with their mission.log) in
# tests/_fuzz_maps for inspection; passing ones are deleted. The directory is
# intentionally outside tests/_tmp - run_all.tcl wipes _tmp after green runs.
# Exit code: 0 = every mutant ok, 1 = at least one violation, 2 = usage error.
#----------------------------------------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir "runlib.tcl"]

set count 10
set base_map "TEST.map"
set seed 20261120
set timeout_s 120
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    if {$arg in {-n -m -s -t}} {
        if {[expr {$i + 1}] >= [llength $argv]} {
            puts stderr "$arg requires a value"
            exit 2
        }
        incr i
        set val [lindex $argv $i]
        switch -- $arg {
            -n { set count $val }
            -m { set base_map $val }
            -s { set seed $val }
            -t { set timeout_s $val }
        }
        foreach v {count seed timeout_s} {
            if {![string is integer -strict [set $v]] || [set $v] <= 0} {
                puts stderr "option value must be a positive integer"
                exit 2
            }
        }
    } else {
        puts "Usage: tclsh86 tests/fuzz_maps.tcl \[-n <count>\] \[-m <map>\] \[-s <seed>\] \[-t <seconds>\]"
        exit 2
    }
}

set root [::Runlib::project_root]
set tclsh [info nameofexecutable]
set src_map [file join $root $base_map]
if {![file exists $src_map]} {
    puts stderr "base map not found: $src_map"
    exit 2
}

set tmp [file join $script_dir "_fuzz_maps"]
file delete -force $tmp
file mkdir $tmp

# --- base content (platform translation strips CR, same read as main.tcl) ---
set fh [open $src_map r]
set base_lines [split [read $fh] "\n"]
close $fh

# --- deterministic RNG ---
proc fz_next {} {
    set ::fz_s [expr {($::fz_s * 1103515245 + 12345) % 2147483648}]
    return $::fz_s
}
proc fz_n {n} { expr {[fz_next] % $n} }

# NOTE: junk lines kept ASCII on purpose - mutants go through the CLI
set fz_junk {0=1,2,3 = key= {[Sec] broken line} x= 0xZZ %d 99999999999999999999 key}
set fz_headers {Basic Events Actions Triggers CellTags Digest IsoMapPack5 0 "" {A B}}

proc fz_junk_line {} {
    switch [fz_n 6] {
        0 { return [lindex $::fz_junk [fz_n [llength $::fz_junk]]] }
        1 { return "[fz_n 1000]=" }
        2 { return "=[lindex $::fz_junk [fz_n [llength $::fz_junk]]]" }
        3 { return "\[[lindex $::fz_headers [fz_n [llength $::fz_headers]]]\]" }
        default { return "junk [fz_n 10000]" }
    }
}

# --- apply 1..4 random mutations to a copy of the base lines ---
proc fz_mutate {lines} {
    global base_lines
    set nops [expr {1 + [fz_n 4]}]
    for {set k 0} {$k < $nops} {incr k} {
        set n [llength $lines]
        if {$n == 0} break
        set idx [fz_n $n]
        set ln [lindex $lines $idx]
        switch [fz_n 7] {
            0 { set lines [lreplace $lines $idx $idx] }
            1 { set lines [lreplace $lines $idx $idx [fz_junk_line]] }
            2 {
                set eq [string first "=" $ln]
                if {$eq > 0} {
                    set lines [lreplace $lines $idx $idx \
                        "[string range $ln 0 $eq][lindex $::fz_junk [fz_n [llength $::fz_junk]]]"]
                }
            }
            3 {
                set eq [string first "=" $ln]
                if {$eq > 0} {
                    set lines [lreplace $lines $idx $idx [string replace $ln $eq $eq ""]]
                }
            }
            4 { set lines [linsert $lines [expr {$idx + 1}] [fz_junk_line]] }
            5 { set lines [lrange $lines 0 $idx] }
            default {
                if {[string index $ln 0] eq "\["} {
                    set head [lindex $::fz_headers [fz_n [llength $::fz_headers]]]
                    set lines [lreplace $lines $idx $idx "\[$head\]"]
                } else {
                    set lines [lreplace $lines $idx $idx [fz_junk_line]]
                }
            }
        }
    }
    # a mutation pass may be a no-op (junk dropped by the parser anyway);
    # force a change so every mutant really differs from the base map
    if {$lines eq $base_lines} {
        set n [llength $lines]
        if {$n > 0} {
            set lines [lreplace $lines [fz_n $n] [fz_n $n]]
            set idx [fz_n [llength $lines]]
            set lines [linsert $lines $idx [fz_junk_line]]
        }
    }
    return $lines
}

puts "fuzz_maps: base=$base_map n=$count seed=$seed timeout=${timeout_s}s"

set ok 0
set bad 0
set ::fz_s $seed
for {set i 0} {$i < $count} {incr i} {
    set lines [fz_mutate $base_lines]
    set mutant [file join $tmp [format "fuzz_%03d.map" $i]]
    set log [file join $tmp "mission.log"]
    set fh [open $mutant w]
    puts -nonewline $fh [join $lines "\n"]
    close $fh
    catch {file delete -force $log}

    set start [clock milliseconds]
    set res [::Runlib::exec_timeout $tmp [expr {$timeout_s * 1000}] \
        [list $tclsh [file join $root "main.tcl"] --quiet --no-log-open --format text $mutant]]
    set secs [format "%.1f" [expr {([clock milliseconds] - $start) / 1000.0}]]

    set why {}
    if {[dict get $res timedout]} {
        set why "hang: no exit code after ${timeout_s}s (process tree killed)"
    } else {
        set code [dict get $res code]
        if {$code == -1} {
            set why "no exit status could be read"
        } elseif {$code > 2} {
            set why "exit=$code (documented range is 0..2)"
        }
        set txt [dict get $res output]
        if {[file exists $log]} {
            set fh [open $log r]
            append txt [read $fh]
            close $fh
        }
        if {[regexp -nocase {unhandled exception} $txt]} {
            set why "unhandled exception reported (exit=$code)"
        }
    }

    if {$why eq ""} {
        set summary [::Runlib::read_summary $log]
        set counts ""
        if {$summary ne {}} {
            set counts " e=[dict get $summary errors] w=[dict get $summary warnings] n=[dict get $summary notices]"
        }
        puts [format "ok   fuzz_%03d exit=%d%s (%ss)" $i [dict get $res code] $counts $secs]
        incr ok
        file delete -force $mutant $log
    } else {
        puts [format "FAIL fuzz_%03d: %s (%ss)" $i $why $secs]
        puts "     mutant kept: $mutant"
        if {[file exists $log]} { puts "     log kept:     $log" }
        puts "     reproduce:    $tclsh [file join $root main.tcl] --quiet $mutant"
        incr bad
    }
}

if {$bad == 0} {
    puts "fuzz_maps: $ok/$count ok"
    exit 0
}
puts "fuzz_maps: $ok/$count ok - $bad FAILED (seed $seed)"
exit 1
