#----------------------------------------------------------------------------------------------------------
# test_crypto.tcl - Unit tests for crypto.tcl
#----------------------------------------------------------------------------------------------------------
# Tests: SHA-256 computation, V2 format detection, hash verification
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
set test_tmpdir [file join $script_dir "tests" "_tmp"]
file mkdir $test_tmpdir

# --------------------------------------------------------------------------
# Source required modules (without loading DLL)
# --------------------------------------------------------------------------
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]

# Set auto_path for sha256 and ffidl packages
set sha256_dir [file join $script_dir "others" "sha256"]
set ffidl_dir [file join $script_dir "others" "ffidl"]
if {[file isdirectory $sha256_dir] && [file exists [file join $sha256_dir "pkgIndex.tcl"]]} {
    if {$sha256_dir ni $::auto_path} {
        set ::auto_path [linsert $::auto_path 0 $sha256_dir]
    }
}
if {[file isdirectory $ffidl_dir] && [file exists [file join $ffidl_dir "pkgIndex.tcl"]]} {
    if {$ffidl_dir ni $::auto_path} {
        set ::auto_path [linsert $::auto_path 0 $ffidl_dir]
    }
}
package require sha256

# Source crypto.tcl (will fail to load DLL but we test helper functions)
source [file join $script_dir "crypto.tcl"]

# --------------------------------------------------------------------------
# SHA-256 hash computation
# --------------------------------------------------------------------------
test sha256-empty "compute SHA-256 of empty string" -body {
    # Create a temp file with known content
    set tmpfile [file join $test_tmpdir "test_sha256.txt"]
    set fh [open $tmpfile wb]
    puts -nonewline $fh "hello"
    close $fh
    set hash [::Crypto::compute_file_sha256 $tmpfile]
    file delete $tmpfile
    string tolower $hash
} -result "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"

test sha256-binary "compute SHA-256 of binary data" -body {
    set tmpfile [file join $test_tmpdir "test_sha256_bin.dat"]
    set fh [open $tmpfile wb]
    puts -nonewline $fh "\x00\x01\x02\x03"
    close $fh
    set hash [::Crypto::compute_file_sha256 $tmpfile]
    file delete $tmpfile
    # Just verify it returns a 64-char hex string
    expr {[string length $hash] == 64 && [regexp {^[0-9a-f]{64}$} $hash]}
} -result 1

# --------------------------------------------------------------------------
# V2 format detection
# --------------------------------------------------------------------------
test v2-detect-cv02 "detect V2 magic bytes" -body {
    set tmpfile [file join $test_tmpdir "test_v2.enc"]
    set fh [open $tmpfile wb]
    puts -nonewline $fh "CV02"
    puts -nonewline $fh "\x00\x00\x00\x00\x00\x00\x00\x00"
    close $fh
    set result [::Crypto::is_v2_format $tmpfile]
    file delete $tmpfile
    expr {$result ? 1 : 0}
} -result 1

test v2-detect-v1 "detect V1 format (no CV02 magic)" -body {
    set tmpfile [file join $test_tmpdir "test_v1.enc"]
    set fh [open $tmpfile wb]
    puts -nonewline $fh "ABCD"
    close $fh
    set result [::Crypto::is_v2_format $tmpfile]
    file delete $tmpfile
    expr {$result ? 1 : 0}
} -result 0

test v2-detect-short "detect V2 with short file" -body {
    set tmpfile [file join $test_tmpdir "test_short.enc"]
    set fh [open $tmpfile wb]
    puts -nonewline $fh "CV"
    close $fh
    set result [::Crypto::is_v2_format $tmpfile]
    file delete $tmpfile
    expr {$result ? 1 : 0}
} -result 0

# --------------------------------------------------------------------------
# Hash verification (without DLL)
# --------------------------------------------------------------------------
test hash-lowercase "hash is lowercase hex" -body {
    set tmpfile [file join $test_tmpdir "test_hash.txt"]
    set fh [open $tmpfile wb]
    puts -nonewline $fh "test data"
    close $fh
    set hash [::Crypto::compute_file_sha256 $tmpfile]
    file delete $tmpfile
    expr {$hash eq [string tolower $hash]}
} -result 1

test hash-length "hash is 64 chars" -body {
    set tmpfile [file join $test_tmpdir "test_hash_len.txt"]
    set fh [open $tmpfile wb]
    puts -nonewline $fh "test"
    close $fh
    set hash [::Crypto::compute_file_sha256 $tmpfile]
    file delete $tmpfile
    string length $hash
} -result 64

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
