#----------------------------------------------------------------------------------------------------------
# test_salt.tcl - Unit tests for salt.tcl (HKCU registry + obfuscated carrier)
# Tests: hex checks, XOR round-trip, carrier encode/decode, file IO,
#        resolve order (env > registry > carrier > settings.cfg), conflict policy.
#
# IMPORTANT: all registry access uses the test hook ::Salt::reg_base
# (HKEY_CURRENT_USER\Software\INI2MAP Tester_tcltest) with scope "unittest" -
# the real key HKEY_CURRENT_USER\Software\INI2MAP Tester is NEVER touched.
# Covers: per-build salt scopes (salt_scope / exe name / "default").
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
set test_tmpdir [file join $script_dir "tests" "_tmp"]
file mkdir $test_tmpdir

lappend ::auto_path [file join $script_dir "others" "sha256"]
package require sha256

# Quiet mode so ::Salt::notice does not print to stdout during tests
namespace eval ::Data { variable quiet_mode 1 }
namespace eval ::CLI { variable salt "" }

source [file join $script_dir salt.tcl]

# --- Test hooks: scratch registry base key + temp carrier file + scope ---
set ::Salt::reg_base {HKEY_CURRENT_USER\Software\INI2MAP Tester_tcltest}
set ::Salt::reg_value "v2_salt"
set ::Salt::carrier_file [file join $test_tmpdir "_salt_test_carrier.cfg"]
set ::Salt::scope "unittest"
set ::Salt::scope_explicit 1

package require registry

proc cleanup_salt_state {} {
    # Delete the registry key of the scope currently in effect, ...
    catch {registry delete [::Salt::reg_path] $::Salt::reg_value}
    # ... then return to the default test scope and clean that key too
    set ::Salt::scope "unittest"
    set ::Salt::scope_explicit 1
    catch {registry delete [::Salt::reg_path] $::Salt::reg_value}
    catch {registry delete $::Salt::reg_base}
    catch {file delete -force [::Salt::carrier_path]}
    if {[info exists ::env(INI2MAP_SALT)]} { unset ::env(INI2MAP_SALT) }
    set ::Salt::pending {}
    set ::Salt::source ""
}

# Deterministic inputs
set salt_hex "06b37082aabbccddeeff001122334455667788990011223344556677ffbf12"
set dll_hash "35e17075642a9a4b460b4a1b08dc50ef1c3c3a20d6e1a5b7e2b1234567890ffb1"
set other_dll_hash "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

# --------------------------------------------------------------------------
# Test 1: _hex validation
# --------------------------------------------------------------------------
test salt-hex-check "_hex accepts even-length hex, rejects bad input" -body {
    list [::Salt::_hex "abc"] [::Salt::_hex "abcd"] [::Salt::_hex ""] \
         [::Salt::_hex "abcg"] [::Salt::_hex "abc de"]
} -result {0 1 0 0 0}

# --------------------------------------------------------------------------
# Test 2: XOR is an involution (round-trip)
# --------------------------------------------------------------------------
test salt-xor-roundtrip "xor_hex applied twice returns the original" -body {
    set key [::Salt::carrier_key $dll_hash]
    set once [::Salt::xor_hex $salt_hex $key]
    set twice [::Salt::xor_hex $once $key]
    list [expr {$once ne $salt_hex}] [expr {$twice eq $salt_hex}]
} -result {1 1}

# --------------------------------------------------------------------------
# Test 3: XOR with a key shorter than the payload repeats the key
# --------------------------------------------------------------------------
test salt-xor-key-repeat "xor_hex key repeats over payload" -body {
    # key "0a" (1 byte) repeated: 01 ^ 0a = 0b, ff ^ 0a = f5
    ::Salt::xor_hex "01ff" "0a"
} -result "0bf5"

# --------------------------------------------------------------------------
# Test 4: carrier encode/decode round-trip, key depends on dll_hash
# --------------------------------------------------------------------------
test salt-carrier-roundtrip "encode_carrier/decode_carrier round-trip" -body {
    set enc [::Salt::encode_carrier $salt_hex $dll_hash]
    set dec [::Salt::decode_carrier $enc $dll_hash]
    set wrong [::Salt::decode_carrier $enc $other_dll_hash]
    list [expr {$dec eq $salt_hex}] [expr {$wrong ne $salt_hex}]
} -result {1 1}

# --------------------------------------------------------------------------
# Test 5: encode_carrier refuses invalid salt
# --------------------------------------------------------------------------
test salt-carrier-invalid "encode_carrier rejects non-hex salt" -body {
    list [::Salt::encode_carrier "xyz" $dll_hash] [::Salt::encode_carrier "" $dll_hash]
} -result {{} {}}

# --------------------------------------------------------------------------
# Test 6: carrier file write/read round-trip
# --------------------------------------------------------------------------
test salt-carrier-file "carrier_write + carrier_read round-trip" -body {
    cleanup_salt_state
    set path [::Salt::carrier_write $salt_hex $dll_hash]
    set payload [::Salt::carrier_read]
    set ok [expr {$path ne "" && [file exists $path]}]
    file delete -force $path
    list $ok [expr {$payload eq [::Salt::encode_carrier $salt_hex $dll_hash]}]
} -result {1 1}

# --------------------------------------------------------------------------
# Test 7: carrier_read ignores comments and blank lines
# --------------------------------------------------------------------------
test salt-carrier-comments "carrier_read skips comments/blank lines" -body {
    cleanup_salt_state
    set path [::Salt::carrier_path]
    set fh [open $path w]
    puts $fh "# comment line"
    puts $fh ""
    puts $fh "carrier1 aabbcc"
    close $fh
    set payload [::Salt::carrier_read]
    file delete -force $path
    set payload
} -result "aabbcc"

# --------------------------------------------------------------------------
# Test 8: resolve picks the environment variable first
# --------------------------------------------------------------------------
test salt-resolve-env "env INI2MAP_SALT wins" -body {
    cleanup_salt_state
    set ::env(INI2MAP_SALT) "DEADBEEF"
    set v [::Salt::resolve $dll_hash $salt_hex]
    unset ::env(INI2MAP_SALT)
    list [string tolower $v] $::Salt::source
} -result {deadbeef env}

# --------------------------------------------------------------------------
# Test 9: resolve falls back to legacy when env is not valid hex
# --------------------------------------------------------------------------
test salt-resolve-bad-env "invalid env falls through to legacy" -body {
    cleanup_salt_state
    set ::env(INI2MAP_SALT) "not-a-hex-value"
    set v [::Salt::resolve $dll_hash $salt_hex]
    unset ::env(INI2MAP_SALT)
    list [expr {$v eq $salt_hex}] $::Salt::source
} -result {1 settings.cfg}

# --------------------------------------------------------------------------
# Test 10: resolve reads the registry
# --------------------------------------------------------------------------
test salt-resolve-registry "registry salt is used when present" -body {
    cleanup_salt_state
    ::Salt::write_registry $salt_hex
    set v [::Salt::resolve $dll_hash $salt_hex]
    list [expr {$v eq $salt_hex}] $::Salt::source
} -result {1 registry}

# --------------------------------------------------------------------------
# Test 11: carrier import (lazy): registry empty -> carrier imported, file deleted
# --------------------------------------------------------------------------
test salt-resolve-carrier-import "empty registry imports and deletes carrier" -body {
    cleanup_salt_state
    ::Salt::carrier_write $salt_hex $dll_hash
    set v [::Salt::resolve $dll_hash ""]
    set still_there [file exists [::Salt::carrier_path]]
    set in_registry [::Salt::read_registry]
    list [expr {$v eq $salt_hex}] $::Salt::source $still_there [expr {$in_registry eq $salt_hex}]
} -result {1 carrier 0 1}

# --------------------------------------------------------------------------
# Test 12: conflict policy: registry wins, carrier is kept but ignored
# --------------------------------------------------------------------------
test salt-resolve-conflict "registry salt wins over a different carrier salt" -body {
    cleanup_salt_state
    set other_salt "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
    ::Salt::write_registry $salt_hex
    ::Salt::carrier_write $other_salt $dll_hash
    set v [::Salt::resolve $dll_hash $other_salt]
    set carrier_kept [file exists [::Salt::carrier_path]]
    set still_reg [::Salt::read_registry]
    list [expr {$v eq $salt_hex}] $::Salt::source $carrier_kept [expr {$still_reg eq $salt_hex}]
} -result {1 registry 1 1}

# --------------------------------------------------------------------------
# Test 13: carrier matching the registry salt is deleted as redundant
# --------------------------------------------------------------------------
test salt-resolve-carrier-redundant "matching carrier file is removed" -body {
    cleanup_salt_state
    ::Salt::write_registry $salt_hex
    ::Salt::carrier_write $salt_hex $dll_hash
    ::Salt::resolve $dll_hash $salt_hex
    file exists [::Salt::carrier_path]
} -result 0

# --------------------------------------------------------------------------
# Test 14: no env, no registry, no carrier -> legacy settings.cfg value
# --------------------------------------------------------------------------
test salt-resolve-legacy "falls back to legacy settings.cfg salt" -body {
    cleanup_salt_state
    set v [::Salt::resolve $dll_hash $salt_hex]
    list [expr {$v eq $salt_hex}] $::Salt::source
} -result {1 settings.cfg}

# --------------------------------------------------------------------------
# Test 15: nothing at all -> empty salt, source "none"
# --------------------------------------------------------------------------
test salt-resolve-none "no salt anywhere yields empty string" -body {
    cleanup_salt_state
    set v [::Salt::resolve $dll_hash ""]
    list $v $::Salt::source
} -result {{} none}

# --------------------------------------------------------------------------
# Test 16: notices are queued (logproc not installed yet) and flushed later
# --------------------------------------------------------------------------
test salt-notice-queue "notice queues into pending before logproc exists" -body {
    cleanup_salt_state
    set ::Data::logproc ""
    ::Salt::notice "queued message"
    set qlen [llength $::Salt::pending]
    # flush with no logproc -> message must stay queued
    ::Salt::flush_pending
    set after_len [llength $::Salt::pending]
    set ::Salt::pending {}
    list $qlen $after_len
} -result {1 1}

# --------------------------------------------------------------------------
# Test 17: auto scope when running under tclsh (script mode) is "default"
# --------------------------------------------------------------------------
test salt-scope-auto "auto scope from interpreter name is default" -body {
    set ::Salt::scope ""
    set ::Salt::scope_explicit 0
    set s [::Salt::get_scope]
    set ::Salt::scope "unittest"
    set ::Salt::scope_explicit 1
    set s
} -result "default"

# --------------------------------------------------------------------------
# Test 18: explicit set_scope; path separators are sanitized
# --------------------------------------------------------------------------
test salt-scope-set "set_scope sanitizes registry path separators" -body {
    cleanup_salt_state
    ::Salt::set_scope "mod\\sub/dir"
    set s [::Salt::get_scope]
    set p [::Salt::reg_path]
    cleanup_salt_state
    list $s [string match "*\\mod_sub_dir" $p]
} -result {mod_sub_dir 1}

# --------------------------------------------------------------------------
# Test 19: scopes are isolated - each build keeps its own salt
# --------------------------------------------------------------------------
test salt-scope-isolation "different scopes keep independent registry salts" -body {
    cleanup_salt_state
    set salt_b "22223333444455556666777788889999aaaabbbbccccddddeeee0000111122223333"
    ::Salt::write_registry $salt_hex
    ::Salt::set_scope "otherscope"
    # other scope has no value yet
    set empty [::Salt::read_registry]
    ::Salt::write_registry $salt_b
    set vb [::Salt::read_registry]
    ::Salt::set_scope "unittest"
    set va [::Salt::read_registry]
    # remove the scratch "otherscope" key
    catch {registry delete [::Salt::reg_path] $::Salt::reg_value}
    cleanup_salt_state
    list [expr {$empty eq ""}] [expr {$va eq $salt_hex}] [expr {$vb eq $salt_b}]
} -result {1 1 1}

# --------------------------------------------------------------------------
# Test 20: carrier payload only decodes in the scope it was created for
# --------------------------------------------------------------------------
test salt-carrier-scope-binding "carrier is bound to its scope" -body {
    cleanup_salt_state
    set payload [::Salt::encode_carrier $salt_hex $dll_hash]
    ::Salt::set_scope "otherscope"
    set dec [::Salt::decode_carrier $payload $dll_hash]
    cleanup_salt_state
    expr {$dec ne $salt_hex}
} -result 1

# --------------------------------------------------------------------------
# Test 21: Config::load applies salt_scope and resolves through ::Salt
# --------------------------------------------------------------------------
test salt-config-integration "Config::load applies salt_scope and resolves" -body {
    cleanup_salt_state
    namespace eval ::CLI {
        variable cfg_file ""
        variable cmd_gamemode ""
        variable cmd_no_log_open 0
        variable cmd_quiet 1
    }
    set ::app_dir $test_tmpdir
    source [file join $script_dir config.tcl]
    set tmpcfg [file join $test_tmpdir "_salt_scope_settings.cfg"]
    set fh [open $tmpcfg w]
    puts $fh "return \[dict create v2_salt $salt_hex salt_scope cfgscope crypto_dll_expected_hash $dll_hash\]"
    close $fh
    set ::CLI::cfg_file $tmpcfg
    ::Config::load
    file delete -force $tmpcfg
    list [::Salt::get_scope] [expr {$::Config::v2_salt eq $salt_hex}] $::Salt::source
} -result {cfgscope 1 settings.cfg}

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
cleanup_salt_state
cleanupTests
