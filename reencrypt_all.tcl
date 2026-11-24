# reencrypt_all.tcl - Re-encrypt original .ini files with new CryptoVisionLib_xp.dll
set map_dir [file dirname [file normalize [info script]]]

lappend ::auto_path [file join $map_dir "others" "sha256"]
lappend ::auto_path [file join $map_dir "others" "ffidl"]

# Load crypto_utils which sets up ffidl bindings for encrypt/decrypt
source [file join $map_dir "crypto_utils.tcl"]

set new_dll [file join $map_dir "CryptoVisionLib_xp.dll"]
if {![file exists $new_dll]} {
    puts "ERROR: $new_dll not found"
    exit 1
}

# Compute hash of new DLL
set dh [open $new_dll rb]
fconfigure $dh -translation binary
set dll_data [read $dh]
close $dh
set dll_hash [::sha2::sha256 -hex $dll_data]
puts "New DLL hash: $dll_hash"

set salt_hex [crypto_config_value "v2_salt"]
if {$salt_hex eq ""} {
    puts "ERROR: v2_salt not found in settings.cfg"
    exit 1
}

set originals_dir [file join $map_dir "original_files"]
set build_dir [file join $map_dir "Build"]

# Collect originals recursively: original_files/ itself plus every variant
# subfolder ({Mental Omega, Red Alert 2, Red Alert 2 Yuris Revenge}).
# .ini and .idx are encrypted identically by encrypt_ini_v2, so one loop
# covers both (the old split was only cosmetic).
set originals {}
foreach f [lsort [glob -nocomplain -directory $originals_dir -types f *]] {
    lappend originals $f
}
foreach d [lsort [glob -nocomplain -directory $originals_dir -types d *]] {
    foreach f [lsort [glob -nocomplain -directory $d -types f *]] {
        lappend originals $f
    }
}
if {![llength $originals]} {
    puts "ERROR: no files found in $originals_dir"
    exit 1
}

foreach src_path $originals {
    set name [file rootname [file tail $src_path]]
    set enc_path [file join $build_dir "${name}.enc"]
    if {[catch {
        encrypt_ini_v2 $src_path $enc_path $salt_hex
        puts "  OK: $name.enc"
    } err]} {
        puts "  FAIL: $name - $err"
    }
}

puts ""
puts "=== Re-encryption complete ==="
puts "New hash for settings.cfg: $dll_hash"
