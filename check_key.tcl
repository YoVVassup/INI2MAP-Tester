# Check DEFAULT_KEY in current DLL vs what's needed
# Uses ffidl for XP-compatible DLL calls

package require Ffidl

set script_dir [file dirname [info script]]
set dll_path [file join $script_dir "CryptoVisionLib_xp.dll"]

::ffidl::callout get_version {} pointer-utf8 [::ffidl::symbol $dll_path get_version]
::ffidl::callout test_key {} int [::ffidl::symbol $dll_path test_key]
::ffidl::callout get_dll_hash {} pointer-utf8 [::ffidl::symbol $dll_path get_dll_hash]
::ffidl::callout DEFAULT_KEY {} pointer [::ffidl::symbol $dll_path DEFAULT_KEY]
::ffidl::callout crypto_last_error_msg {} pointer-utf8 [::ffidl::symbol $dll_path crypto_last_error_msg]
::ffidl::callout decrypt_to_buffer {pointer-utf8 pointer-var} pointer [::ffidl::symbol $dll_path decrypt_to_buffer]
::ffidl::callout free_buffer {pointer} void [::ffidl::symbol $dll_path free_buffer]

puts "Version: [get_version]"
puts "DLL hash: [get_dll_hash]"

set key_result [test_key]
puts "test_key: $key_result"
if {$key_result != 0} {
    puts "FAILED: [crypto_last_error_msg]"
    exit 1
}

set key_ptr [DEFAULT_KEY]
if {$key_ptr == 0} {
    puts "ERROR: DEFAULT_KEY returned NULL pointer"
    exit 1
}
puts "DEFAULT_KEY: present (key material not displayed)"

set enc_file [file join $script_dir "rulesmo.enc"]
if {[file exists $enc_file]} {
    set out_len 0
    puts "\nTrying to decrypt $enc_file..."
    set buf [decrypt_to_buffer $enc_file out_len]
    puts "Result ptr: $buf"
    if {$buf == 0 || $buf eq ""} {
        puts "FAILED: [crypto_last_error_msg]"
    } else {
        puts "Decrypted length: $out_len"
        free_buffer $buf
    }
}
