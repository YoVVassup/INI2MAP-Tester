#----------------------------------------------------------------------------------------------------------
# crypto_utils.tcl - Standalone encryption/decryption utility for CryptoVisionLib_xp.dll
# Uses ffidl for XP-compatible DLL calls
#
# Modes:
#   (no arguments)                      In-memory round-trip self-test
#   --salt <hex> <files...>             Encrypt given files to <base>_enc<ext>
#   --encrypt-originals [options]       Encrypt everything in original_files/ (all
#                                       variant subfolders) to .enc in the project root
#
# Options for --encrypt-originals:
#   --salt <hex>        V2 salt (default: v2_salt from settings.cfg)
#   --out <dir>         Output directory (default: project root)
#   --force             Encrypt even if the loaded DLL hash differs from settings.cfg
#   --dry-run           Show what would be written, do not encrypt
#----------------------------------------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
lappend ::auto_path [file join $script_dir "others" "ffidl"]
lappend ::auto_path [file join $script_dir "others" "sha256"]

package require Ffidl

set dll_path [file join $script_dir "CryptoVisionLib_xp.dll"]
if {![file exists $dll_path]} {
    set dll_path [file join [pwd] "CryptoVisionLib_xp.dll"]
}
if {![file exists $dll_path]} {
    puts "ERROR: CryptoVisionLib_xp.dll not found in $script_dir or [pwd]"
    exit 1
}

if {[catch {
    ::ffidl::callout get_version {} pointer-utf8 [::ffidl::symbol $dll_path get_version]
    ::ffidl::callout test_key {} int [::ffidl::symbol $dll_path test_key]
    ::ffidl::callout free_buffer {pointer} void [::ffidl::symbol $dll_path free_buffer]
    ::ffidl::callout crypto_last_error_msg {} pointer-utf8 [::ffidl::symbol $dll_path crypto_last_error_msg]
    ::ffidl::callout get_dll_hash {} pointer-utf8 [::ffidl::symbol $dll_path get_dll_hash]
    ::ffidl::callout encrypt_ini_with_salt {pointer-utf8 pointer-utf8 pointer-utf8 pointer-byte int} int [::ffidl::symbol $dll_path encrypt_ini_with_salt]
    ::ffidl::callout decrypt_ini_with_salt {pointer-utf8 pointer-utf8 pointer-utf8 pointer-byte int} int [::ffidl::symbol $dll_path decrypt_ini_with_salt]
    ::ffidl::callout decrypt_to_buffer_with_salt {pointer-utf8 pointer-var pointer-utf8 pointer-byte int} pointer [::ffidl::symbol $dll_path decrypt_to_buffer_with_salt]
    ::ffidl::callout dll_memcpy {pointer-var pointer int} void [::ffidl::symbol kernel32.dll RtlMoveMemory]
} err]} {
    puts "ERROR: Failed to load CryptoVisionLib_xp.dll: $err"
    exit 1
}

set version [get_version]
puts "CryptoVisionLib version: $version"

if {[test_key] != 0} {
    puts "Key verification error: [crypto_last_error_msg]"
    exit 1
} else {
    puts "Key is valid"
}

set dll_hash_val [get_dll_hash]
puts "DLL SHA-256: $dll_hash_val"

proc encrypt_ini_v2 {input output salt_hex} {
    if {![regexp {^[0-9a-fA-F]+$} $salt_hex] || [string length $salt_hex] % 2 != 0} {
        puts "Invalid salt format (must be even-length hex string)"
        return 0
    }
    set dll_hash [get_dll_hash]
    set salt_bin [binary format H* $salt_hex]
    set salt_len [string length $salt_bin]
    set res [encrypt_ini_with_salt $input $output $dll_hash $salt_bin $salt_len]
    if {$res != 0} {
        puts "V2 Encryption error (code $res): [crypto_last_error_msg]"
        return 0
    }
    return 1
}

proc decrypt_ini_v2 {input output salt_hex} {
    if {![regexp {^[0-9a-fA-F]+$} $salt_hex] || [string length $salt_hex] % 2 != 0} {
        puts "Invalid salt format (must be even-length hex string)"
        return 0
    }
    set dll_hash [get_dll_hash]
    set salt_bin [binary format H* $salt_hex]
    set salt_len [string length $salt_bin]
    set res [decrypt_ini_with_salt $input $output $dll_hash $salt_bin $salt_len]
    if {$res != 0} {
        puts "V2 Decryption error (code $res): [crypto_last_error_msg]"
        return 0
    }
    return 1
}

proc decrypt_buffer_v2 {enc_path salt_hex} {
    if {![regexp {^[0-9a-fA-F]+$} $salt_hex] || [string length $salt_hex] % 2 != 0} {
        puts "Invalid salt format (must be even-length hex string)"
        return ""
    }
    set dll_hash [get_dll_hash]
    set salt_bin [binary format H* $salt_hex]
    set salt_len [string length $salt_bin]
    set out_len [binary format i 0]
    if {[catch {set buf_ptr [decrypt_to_buffer_with_salt $enc_path out_len $dll_hash $salt_bin $salt_len]} err]} {
        puts "V2 Decryption error: $err"
        return ""
    }
    if {$buf_ptr == 0} {
        puts "V2 Decryption error: [crypto_last_error_msg]"
        return ""
    }
    binary scan $out_len i len
    if {$len <= 0 || $len > 536870912} {
        catch { free_buffer $buf_ptr }
        puts "V2 Decryption error: implausible buffer length $len"
        return ""
    }
    set data [binary format a$len ""]
    if {[catch {dll_memcpy data $buf_ptr $len} err]} {
        catch { free_buffer $buf_ptr }
        puts "V2 Decryption error reading buffer: $err"
        return ""
    }
    catch { free_buffer $buf_ptr }
    return $data
}

set script_dir [file dirname [file normalize [info script]]]

# --------------------------------------------------------------------------
# Read a single value from settings.cfg (returns "" when unavailable)
# --------------------------------------------------------------------------
proc crypto_config_value {key} {
    global script_dir
    set cfg_path [file join $script_dir "settings.cfg"]
    if {![file exists $cfg_path]} { return "" }
    if {[catch {set cfg [source $cfg_path]}]} { return "" }
    if {[catch {set val [dict get $cfg $key]}]} { return "" }
    return $val
}

# --------------------------------------------------------------------------
# Encrypt every file in <src_dir> to <out_dir>/<basename>.enc
# --------------------------------------------------------------------------
proc encrypt_originals_batch {src_dir out_dir salt_hex {dry_run 0}} {
    if {![file isdirectory $src_dir]} {
        puts "ERROR: source directory not found: $src_dir"
        return 0
    }
    # Collect files from src_dir itself and from every variant subfolder
    # (original_files/{Mental Omega,Red Alert 2,Red Alert 2 Yuris Revenge}).
    # Output names are basenames, so only the shared audio_*.idx collide -
    # those are identical across folders and overwrite each other harmlessly.
    set files {}
    foreach f [lsort [glob -nocomplain -directory $src_dir -types f *]] {
        lappend files $f
    }
    foreach d [lsort [glob -nocomplain -directory $src_dir -types d *]] {
        foreach f [lsort [glob -nocomplain -directory $d -types f *]] {
            lappend files $f
        }
    }
    if {[llength $files] == 0} {
        puts "ERROR: no files found in $src_dir"
        return 0
    }
    if {!$dry_run && ![file isdirectory $out_dir]} {
        file mkdir $out_dir
    }

    set ok 0
    set failed 0
    foreach f $files {
        set dst [file join $out_dir "[file rootname [file tail $f]].enc"]
        if {$dry_run} {
            puts "  WOULD: [file tail $f] -> $dst"
            incr ok
            continue
        }
        if {[encrypt_ini_v2 $f $dst $salt_hex] && [file exists $dst]} {
            puts "  OK:   [file tail $f] -> [file tail $dst] ([file size $dst] bytes)"
            incr ok
        } else {
            puts "  FAIL: [file tail $f]"
            incr failed
        }
    }
    puts ""
    puts "=== encrypt-originals: $ok ok, $failed failed ([llength $files] files in [file tail $src_dir]) ==="
    return [expr {$failed == 0 && $ok > 0}]
}

# --------------------------------------------------------------------------
# Verify the loaded DLL against crypto_dll_expected_hash in settings.cfg
# Returns 1 when no expectation is configured.
# --------------------------------------------------------------------------
proc verify_dll_hash {force} {
    set expected [crypto_config_value "crypto_dll_expected_hash"]
    set actual [string tolower [get_dll_hash]]
    if {$expected eq ""} {
        puts "NOTE: crypto_dll_expected_hash not set in settings.cfg (skipped check)"
        return 1
    }
    if {$expected eq $actual} {
        puts "DLL hash matches settings.cfg"
        return 1
    }
    puts "WARNING: DLL hash mismatch"
    puts "  settings.cfg expects: $expected"
    puts "  loaded DLL is:        $actual"
    puts "  .enc files embed the loaded DLL hash, so the app will reject them"
    puts "  unless settings.cfg is updated (or --force is used)."
    if {!$force} {
        puts "ABORT: re-run with --force to encrypt anyway."
        return 0
    }
    puts "Continuing because --force was given."
    return 1
}

if {[llength $argv] > 0} {
    set salt_hex ""
    set files {}
    set encrypt_originals 0
    set out_dir ""
    set force 0
    set dry_run 0
    set i 0
    set argc [llength $argv]
    while {$i < $argc} {
        set arg [lindex $argv $i]
        switch -exact -- $arg {
            "--salt" {
                incr i
                if {$i >= $argc} {
                    puts "ERROR: --salt requires a hex string argument"
                    exit 1
                }
                set salt_hex [lindex $argv $i]
            }
            "--out" {
                incr i
                if {$i >= $argc} {
                    puts "ERROR: --out requires a directory argument"
                    exit 1
                }
                set out_dir [lindex $argv $i]
            }
            "--encrypt-originals" {
                set encrypt_originals 1
            }
            "--force" {
                set force 1
            }
            "--dry-run" {
                set dry_run 1
            }
            default {
                lappend files $arg
            }
        }
        incr i
    }

    if {$encrypt_originals} {
        puts "CryptoVisionLib version: [get_version]"
        puts "DLL SHA-256: [get_dll_hash]"
        puts ""
        if {![verify_dll_hash $force]} {
            exit 1
        }
        if {$salt_hex eq ""} {
            set salt_hex [crypto_config_value "v2_salt"]
            if {$salt_hex ne ""} { puts "Salt: taken from settings.cfg (v2_salt)" }
        } else {
            puts "Salt: taken from --salt"
        }
        if {$salt_hex eq ""} {
            puts "ERROR: no salt. Pass --salt <hex> or set v2_salt in settings.cfg"
            exit 1
        }
        if {$out_dir eq ""} { set out_dir $script_dir }
        set src_dir [file join $script_dir "original_files"]
        puts "Source: $src_dir"
        puts "Output: $out_dir"
        puts ""
        set ok [encrypt_originals_batch $src_dir [file normalize $out_dir] $salt_hex $dry_run]
        exit [expr {$ok ? 0 : 1}]
    }

    if {[llength $files] == 0} {
        puts "Usage: tclsh crypto_utils.tcl \[options\] <files...>"
        puts "       tclsh crypto_utils.tcl --encrypt-originals \[options\]"
        puts "Options: --salt <hex>             Use v2 encryption"
        puts "         --encrypt-originals      Encrypt original_files/* to .enc in the project root"
        puts "         --out <dir>              Output directory for --encrypt-originals (default: project root)"
        puts "         --force                  Encrypt even on DLL hash mismatch"
        puts "         --dry-run                Show target paths without encrypting"
        exit 1
    }
    foreach file $files {
        set base [file rootname $file]
        set ext [file extension $file]
        if {$salt_hex eq ""} {
            puts "ERROR: no salt for $file. V1 encryption was removed; pass --salt <hex> or set v2_salt in settings.cfg"
            exit 1
        }
        puts "Encrypting (v2): $file -> ${base}_enc${ext}"
        encrypt_ini_v2 $file "${base}_enc${ext}" $salt_hex
    }
} else {
    puts "Testing V2 round-trip..."
    set salt_hex [crypto_config_value "v2_salt"]
    if {$salt_hex eq ""} {
        puts "ERROR: v2_salt not set in settings.cfg (V1 round-trip was removed)"
        exit 1
    }
    set tmp_base [file join [file normalize [pwd]] "selftest_[pid]"]
    if {[info exists ::env(TEMP)] && $::env(TEMP) ne ""} {
        set tmp_base [file join [file normalize $::env(TEMP)] "ini2map_selftest_[pid]"]
    }
    set tmp_in  "${tmp_base}.ini"
    set tmp_enc "${tmp_base}.enc"
    set tmp_out "${tmp_base}.out"
    set test_data "Test data for encryption\r\n"
    set fh [open $tmp_in wb]
    puts -nonewline $fh $test_data
    close $fh
    set ok [encrypt_ini_v2 $tmp_in $tmp_enc $salt_hex]
    if {$ok} { set ok [decrypt_ini_v2 $tmp_enc $tmp_out $salt_hex] }
    set got ""
    if {[file exists $tmp_out]} {
        set fh [open $tmp_out rb]
        set got [read $fh]
        close $fh
    }
    file delete -force $tmp_in $tmp_enc $tmp_out
    if {$ok && $got eq $test_data} {
        puts "Round-trip test PASSED"
    } else {
        puts "Round-trip test FAILED"
        exit 1
    }
}
