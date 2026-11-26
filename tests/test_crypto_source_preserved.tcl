# test_crypto_source_preserved.tcl - Regression tests: decryption must never delete the source .enc file
#
# Bug being covered: crypto.tcl used ::tcl::tempdir (does not exist in Tcl 8.6), so the temp copy
# silently failed and "file delete -force $native_path" removed the ORIGINAL encrypted file.

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file normalize [info script]]]
set map_dir    [file normalize [file join $script_dir ".."]]

namespace eval ::Data {}

lappend auto_path [file join $map_dir "others" "ffidl"] [file join $map_dir "others" "sha256"]
package require Ffidl
package require sha256

set ::app_dir $map_dir
set ::crypto_dll_expected_hash [string tolower [::sha2::sha256 -hex [read [open [file join $map_dir "CryptoVisionLib_xp.dll"] rb]]]]
source [file join $map_dir "crypto.tcl"]
# Salt comes from operational storage (env > HKCU registry > carrier >
# settings.cfg); a fixed round-trip salt is only the last-resort fallback.
set ::Crypto::v2_salt ""
catch {source [file join $map_dir "salt.tcl"]}
if {[llength [info procs ::Salt::resolve_from_cfg]]} {
    set ::Crypto::v2_salt [::Salt::resolve_from_cfg [file join $map_dir "settings.cfg"]]
}
if {$::Crypto::v2_salt eq ""} {
    set ::Crypto::v2_salt "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
}

if {![::Crypto::init]} {
    puts "FAILED: Crypto init failed"
    exit 1
}

set test_dir [file join $map_dir "test_crypto_src_tmp"]
file delete -force $test_dir
file mkdir $test_dir

# Small valid INI source to encrypt
set ini_path [file join $test_dir "sample.ini"]
set fh [open $ini_path w]
puts $fh "\[General\]"
puts $fh "Name=Test"
puts $fh "Count=42"
close $fh

set enc_path [file join $test_dir "sample.enc"]
set dll_hash [::Crypto::get_dll_hash]
set salt_bin [binary format H* $::Crypto::v2_salt]
set salt_len [string length $salt_bin]
::Crypto::dll_encrypt_ini_with_salt $ini_path $enc_path $dll_hash $salt_bin $salt_len
set enc_size_before [file size $enc_path]

test crypto-temp-copy-is-distinct "temp copy resolves outside the source directory" -body {
    set copy [::Crypto::_copy_to_native_temp $enc_path]
    expr {[file normalize $copy] ne [file normalize $enc_path] && [file exists $copy]}
} -cleanup {
    catch {file delete -force $copy}
} -result 1

test crypto-decrypt-buffer-keeps-source "decrypt_buffer_v2 leaves the source file intact" -body {
    set data [::Crypto::decrypt_buffer_v2 $enc_path]
    list [expr {[file exists $enc_path] ? 1 : 0}] [file size $enc_path] [expr {[string length $data] > 0 ? 1 : 0}]
} -result [list 1 $enc_size_before 1]

test crypto-decrypt-ini-keeps-source "decrypt_ini_to_string leaves the source file intact" -body {
    set text [::Crypto::decrypt_ini_to_string $enc_path]
    list [expr {[file exists $enc_path] ? 1 : 0}] [file size $enc_path] \
         [expr {[string first "Count=42" $text] >= 0 ? 1 : 0}]
} -result [list 1 $enc_size_before 1]

test crypto-decrypt-missing-source-is-not-recreated "a missing source file produces an error and no file" -body {
    set missing [file join $test_dir "does_not_exist.enc"]
    set code [catch {::Crypto::decrypt_buffer_v2 $missing} msg]
    list $code [expr {$msg ne "" ? 1 : 0}] [file exists $missing]
} -result [list 1 1 0]

file delete -force $test_dir

cleanupTests
