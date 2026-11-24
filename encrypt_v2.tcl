# encrypt_v2.tcl - Encrypt original .ini files with v2 multi-factor encryption
set script_dir [file dirname [info script]]
lappend ::auto_path [file join $script_dir others sha256]

source [file join $script_dir crypto_utils.tcl]
