#----------------------------------------------------------------------------------------------------------
# test_crypto_utils_cli.tcl - CLI integration tests for crypto_utils.tcl
# Runs crypto_utils.tcl in a subprocess and checks exit codes / output.
# Covers: in-memory round-trip self-test, --encrypt-originals --dry-run, usage output.
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
set test_tmpdir [file join $script_dir "tests" "_tmp"]
file mkdir $test_tmpdir
set crypto_util [file join $script_dir "crypto_utils.tcl"]

proc run_crypto_utils {args} {
    global crypto_util
    set tclsh [info nameofexecutable]
    set output ""
    set code 0
    if {[catch {
        set output [exec $tclsh $crypto_util {*}$args 2>@1]
    } err]} {
        # exec throws when exit code != 0; extract output and code
        set output $err
        set code 1
        if {[dict exists $::errorCode CHILDSTATUS]} {
            set status [dict get $::errorCode CHILDSTATUS]
            set code [lindex $status 2]
        } elseif {[string match "*child killed*" $err] || [string match "*exit*" $err]} {
            set code 1
        }
    }
    return [list $code $output]
}

# --------------------------------------------------------------------------
# Test 1: no arguments runs round-trip self-test successfully
# --------------------------------------------------------------------------
test cu-roundtrip "no args runs round-trip self-test" -body {
    lassign [run_crypto_utils] code output
    list $code [string match "*Round-trip test PASSED*" $output]
} -result {0 1}

# --------------------------------------------------------------------------
# Test 2: --encrypt-originals --dry-run reports every original file
# (original_files/<variant>/*.ini + *.idx - counted recursively)
# --------------------------------------------------------------------------
proc count_original_files {} {
    set root [file join $::script_dir "original_files"]
    set n [llength [glob -nocomplain -directory $root -types f *]]
    foreach d [glob -nocomplain -directory $root -types d *] {
        incr n [llength [glob -nocomplain -directory $d -types f *]]
    }
    return $n
}

# Distinct output names: shared files (audio_*.idx) collide on their basename
# and overwrite each other, so the written .enc count is lower than the input count.
proc count_unique_enc_names {} {
    set root [file join $::script_dir "original_files"]
    set names {}
    foreach f [glob -nocomplain -directory $root -types f *] {
        dict set names [file rootname [file tail $f]] 1
    }
    foreach d [glob -nocomplain -directory $root -types d *] {
        foreach f [glob -nocomplain -directory $d -types f *] {
            dict set names [file rootname [file tail $f]] 1
        }
    }
    return [dict size $names]
}

test cu-dry-run "encrypt-originals dry-run lists all original files" -body {
    set n [count_original_files]
    lassign [run_crypto_utils --encrypt-originals --dry-run] code output
    list $code [string match "*$n ok, 0 failed*" $output] [string match "*rulesmo.ini*" $output]
} -result {0 1 1}

# --------------------------------------------------------------------------
# Test 3: dry-run does not write anything
# --------------------------------------------------------------------------
test cu-dry-run-no-write "dry-run writes no .enc files" -body {
    set outdir [file join $test_tmpdir "momt_dryrun_out"]
    file delete -force $outdir
    file mkdir $outdir
    lassign [run_crypto_utils --encrypt-originals --dry-run --out $outdir] code output
    set written [llength [glob -nocomplain -directory $outdir *]]
    file delete -force $outdir
    list $code $written
} -result {0 0}

# --------------------------------------------------------------------------
# Test 4: encrypt + verify round-trip of a produced file
# --------------------------------------------------------------------------
test cu-encrypt-verify "encrypt-originals to temp dir, decryptable output" -body {
    set outdir [file join $test_tmpdir "momt_enc_out"]
    file delete -force $outdir
    lassign [run_crypto_utils --encrypt-originals --out $outdir] code output
    set produced [llength [glob -nocomplain -directory $outdir *.enc]]
    set expected [count_unique_enc_names]
    # Verify a small file: evamo.enc should decrypt back to evamo.ini via decrypt_helper
    set ok 0
    if {$code == 0 && $produced == $expected} {
        set helper [file join [file dirname [info script]] ".." "decrypt_helper.tcl"]
        set helper [file normalize $helper]
        set dec_file [file join $test_tmpdir "momt_enc_out_evamo.bin"]
        set tclsh [info nameofexecutable]
        catch {
            exec cmd /c "$tclsh $helper [file dirname $helper] $outdir/evamo.enc > $dec_file 2>nul"
        }
        if {[file exists $dec_file]} {
            set fh [open $dec_file r]
            fconfigure $fh -translation binary
            set raw [read $fh]
            close $fh
            if {[string length $raw] > 4} {
                binary scan [string range $raw 0 3] i len
                set payload [string range $raw 4 end]
                set orig_fh [open [file join [file dirname $helper] "original_files" "Mental Omega" "evamo.ini"] r]
                fconfigure $orig_fh -translation binary
                set orig [read $orig_fh]
                close $orig_fh
                set ok [expr {$len == [string length $orig] && $payload eq $orig}]
            }
            file delete -force $dec_file
        }
    }
    file delete -force $outdir
    list $code [expr {$produced == $expected}] $ok
} -result {0 1 1}

# --------------------------------------------------------------------------
# Test 5: usage text with all options is printed (and exit code is 1)
# when no files and no --encrypt-originals mode are given
# --------------------------------------------------------------------------
test cu-usage "usage text shown when no files and no mode" -body {
    # --out is a valid flag, so parsing succeeds but files stay empty -> usage path
    lassign [run_crypto_utils --out [file join $test_tmpdir "momt_usage_out"]] code output
    list $code \
        [string match "*Usage: tclsh crypto_utils.tcl*" $output] \
        [string match "*--encrypt-originals*" $output] \
        [string match "*--salt <hex>*" $output] \
        [string match "*--dry-run*" $output] \
        [string match "*--force*" $output]
} -result {1 1 1 1 1 1}

# --------------------------------------------------------------------------
# Test 6: decrypt_buffer_v2 still works after the in-memory round-trip self-test
# (regression: free_buffer on the encrypt_to_memory result corrupts the heap
# and crashes every subsequent native call)
# --------------------------------------------------------------------------
test cu-decrypt-buffer-v2 "decrypt_buffer_v2 works after round-trip self-test" -body {
    source $crypto_util
    # Salt comes from operational config (settings.cfg), not from the test source.
    set salt [dict get [source [file join $script_dir "settings.cfg"]] v2_salt]
    set dec [decrypt_buffer_v2 [file join $script_dir "evamo.enc"] $salt]
    set fh [open [file join $script_dir "original_files" "Mental Omega" "evamo.ini"] r]
    fconfigure $fh -translation binary
    set orig [read $fh]
    close $fh
    expr {$dec ne "" && $dec eq $orig}
} -result 1

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
cleanupTests
