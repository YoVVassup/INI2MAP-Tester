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
    return 1
}

# Common decrypt core: temp copy → DLL call → len check → memcpy → cleanup.
# Returns raw binary data. V2 (CV02) only - V1 support was removed.
proc ::Crypto::_decrypt_core {enc_path salt_hex} {
    variable loaded
    if {![::Crypto::is_v2_format $enc_path]} {
        error "Unsupported format (V1 support was removed): $enc_path"
    }
    if {!$loaded} { error "Crypto module not initialized." }
    if {$salt_hex eq ""} { error "V2 file but no salt provided." }

    # Only ever delete the temporary copy - never the original .enc file
    set native_path $enc_path
    set temp_copy 0
    if {![catch {set native_path [::Crypto::_copy_to_native_temp $enc_path]}]} {
        set temp_copy 1
    }

    set out_len_buf [binary format i 0]
    set dll_hash [::Crypto::get_dll_hash]
    set salt_bin [binary format H* $salt_hex]
    set salt_len [string length $salt_bin]
    set buf_ptr [::Crypto::dll_decrypt_to_buffer_with_salt $native_path out_len_buf $dll_hash $salt_bin $salt_len]

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

# Raw decrypt with the effective salt: in-process DLL call, no encoding
# conversion. V2 (CV02) only - V1 support was removed.
proc ::Crypto::_decrypt_raw {enc_path} {
    variable v2_salt
    return [::Crypto::_decrypt_core $enc_path $v2_salt]
}

proc ::Crypto::decrypt_ini_to_string {enc_path} {
    variable loaded
    if {!$loaded} { error "Crypto module not initialized." }

    set bin_data [::Crypto::_decrypt_raw $enc_path]

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
    if {!$loaded} { error "Crypto module not initialized." }

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
