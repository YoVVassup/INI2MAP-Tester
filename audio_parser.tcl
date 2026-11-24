#----------------------------------------------------------------------------------------------------------
# audio_parser.tcl - Multi-file audio.idx loader for sound resource validation
# Supports v2 encrypted .enc files (decrypted in memory before parsing)
#----------------------------------------------------------------------------------------------------------

namespace eval ::Utils {
    variable audio_idx_loaded 0
}

# Decrypt .enc file to binary data in memory using v2 salt
proc ::Utils::_decrypt_idx_to_binary {enc_path} {
    return [::Crypto::decrypt_buffer_v2 $enc_path]
}

# Load a single audio index (.enc or .idx) and add its resources to the global array
proc ::Utils::_load_single_audio_idx {filepath} {
    # Try .enc first (v2 encrypted), fall back to plain .idx
    set enc_path [file rootname $filepath].enc
    set use_enc 0
    if {[file exists $enc_path] && $::Crypto::loaded && $::Crypto::v2_salt ne ""} {
        set use_enc 1
    } elseif {![file exists $filepath] || ![file readable $filepath]} {
        return 0
    }

    if {$use_enc} {
        if {[catch {::Utils::_decrypt_idx_to_binary $enc_path} bin_data]} {
            puts "WARNING: Cannot decrypt $enc_path: $bin_data"
            return 0
        }
        set data $bin_data
    } else {
        if {[catch {open $filepath rb} fh]} {
            puts "WARNING: Cannot open $filepath: $fh"
            return 0
        }
        fconfigure $fh -translation binary -buffering none
        set data [read $fh]
        close $fh
    }

    # Parse binary data
    set pos 0

    # Read header: 4 bytes magic + 2 bytes version (read 4 but only 2 meaningful)
    set magic [string range $data $pos [expr {$pos + 3}]]
    incr pos 4
    binary scan [string range $data $pos [expr {$pos + 3}]] s version
    incr pos 4

    if {$magic ne "GABA" || $version != 2} {
        puts "WARNING: [file tail $filepath] has invalid header (magic='$magic', version=$version). Skipping."
        return 0
    }

    binary scan [string range $data $pos [expr {$pos + 3}]] s num_entries
    incr pos 4
    if {$num_entries <= 0 || $num_entries > 100000} {
        puts "WARNING: [file tail $filepath] reports invalid entry count: $num_entries"
        return 0
    }

    set count 0
    if {[catch {
        for {set i 0} {$i < $num_entries} {incr i} {
            set raw_name [string range $data $pos [expr {$pos + 15}]]
            incr pos 16
            set name [lindex [split $raw_name \x00] 0]
            set name [regsub {\.wav$} [string tolower $name] ""]
            incr pos 20
            if {$name ne ""} {
                set ::Data::audio_resources($name) 1
                incr count
            }
        }
    } read_err]} {
        puts "WARNING: Error reading [file tail $filepath]: $read_err"
        return 0
    }
    set label [expr {$use_enc ? "[file tail $enc_path] (decrypted)" : [file tail $filepath]}]
    puts "Loaded $count resources from $label"
    return 1
}

# Main function: load all idx files from the provided list
proc ::Utils::load_audio_indices {idx_files} {
    # Pre-decrypt all audio .enc files in one subprocess spawn
    if {[info exists ::Crypto::loaded] && $::Crypto::loaded} {
        set enc_paths {}
        foreach idx_file $idx_files {
            lappend enc_paths [file rootname $idx_file].enc
        }
        catch {::Crypto::prefetch_enc_files $enc_paths}
    }
    set loaded 0
    foreach idx_file $idx_files {
        if {[::Utils::_load_single_audio_idx $idx_file]} {
            incr loaded
        }
    }
    if {$loaded > 0} {
        set ::Data::audio_resource_count [array size ::Data::audio_resources]
        set ::Data::audio_idx_available 1
        puts "Total unique audio resources loaded: $::Data::audio_resource_count"
    } else {
        set ::Data::audio_idx_available 0
        puts "WARNING: No audio index files could be loaded. Sound resource validation will be skipped."
    }
}
