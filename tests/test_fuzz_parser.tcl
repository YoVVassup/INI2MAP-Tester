#----------------------------------------------------------------------------------------------------------
# test_fuzz_parser.tcl - Deterministic parser/validator fuzzing (fast, runs inside run_all.tcl)
#----------------------------------------------------------------------------------------------------------
# Family 1: pseudo-random garbage INI files fed through the real parse pipeline
#           (::MapParser::parse_map) plus the event/action validators.
# Family 2: line-level mutants of the real control map TEST.map.
#
# Fixed LCG seed -> every run sees exactly the same inputs (deterministic).
# Invariant under test: no Tcl error escapes those procedures. Findings counters
# (errors/warnings/notices) are intentionally NOT asserted - garbage input
# legitimately produces arbitrary findings.
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

# --------------------------------------------------------------------------
# Source required modules (same order as check_load.tcl)
# --------------------------------------------------------------------------
set script_dir [file dirname [file dirname [info script]]]
set tests_dir [file dirname [file normalize [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir utils.tcl]
source [file join $script_dir map_parser.tcl]
source [file join $script_dir validators.tcl]
source [file join $script_dir checks.tcl]

set tmp_dir [file join $tests_dir "_tmp" "fuzz_parser"]
file delete -force $tmp_dir
file mkdir $tmp_dir

# --------------------------------------------------------------------------
# Deterministic RNG: 31-bit LCG, seed derived from the iteration index so the
# input of iteration i is identical no matter in which order tests run.
# --------------------------------------------------------------------------
set ::fz_base 20261120
proc fz_seed {s} { set ::fz_s $s }
proc fz_rand {} {
    set ::fz_s [expr {($::fz_s * 1103515245 + 12345) % 2147483648}]
    return $::fz_s
}
proc fz_n {n} { expr {[fz_rand] % $n} }
proc fz_pick {lst} { lindex $lst [fz_n [llength $lst]] }

# --------------------------------------------------------------------------
# Garbage line generators
# --------------------------------------------------------------------------
set ::fz_keys [list 0 1 2 17 4294967295 -1 0x1F Player HomeCell NewINIFormat \
    Waypoints {Waypoint 0} {} {0 } { 0} = 0= key {a b} {k[0]} %s {A=1} {0;1} {weird key}]
set ::fz_vals [list {} { } 1 -1 0x10 99999999999999999999 1.5 Eng None Guard \
    1,2,3 {,,,} {1,2,3,4,5,6,7,8,9,10} {a=b} {a;b} {} {[0]} {a b} "\\" {%d%s} \
    {\t} {0\t1} {x_test} {1,,2} -0 1e999 {end} {"q"}]
set ::fz_secs [list Basic Map Houses Country0 Country1 Structures Units Infantry \
    Aircraft Triggers Events Actions Tags TeamTypes TaskForces ScriptTypes \
    AITriggerTypes Waypoints VariableNames CellTags Smudge Terrain Digest \
    IsoMapPack5 OverlayDataPack Preview PreviewPack SpecialFlags {} {A B} {sec}]

proc fz_header {} {
    set sec [fz_pick $::fz_secs]
    switch [fz_n 6] {
        0 { return "\[$sec\]" }
        1 { return "\[$sec" }
        2 { return "\[]" }
        3 { return "\[  $sec  \]" }
        4 { return "$sec\]" }
        default { return "\[$sec\] trailing" }
    }
}

# Plausible map line (keeps the downstream object checks reachable)
proc fz_real_line {} {
    switch [fz_n 14] {
        0  { return "Player=[fz_pick {Eng GoodGuy Neutral Player1 Other3}]" }
        1  { return "NewINIFormat=1" }
        2  { return "HomeCell=[fz_n 100],[fz_n 100]" }
        3  { return "MultiplayerOnly=[fz_n 2]" }
        4  { return "[fz_n 3]=[fz_n 9],Neutral,0,0,0,0,1,1,0,0" }
        5  { return "[fz_n 3]=[fz_n 99],0,[fz_n 50],0,0,0,0,0,0,0,0,0,0,0" }
        6  { return "[fz_n 3]=[fz_n 99],6,0,0,0,0,0,0,0" }
        7  { return "[fz_n 3]=Eng,GAPOWR,100,[fz_n 50],[fz_n 50],0,0,0,0,0,0" }
        8  { return "[fz_n 3]=Eng,HARV,100,[fz_n 50],[fz_n 50],0,Guard,None,0,0,0,-1,0,0" }
        9  { return "[fz_n 3]=Eng,E1,100,[fz_n 50],[fz_n 50],0,Guard,None,0,0" }
        10 { return "[fz_n 3]=[fz_n 500],[fz_n 500]" }
        11 { return "[fz_n 3]=Tag[fz_n 9],Trg[fz_n 9]" }
        12 { return "[fz_n 3]=Team[fz_n 9]" }
        default { return "[fz_n 3]=Var[fz_n 9],Local" }
    }
}

proc fz_line {} {
    switch [fz_n 12] {
        0  { return "[fz_pick $::fz_keys]=[fz_pick $::fz_vals]" }
        1  { return "[fz_n 1000]=[fz_pick $::fz_vals]" }
        2  { return "[fz_pick $::fz_keys]=" }
        3  { return "=[fz_pick $::fz_vals]" }
        4  { return "[fz_pick $::fz_keys]=[fz_pick $::fz_vals],[fz_pick $::fz_vals],[fz_n 99999]" }
        5  { return [fz_header] }
        6  { return "; comment [fz_n 100]" }
        7  { return "junk without equals [fz_n 100]" }
        8  {
            set len [expr {[fz_n 4] == 0 ? 5000 : 1 + [fz_n 60]}]
            return "[fz_pick $::fz_keys]=[string repeat A $len]"
        }
        9  { return [fz_real_line] }
        10 { return "\t[fz_pick $::fz_keys]=[fz_pick $::fz_vals]\t" }
        default { return "[fz_pick $::fz_keys]==[fz_pick $::fz_vals]=[fz_n 10]" }
    }
}

# --------------------------------------------------------------------------
# State reset (same array list as test_map_parser_wae.tcl)
# --------------------------------------------------------------------------
proc fz_reset {} {
    foreach arr {
        rawmapdata rulesdata houses countries changeidx aircraft vehicles buildings
        infantry smudges tags triggers events actions teamtypes scripts taskforces
        waypoints wpcoords variables globalvars uvars uglobal infsubcell
        tagobjects tagcelltags unitcoord foundry uhouse ubldg uteam utask uscript
        basicplayer local_aitriggers aitriggertypes allobjects artery paddies
        corner mphouses parent attached bidx iidx uidx aidx allunits terrains
        harvy terrain_foundation ianims anims attacheffects superweapons
        house_country house_playerctl house_basenodes house_units
    } {
        catch {array unset ::Data::${arr}}
    }
    foreach v {newini mhouses countrycnt strictra2 mismap mpsonly housecnt \
               maspect showunused writeanims savelog} {
        catch {set ::Data::$v 0}
    }
    set ::Data::houselist {}
    set ::Data::gamemode "ares"
    set ::Data::paranoid 1
    set ::Data::animlog ""
    set ::Data::ignoreglobals 0
    set ::Data::quiet_mode 1
    set ::Data::logproc ::Logging::logputs_impl
    set ::Data::maperr {}
    ::Logging::reset_counts
}

# --------------------------------------------------------------------------
# One failure report: seed + generated input kept on disk for reproduction
# --------------------------------------------------------------------------
proc fz_fail {f i step err} {
    global tmp_dir
    puts "FUZZ FAIL iter=$i step=$step"
    puts "  seed=[expr {$::fz_base + $i * 7919}] (rerun: test_fuzz_parser.tcl)"
    puts "  err=$err"
    foreach line [lrange [split $::errorInfo \n] 0 4] {
        if {$line ne ""} { puts "  | $line" }
    }
    if {[file exists $f]} { puts "  input kept: $f" }
    return 0
}

# Step runner: every step must complete without a Tcl error
proc fz_steps {f i} {
    foreach {step script} [list \
        parse_map       "::MapParser::parse_map {$f}" \
        validate_events "::Validators::validate_events" \
        validate_actions "::Validators::validate_actions" \
    ] {
        if {[catch {uplevel 1 $script} err]} {
            return [fz_fail $f $i $step $err]
        }
    }
    return 1
}

# --------------------------------------------------------------------------
# Real-map scaffolding: section headers + subsampled entries of the control
# map, so [Events]/[Actions]/[Triggers] and friends always reach the
# validators with realistic data around the injected garbage.
# --------------------------------------------------------------------------
proc fz_real_sections {} {
    set wanted {Basic Houses Countries Events Actions Triggers Tags TeamTypes \
        TaskForces ScriptTypes Structures Units Infantry Waypoints \
        VariableNames CellTags AITriggerTypes Smudge Terrain}
    set out {}
    set want 0
    foreach line $::fz_base_lines {
        if {[string index $line 0] eq "\["} {
            set want 0
            set cc [string first "\]" $line]
            if {$cc != -1} {
                set name [string range $line 1 [expr {$cc - 1}]]
                if {$name in $wanted} { set want 1; lappend out $line }
            }
            continue
        }
        if {$want} {
            if {[string first "=" $line] == -1} continue
            if {[fz_n 4] != 0} { lappend out $line }   ;# keep 3 of 4 entries
        }
    }
    return $out
}

# --------------------------------------------------------------------------
# Family 1: real scaffolding or pure garbage INI, always mixed with junk lines
# --------------------------------------------------------------------------
proc fz_run_ini {i} {
    global tmp_dir
    fz_seed [expr {$::fz_base + $i * 7919}]
    fz_reset
    set ::Data::path "$tmp_dir/"
    set ::Data::argv "fuzz_$i.map"
    set lines {}
    # real scaffolding in every other iteration, pure garbage otherwise
    if {[fz_n 2] == 0 && [llength $::fz_base_lines] > 0} {
        set lines [fz_real_sections]
    } else {
        lappend lines [fz_header]
    }
    set nlines [expr {5 + [fz_n 60]}]
    for {set k 0} {$k < $nlines} {incr k} { lappend lines [fz_line] }
    set f [file join $tmp_dir "fuzz_$i.map"]
    set fh [open $f w]
    puts $fh [join $lines "\n"]
    close $fh
    return [fz_steps $f $i]
}

# --------------------------------------------------------------------------
# Family 2: line-level mutants of the real control map
# --------------------------------------------------------------------------
set ::fz_base_map [file join $script_dir "TEST.map"]
set ::fz_base_lines {}
if {[catch {
    set fh [open $::fz_base_map r]
    set ::fz_base_lines [split [read $fh] "\n"]
    close $fh
} base_err]} {
    puts "test_fuzz_parser: cannot read base map: $base_err"
}

proc fz_run_mutant {i} {
    global tmp_dir
    fz_seed [expr {$::fz_base + 1000000 + $i * 104729}]
    fz_reset
    set ::Data::path "$tmp_dir/"
    set ::Data::argv "mutant_$i.map"

    set lines $::fz_base_lines

    set nops [expr {1 + [fz_n 5]}]
    for {set k 0} {$k < $nops} {incr k} {
        set n [llength $lines]
        if {$n == 0} break
        set idx [fz_n $n]
        switch [fz_n 7] {
            0 { set lines [lreplace $lines $idx $idx] }
            1 { set lines [lreplace $lines $idx $idx [fz_line]] }
            2 {
                set ln [lindex $lines $idx]
                set eq [string first "=" $ln]
                if {$eq > 0} {
                    set lines [lreplace $lines $idx $idx \
                        "[string range $ln 0 $eq][fz_pick $::fz_vals]"]
                }
            }
            3 {
                set ln [lindex $lines $idx]
                set eq [string first "=" $ln]
                if {$eq > 0} {
                    set lines [lreplace $lines $idx $idx [string replace $ln $eq $eq ""]]
                }
            }
            4 { set lines [linsert $lines [expr {$idx + 1}] [lindex $lines $idx]] }
            5 { set lines [lrange $lines 0 $idx] }
            default {
                set ln [lindex $lines $idx]
                if {[string index $ln 0] eq "\["} {
                    set lines [lreplace $lines $idx $idx [fz_header]]
                } else {
                    set lines [lreplace $lines $idx $idx [fz_line]]
                }
            }
        }
    }

    set f [file join $tmp_dir "mutant_$i.map"]
    set fh [open $f w]
    puts -nonewline $fh [join $lines "\n"]
    close $fh
    return [fz_steps $f $i]
}

# --------------------------------------------------------------------------
# Test definitions
# --------------------------------------------------------------------------
for {set i 0} {$i < 200} {incr i} {
    test "fuzz-ini-[format %03d $i]" "garbage INI iteration $i parses without a Tcl error" \
        -body [list fz_run_ini $i] -result 1
}
for {set i 0} {$i < 10} {incr i} {
    test "fuzz-map-[format %02d $i]" "TEST.map mutant $i parses without a Tcl error" \
        -body [list fz_run_mutant $i] -result 1
}

cleanupTests
