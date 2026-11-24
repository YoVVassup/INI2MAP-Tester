#----------------------------------------------------------------------------------------------------------
# crypto.tcl - Decrypting .enc files via CryptoVisionLib_xp.dll using ffidl
# XP-compatible: uses ffidl + Windows API for memory management
#----------------------------------------------------------------------------------------------------------

namespace eval ::Crypto {
    variable loaded 0
    variable crypto_dll_path ""
    variable dll_hash ""
    variable v2_salt ""
    variable temp_dir ""
    variable use_subprocess 0
    variable tclsh_path ""
    variable decrypt_helper_path ""
    variable prefetched [dict create]
}

proc ::Crypto::_detect_starpack {} {
    variable use_subprocess
    variable tclsh_path
    variable decrypt_helper_path

    set exe [info nameofexecutable]
    set tail [file tail $exe]
    set root [file rootname $tail]
    # Starpack variants: MOMT.exe / RA2MT.exe / RA2YRMT.exe - these resolve
    # runtime files (settings.cfg, .enc) next to the exe, so spawn decrypt_helper.
    if {[string tolower $root] in {momt ra2mt ra2yrmt}} {
        set use_subprocess 1
    }

    if {$use_subprocess} {
        set tclsh_path ""
        set candidates {}
        if {[info exists ::Config::tclsh_path] && $::Config::tclsh_path ne ""} {
            lappend candidates $::Config::tclsh_path
        }
        foreach rel [list \
                [file join $::app_dir "tclsh86.exe"] \
                [file join $::app_dir "tclsh.exe"] \
                [file join $::app_dir "bin" "tclsh86.exe"] \
                [file join $::app_dir "tcl" "bin" "tclsh86.exe"]] {
            lappend candidates $rel
        }
        lappend candidates "tclsh86.exe" "tclsh.exe"
        foreach candidate $candidates {
            if {[file exists $candidate]} {
                set tclsh_path [file normalize $candidate]
                break
            }
            if {[catch {exec where $candidate} result] == 0} {
                set tclsh_path [string trim [lindex [split $result "\n"] 0]]
                break
            }
        }
        if {$tclsh_path eq ""} {
            puts stderr "WARNING: tclsh not found, subprocess decrypt unavailable"
            set use_subprocess 0
            return
        }

        set decrypt_helper_path [file join $::app_dir "decrypt_helper.tcl"]
        if {![file exists $decrypt_helper_path]} {
            set decrypt_helper_path [file join [file dirname $::app_dir] "decrypt_helper.tcl"]
        }
        if {![file exists $decrypt_helper_path]} {
            puts stderr "WARNING: decrypt_helper.tcl not found, subprocess decrypt unavailable"
            set use_subprocess 0
            return
        }

        puts "Subprocess decrypt mode: tclsh=$tclsh_path"
    }
}

proc ::Crypto::_system_tempdir {} {
    foreach v {TEMP TMP} {
        if {[info exists ::env($v)] && $::env($v) ne "" && [file isdirectory $::env($v)]} {
            return $::env($v)
        }
    }
    return [file normalize [pwd]]
}

proc ::Crypto::_init_temp_dir {} {
    variable temp_dir
    if {$temp_dir ne "" && [file isdirectory $temp_dir]} { return $temp_dir }
    # Per-PID subdirectory: parallel MOMT instances must not share temp copies
    set temp_dir [file join [::Crypto::_system_tempdir] "momt_crypto_tmp" "p[pid]"]
    if {![file isdirectory $temp_dir]} {
        file mkdir $temp_dir
    }
    return $temp_dir
}

proc ::Crypto::_copy_to_native_temp {enc_path} {
    variable temp_dir
    if {$temp_dir eq ""} { ::Crypto::_init_temp_dir }
    set tail [file tail $enc_path]
    set dest [file join $temp_dir $tail]
    if {[file normalize $dest] eq [file normalize $enc_path]} {
        error "temp copy of '$enc_path' resolves to the file itself"
    }
    file copy -force -- $enc_path $dest
    return $dest
}

# Deletes the temporary copy of a file. $is_temp is 0 when the temporary copy
# could not be created and the original file was used directly - in that case
# the file must be left untouched.
proc ::Crypto::_delete_temp {path is_temp} {
    if {!$is_temp} return
    catch { file delete -force $path }
}

package require sha256
package require Ffidl

proc ::Crypto::compute_file_sha256 {filepath} {
    set fh [open $filepath rb]
    fconfigure $fh -translation binary
    set data [read $fh]
    close $fh
    return [::sha2::sha256 -hex $data]
}

# Validate that a length from the DLL is within sane bounds (prevents OOM / native buffer leak)
# Max 512 MB — INI files are at most a few MB; larger means corrupted/hostile DLL output
proc ::Crypto::_check_len {len filepath} {
    if {![string is integer -strict $len] || $len < 0 || $len > 536870912} {
        error "Invalid decrypted length $len for $filepath (expected 0..512MB)"
    }
}

proc ::Crypto::init {{dll_path ""}} {
    variable loaded
    variable crypto_dll_path

    if {$loaded} { return 1 }

    if {$dll_path eq ""} {
        set dll_path [file join $::app_dir "CryptoVisionLib_xp.dll"]
    }

    set crypto_dll_path [file normalize $dll_path]
    if {![file exists $crypto_dll_path]} {
        puts stderr "FATAL: CryptoVisionLib_xp.dll not found: $crypto_dll_path"
        return 0
    }

    set computed_hash [string tolower [::Crypto::compute_file_sha256 $crypto_dll_path]]
    global crypto_dll_expected_hash
    if {![info exists crypto_dll_expected_hash] || $crypto_dll_expected_hash eq ""} {
        puts stderr "FATAL: crypto_dll_expected_hash not defined in settings.cfg."
        return 0
    }

    if {$computed_hash ne [string tolower $crypto_dll_expected_hash]} {
        puts stderr "FATAL: CryptoVisionLib_xp.dll hash mismatch!"
        puts stderr "  Computed: $computed_hash"
        puts stderr "  Expected: $crypto_dll_expected_hash"
        return 0
    }
    puts "CryptoVisionLib_xp.dll hash verification passed."

    # Register DLL functions via ffidl
    if {[catch {
        ::ffidl::callout ::Crypto::dll_decrypt_to_buffer \
            {pointer-utf8 pointer-var} pointer \
            [::ffidl::symbol $crypto_dll_path decrypt_to_buffer]
    } err]} {
        puts stderr "FATAL: decrypt_to_buffer: $err"
        return 0
    }

    if {[catch {
        ::ffidl::callout ::Crypto::dll_free_buffer \
            {pointer} void \
            [::ffidl::symbol $crypto_dll_path free_buffer]
    } err]} {
        puts stderr "FATAL: free_buffer: $err"
        return 0
    }

    catch {
        ::ffidl::callout ::Crypto::dll_crypto_last_error_msg \
            {} pointer-utf8 \
            [::ffidl::symbol $crypto_dll_path crypto_last_error_msg]
    }

    if {[catch {
        ::ffidl::callout ::Crypto::dll_get_dll_hash \
            {} pointer-utf8 \
            [::ffidl::symbol $crypto_dll_path get_dll_hash]
    } err]} {
        puts stderr "FATAL: get_dll_hash: $err"
        return 0
    }

    if {[catch {
        ::ffidl::callout ::Crypto::dll_encrypt_ini_with_salt \
            {pointer-utf8 pointer-utf8 pointer-utf8 pointer-byte int} int \
            [::ffidl::symbol $crypto_dll_path encrypt_ini_with_salt]
    } err]} {
        puts stderr "FATAL: encrypt_ini_with_salt: $err"
        return 0
    }

    if {[catch {
        ::ffidl::callout ::Crypto::dll_decrypt_to_buffer_with_salt \
            {pointer-utf8 pointer-var pointer-utf8 pointer-byte int} pointer \
            [::ffidl::symbol $crypto_dll_path decrypt_to_buffer_with_salt]
    } err]} {
        puts stderr "FATAL: decrypt_to_buffer_with_salt: $err"
        return 0
    }

    if {[catch {
        ::ffidl::callout ::Crypto::dll_memcpy \
            {pointer-var pointer int} void \
            [::ffidl::symbol kernel32.dll RtlMoveMemory]
    } err]} {
        puts stderr "FATAL: RtlMoveMemory: $err"
        return 0
    }

    puts "CryptoVisionLib_xp.dll loaded (ffidl)."

    # Optional key test
    set _key_ok 1
    catch {
        ::ffidl::callout ::Crypto::dll_test_key {} int \
            [::ffidl::symbol $crypto_dll_path test_key]
        if {[::Crypto::dll_test_key] != 0} {
            puts stderr "FATAL: Crypto key validation failed!"
            set _key_ok 0
        } else {
            puts "Crypto key test passed."
        }
    }
    if {!$_key_ok} { return 0 }

    set loaded 1
    ::Crypto::_detect_starpack
    return 1
}

# Decrypt several .enc files in ONE subprocess run.
# decrypt_helper.tcl accepts multiple files and writes one
# (int32 LE length + payload) frame per file; frames are split here.
proc ::Crypto::_subprocess_decrypt_multi {enc_paths} {
    variable tclsh_path
    variable decrypt_helper_path
    variable v2_salt

    set base_dir $::app_dir
    # Pass the EFFECTIVE salt so a CLI --salt override reaches the subprocess
    # (the helper otherwise falls back to settings.cfg).
    set cmd [list $tclsh_path $decrypt_helper_path --salt $v2_salt $base_dir]
    foreach p $enc_paths { lappend cmd $p }
    set fd [open "|$cmd" rb]
    fconfigure $fd -translation binary -buffering none
    set raw [read $fd]
    close $fd

    set payloads {}
    set pos 0
    set total [string length $raw]
    foreach enc_path $enc_paths {
        if {$pos + 4 > $total} {
            error "subprocess decrypt returned no data for $enc_path"
        }
        binary scan [string range $raw $pos [expr {$pos + 3}]] i len
        incr pos 4
        if {$len < 0 || $pos + $len > $total} {
            error "subprocess decrypt truncated output for $enc_path"
        }
        lappend payloads [string range $raw $pos [expr {$pos + $len - 1}]]
        incr pos $len
    }
    return $payloads
}

proc ::Crypto::_subprocess_decrypt {enc_path} {
    return [lindex [::Crypto::_subprocess_decrypt_multi [list $enc_path]] 0]
}

# Common decrypt core: temp copy → DLL call → len check → memcpy → cleanup.
# Returns raw binary data. salt_hex="" means V1 (no salt).
proc ::Crypto::_decrypt_core {enc_path {salt_hex ""}} {
    variable loaded
    variable v2_salt
    if {!$loaded} { error "Crypto module not initialized." }

    # Only ever delete the temporary copy - never the original .enc file
    set native_path $enc_path
    set temp_copy 0
    if {![catch {set native_path [::Crypto::_copy_to_native_temp $enc_path]}]} {
        set temp_copy 1
    }

    set out_len_buf [binary format i 0]
    if {$salt_hex eq ""} {
        # V1
        set buf_ptr [::Crypto::dll_decrypt_to_buffer $native_path out_len_buf]
    } else {
        # V2
        set dll_hash [::Crypto::get_dll_hash]
        set salt_bin [binary format H* $salt_hex]
        set salt_len [string length $salt_bin]
        set buf_ptr [::Crypto::dll_decrypt_to_buffer_with_salt $native_path out_len_buf $dll_hash $salt_bin $salt_len]
    }

    if {$buf_ptr == 0} {
        set err_msg "decryption failed"
        catch { set err_msg [::Crypto::dll_crypto_last_error_msg] }
        ::Crypto::_delete_temp $native_path $temp_copy
        error "$err_msg for $enc_path"
    }

    binary scan $out_len_buf i len
    # Free the native buffer and the temp copy on EVERY exit path below:
    # _check_len error, OOM in binary format, callout exception.
    set code [catch {
        ::Crypto::_check_len $len $enc_path
        set dest_buf [binary format a$len ""]
        if {[catch {::Crypto::dll_memcpy dest_buf $buf_ptr $len} memcpy_err]} {
            error "memcpy failed: $memcpy_err"
        }
    } err opts]
    catch {::Crypto::dll_free_buffer $buf_ptr}
    ::Crypto::_delete_temp $native_path $temp_copy
    if {$code} { return -options $opts $err }
    return $dest_buf
}

# Raw decrypt (no cache, no encoding conversion): subprocess or in-process.
proc ::Crypto::_decrypt_raw {enc_path} {
    variable use_subprocess
    variable v2_salt
    if {$use_subprocess} {
        return [::Crypto::_subprocess_decrypt $enc_path]
    }
    if {[::Crypto::is_v2_format $enc_path]} {
        if {$v2_salt eq ""} { error "V2 file but no salt provided." }
        return [::Crypto::_decrypt_core $enc_path $v2_salt]
    }
    return [::Crypto::_decrypt_core $enc_path]
}

# Pre-decrypt a batch of .enc files with a single subprocess spawn (or
# eagerly in-process) and cache raw payloads for decrypt_ini_to_string /
# decrypt_buffer_v2. Each cache entry is [list salt payload]; consumers
# only use an entry when its salt matches the salt they would apply.
proc ::Crypto::prefetch_enc_files {enc_paths} {
    variable use_subprocess
    variable v2_salt
    variable prefetched

    set existing {}
    foreach p $enc_paths {
        if {[file exists $p] && ![dict exists $prefetched $p]} {
            lappend existing $p
        }
    }
    if {![llength $existing]} { return }

    if {$use_subprocess} {
        set payloads [::Crypto::_subprocess_decrypt_multi $existing]
    } else {
        set payloads {}
        foreach p $existing {
            lappend payloads [::Crypto::_decrypt_raw $p]
        }
    }

    foreach p $existing payload $payloads {
        set salt ""
        if {[::Crypto::is_v2_format $p]} { set salt $v2_salt }
        dict set prefetched $p [list $salt $payload]
    }
}

proc ::Crypto::decrypt_ini_to_string {enc_path} {
    variable loaded
    variable v2_salt
    variable prefetched
    if {!$loaded} { error "Crypto module not initialized." }

    set bin_data ""
    set from_cache 0
    if {[dict exists $prefetched $enc_path]} {
        lassign [dict get $prefetched $enc_path] entry_salt payload
        if {$entry_salt eq "" || $entry_salt eq $v2_salt} {
            set prefetched [dict remove $prefetched $enc_path]
            set bin_data $payload
            set from_cache 1
        }
    }
    if {!$from_cache} {
        set bin_data [::Crypto::_decrypt_raw $enc_path]
    }

    if {[info exists ::Data::ini_encoding] && $::Data::ini_encoding ne ""} {
        set enc $::Data::ini_encoding
    } else {
        set enc [encoding system]
    }
    return [encoding convertfrom $enc $bin_data]
}

proc ::Crypto::get_dll_hash {} {
    variable dll_hash
    variable crypto_dll_path
    if {$dll_hash ne ""} { return $dll_hash }
    set fh [open $crypto_dll_path rb]
    fconfigure $fh -translation binary
    set data [read $fh]
    close $fh
    set dll_hash [string tolower [::sha2::sha256 -hex $data]]
    return $dll_hash
}

proc ::Crypto::is_v2_format {enc_path} {
    set fh [open $enc_path rb]
    fconfigure $fh -translation binary
    set magic [read $fh 4]
    close $fh
    return [expr {$magic eq "CV02"}]
}

interp alias {} decrypt_ini_to_string {} ::Crypto::decrypt_ini_to_string

proc ::Crypto::decrypt_buffer_v2 {enc_path {salt_hex ""}} {
    variable loaded
    variable v2_salt
    variable use_subprocess
    variable prefetched
    if {!$loaded} { error "Crypto module not initialized." }

    # Consume a prefetched payload only when its salt matches what we would use
    if {[dict exists $prefetched $enc_path]} {
        lassign [dict get $prefetched $enc_path] entry_salt payload
        set eff_salt $salt_hex
        if {$eff_salt eq ""} { set eff_salt $v2_salt }
        if {$entry_salt eq "" || $entry_salt eq $eff_salt} {
            set prefetched [dict remove $prefetched $enc_path]
            return $payload
        }
    }

    if {$use_subprocess} {
        return [::Crypto::_subprocess_decrypt $enc_path]
    }

    if {$salt_hex eq ""} {
        if {$v2_salt eq ""} { error "V2 file but no salt provided." }
        set salt_hex $v2_salt
    }

    if {![regexp {^[0-9a-fA-F]+$} $salt_hex] || [string length $salt_hex] % 2 != 0} {
        error "Invalid V2 salt format (must be even-length hex string)"
    }

    return [::Crypto::_decrypt_core $enc_path $salt_hex]
}

interp alias {} decrypt_buffer_v2 {} ::Crypto::decrypt_buffer_v2
