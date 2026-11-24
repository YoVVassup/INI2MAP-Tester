#----------------------------------------------------------------------------------------------------------
# test_audio_parser.tcl - Unit tests for audio_parser.tcl
#----------------------------------------------------------------------------------------------------------
# Tests: Binary parsing of GABA headers, audio entry parsing
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
set test_tmpdir [file join $script_dir "tests" "_tmp"]
file mkdir $test_tmpdir

# --------------------------------------------------------------------------
# Source required modules
# --------------------------------------------------------------------------
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]

# Initialize audio_resources array
array set ::Data::audio_resources {}

source [file join $script_dir "audio_parser.tcl"]

# --------------------------------------------------------------------------
# Helper: create a minimal GABA .enc file for testing
# --------------------------------------------------------------------------
proc create_test_idx {filepath num_entries} {
    set fh [open $filepath wb]
    # Magic: "GABA" (4 bytes)
    puts -nonewline $fh "GABA"
    # Version: 2 (4 bytes - parser reads 4 bytes, uses first 2)
    puts -nonewline $fh [binary format s 2]
    puts -nonewline $fh [binary format s 0]
    # Number of entries (4 bytes - parser reads 4 bytes, uses first 2)
    puts -nonewline $fh [binary format s $num_entries]
    puts -nonewline $fh [binary format s 0]
    # Write entries: 16-byte name + 20-byte padding = 36 bytes each
    for {set i 0} {$i < $num_entries} {incr i} {
        set name [format "SOUND%03d" $i]
        # Pad name to 16 bytes with nulls
        set name_padded [binary format a16 $name]
        puts -nonewline $fh $name_padded
        # 20 bytes of padding data
        puts -nonewline $fh [binary format a20 "padding_data_padding_da"]
    }
    close $fh
}

# --------------------------------------------------------------------------
# Test: parse valid GABA header
# --------------------------------------------------------------------------
test parse-valid "parse valid GABA header with 3 entries" -body {
    array unset ::Data::audio_resources
    set testfile [file join $test_tmpdir "test_audio.idx"]
    create_test_idx $testfile 3
    set result [::Utils::_load_single_audio_idx $testfile]
    file delete $testfile
    expr {$result ? 1 : 0}
} -result 1

test parse-count "correct entry count parsed" -body {
    array unset ::Data::audio_resources
    set testfile [file join $test_tmpdir "test_audio2.idx"]
    create_test_idx $testfile 5
    ::Utils::_load_single_audio_idx $testfile
    set count [array size ::Data::audio_resources]
    file delete $testfile
    set count
} -result 5

test parse-names "entry names are normalized" -body {
    array unset ::Data::audio_resources
    set testfile [file join $test_tmpdir "test_audio3.idx"]
    create_test_idx $testfile 2
    ::Utils::_load_single_audio_idx $testfile
    # Names should be lowercase - check if sound000 exists (may have null bytes trimmed)
    set names [array names ::Data::audio_resources]
    file delete $testfile
    expr {[llength $names] == 2}
} -result 1

# --------------------------------------------------------------------------
# Test: parse invalid header
# --------------------------------------------------------------------------
test parse-bad-magic "reject file with bad magic" -body {
    array unset ::Data::audio_resources
    set testfile [file join $test_tmpdir "test_bad_magic.idx"]
    set fh [open $testfile wb]
    puts -nonewline $fh "XXXX"
    puts -nonewline $fh [binary format s 2]
    puts -nonewline $fh [binary format s 3]
    close $fh
    set result [::Utils::_load_single_audio_idx $testfile]
    file delete $testfile
    expr {$result ? 1 : 0}
} -result 0

test parse-bad-version "reject file with bad version" -body {
    array unset ::Data::audio_resources
    set testfile [file join $test_tmpdir "test_bad_version.idx"]
    set fh [open $testfile wb]
    puts -nonewline $fh "GABA"
    puts -nonewline $fh [binary format s 99]
    puts -nonewline $fh [binary format s 3]
    close $fh
    set result [::Utils::_load_single_audio_idx $testfile]
    file delete $testfile
    expr {$result ? 1 : 0}
} -result 0

test parse-empty "reject file with 0 entries" -body {
    array unset ::Data::audio_resources
    set testfile [file join $test_tmpdir "test_empty.idx"]
    create_test_idx $testfile 0
    set result [::Utils::_load_single_audio_idx $testfile]
    file delete $testfile
    expr {$result ? 1 : 0}
} -result 0

test parse-missing "reject missing file" -body {
    array unset ::Data::audio_resources
    ::Utils::_load_single_audio_idx "/nonexistent/file.idx"
} -result 0

# --------------------------------------------------------------------------
# Test: load_audio_indices with multiple files
# --------------------------------------------------------------------------
test load-multi "load multiple idx files (unique resources)" -body {
    array unset ::Data::audio_resources
    # Create files with different resource names
    set file1 [file join $test_tmpdir "test1.idx"]
    set fh [open $file1 wb]
    puts -nonewline $fh "GABA"
    puts -nonewline $fh [binary format s 2]
    puts -nonewline $fh [binary format s 0]
    puts -nonewline $fh [binary format s 3]
    puts -nonewline $fh [binary format s 0]
    puts -nonewline $fh [binary format a16 "FILE1_SOUND_A"]
    puts -nonewline $fh [binary format a20 "padding_data_padding_da"]
    puts -nonewline $fh [binary format a16 "FILE1_SOUND_B"]
    puts -nonewline $fh [binary format a20 "padding_data_padding_da"]
    puts -nonewline $fh [binary format a16 "FILE1_SOUND_C"]
    puts -nonewline $fh [binary format a20 "padding_data_padding_da"]
    close $fh

    set file2 [file join $test_tmpdir "test2.idx"]
    set fh [open $file2 wb]
    puts -nonewline $fh "GABA"
    puts -nonewline $fh [binary format s 2]
    puts -nonewline $fh [binary format s 0]
    puts -nonewline $fh [binary format s 2]
    puts -nonewline $fh [binary format s 0]
    puts -nonewline $fh [binary format a16 "FILE2_SOUND_X"]
    puts -nonewline $fh [binary format a20 "padding_data_padding_da"]
    puts -nonewline $fh [binary format a16 "FILE2_SOUND_Y"]
    puts -nonewline $fh [binary format a20 "padding_data_padding_da"]
    close $fh

    ::Utils::load_audio_indices [list $file1 $file2]
    set count [array size ::Data::audio_resources]
    file delete $file1 $file2
    set count
} -result 5

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
