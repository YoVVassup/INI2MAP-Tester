# Check V2 crypto health of the current DLL: hash, self-test, decrypt a known file.
# Uses ffidl for XP-compatible DLL calls. V1/DEFAULT_KEY support was removed.

set script_dir [file dirname [file normalize [info script]]]
lappend auto_path [file join $script_dir "others" "ffidl"]
package require Ffidl

set dll_path [file join $script_dir "CryptoVisionLib_xp.dll"]

::ffidl::callout get_version {} pointer-utf8 [::ffidl::symbol $dll_path get_version]
::ffidl::callout test_key {} int [::ffidl::symbol $dll_path test_key]
::ffidl::callout get_dll_hash {} pointer-utf8 [::ffidl::symbol $dll_path get_dll_hash]
::ffidl::callout crypto_last_error_msg {} pointer-utf8 [::ffidl::symbol $dll_path crypto_last_error_msg]
::ffidl::callout decrypt_to_buffer_with_salt {pointer-utf8 pointer-var pointer-utf8 pointer-byte int} pointer [::ffidl::symbol $dll_path decrypt_to_buffer_with_salt]
::ffidl::callout free_buffer {pointer} void [::ffidl::symbol $dll_path free_buffer]

puts "Version: [get_version]"
puts "DLL hash: [get_dll_hash]"

set key_result [test_key]
puts "test_key: $key_result"
if {$key_result != 0} {
    puts "FAILED: [crypto_last_error_msg]"
    exit 1
}

# Salt comes from operational storage (env > HKCU registry > carrier > settings.cfg)
set salt_hex ""
catch {source [file join $script_dir "salt.tcl"]}
if {[llength [info procs ::Salt::resolve_from_cfg]]} {
    set salt_hex [::Salt::resolve_from_cfg [file join $script_dir "settings.cfg"]]
    puts "Salt source: $::Salt::source"
} else {
    catch { set salt_hex [dict get [source [file join $script_dir "settings.cfg"]] v2_salt] }
}
if {$salt_hex eq ""} {
    puts "ERROR: no V2 salt available (env/registry/carrier/settings.cfg)"
    exit 1
}

set enc_file [file join $script_dir "rulesmo.enc"]
if {[file exists $enc_file]} {
    set out_len_buf [binary format i 0]
    set dll_hash [get_dll_hash]
    set salt_bin [binary format H* $salt_hex]
    puts "\nTrying to decrypt $enc_file..."
    set buf [decrypt_to_buffer_with_salt $enc_file out_len_buf $dll_hash $salt_bin [string length $salt_bin]]
    if {$buf == 0} {
        puts "FAILED: [crypto_last_error_msg]"
        exit 1
    }
    binary scan $out_len_buf i len
    puts "Decrypted length: $len"
    free_buffer $buf
    puts "OK"
}
