package require Tcl 8.6

set script_dir [file dirname [file normalize [info script]]]
set map_dir [file normalize [file join $script_dir ".."]]

namespace eval ::Rules {}
namespace eval ::Data {}
namespace eval ::MapParser {}

source [file join $map_dir "utils.tcl"]
source [file join $map_dir "rules_parser" "core.tcl"]
source [file join $map_dir "rules_parser" "load_rules.tcl"]
source [file join $map_dir "rules_parser" "load_art.tcl"]
source [file join $map_dir "rules_parser" "load_ai.tcl"]
source [file join $map_dir "rules_parser" "load_sound.tcl"]
source [file join $map_dir "rules_parser" "load_theme.tcl"]
source [file join $map_dir "rules_parser" "load_eva.tcl"]
source [file join $map_dir "map_parser" "core.tcl"]
source [file join $map_dir "map_parser" "load_map.tcl"]
source [file join $map_dir "map_parser" "typedecl_units.tcl"]
source [file join $map_dir "map_parser" "typedecl_others.tcl"]
source [file join $map_dir "checks.tcl"]
source [file join $map_dir "validators.tcl"]
source [file join $map_dir "aicheck" "aicheck.tcl"]

lappend auto_path [file join $map_dir "others" "ffidl"] [file join $map_dir "others" "sha256"]
package require Ffidl
package require sha256

set ::app_dir $map_dir
set ::crypto_dll_expected_hash [string tolower [::sha2::sha256 -hex [read [open [file join $map_dir "CryptoVisionLib_xp.dll"] rb]]]]
source [file join $map_dir "crypto.tcl"]
# Salt comes from operational config (settings.cfg), not from the test source.
set ::Crypto::v2_salt [dict get [source [file join $map_dir "settings.cfg"]] v2_salt]

puts "=== Crypto Round-Trip Test ==="
puts ""

if {![::Crypto::init]} {
    puts "FAILED: Crypto init failed"
    exit 1
}

set test_files {rulesmo.ini aimo.ini artmo.ini soundmo.ini thememo.ini evamo.ini}
set original_dir [file join $map_dir "original_files" "Mental Omega"]
set temp_dir [file join $map_dir "test_temp"]
if {![file isdirectory $temp_dir]} { file mkdir $temp_dir }

set all_passed 1
foreach f $test_files {
    set orig_path [file join $original_dir $f]
    if {![file exists $orig_path]} {
        puts "SKIP: $f (not found)"
        continue
    }

    set enc_path [file join $temp_dir "${f}.enc"]
    set dec_path [file join $temp_dir "${f}.dec"]

    puts -nonewline "Testing $f... "

    # Read original
    set fh [open $orig_path r]
    fconfigure $fh -translation binary
    set original [read $fh]
    close $fh

    # Encrypt
    set dll_hash [::Crypto::get_dll_hash]
    set salt_bin [binary format H* $::Crypto::v2_salt]
    set salt_len [string length $salt_bin]
    if {[catch {set res [::Crypto::dll_encrypt_ini_with_salt $orig_path $enc_path $dll_hash $salt_bin $salt_len]} err]} {
        puts "ENCRYPT FAILED: $err"
        set all_passed 0
        continue
    }

    # Decrypt
    if {[catch {set decrypted_bin [::Crypto::decrypt_buffer_v2 $enc_path]} err]} {
        puts "DECRYPT FAILED: $err"
        set all_passed 0
        continue
    }

    # Compare
    if {$original eq $decrypted_bin} {
        puts "PASS"
    } else {
        puts "MISMATCH (orig=[string length $original] dec=[string length $decrypted_bin])"
        set all_passed 0
    }
}

# Cleanup
file delete -force $temp_dir

puts ""
if {$all_passed} {
    puts "=== ALL TESTS PASSED ==="
} else {
    puts "=== SOME TESTS FAILED ==="
    exit 1
}
