#----------------------------------------------------------------------------------------------------------
# salt.tcl - V2 salt storage: HKCU registry + obfuscated carrier file (INI2MAP Tester)
#----------------------------------------------------------------------------------------------------------
# Every tester build variant (MOMT / RA2MT / RA2YRMT, and future mod ports) may
# carry its own salt, so the registry value is scoped per build:
#   HKCU\Software\INI2MAP Tester\<scope>  (value v2_salt)
#
# Scope resolution:
#   1. salt_scope from settings.cfg (explicit, ships with each variant)
#   2. running starpack exe name, lowercased (MOMT.exe -> momt, ...)
#   3. "default" (script mode / tclsh)
#
# Salt resolution order (first match wins):
#   1. env INI2MAP_SALT (overrides everything, applies to the current run only)
#   2. registry value of the current scope
#   3. settings.local.cfg carrier - obfuscated, imported into the registry on
#      first use, then the file is deleted
#   4. v2_salt from settings.cfg (legacy fallback)
# CLI --salt is parsed in cli.tcl and overrides everything above (applied in main.tcl).
#
# Carrier format (obfuscation, NOT encryption):
#   carrier1 <hex>    hex = v2_salt XOR sha256(dll_hash || scope || "ini2map-carrier")
# The XOR key is derived from the configured DLL hash (crypto_dll_expected_hash
# in settings.cfg) plus the scope, so a carrier shipped for one variant does not
# decode in another - it only shields the salt from a casual look, it is not a
# secret store and does not survive without settings.cfg.
#
# HKDF v2 derivation is one-way: losing the salt loses access to every .enc
# file. Back up ALL scopes of the current user with:
#   reg export "HKEY_CURRENT_USER\Software\INI2MAP Tester" salt-backup.reg /y
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Salt::loaded]} { return }
namespace eval ::Salt {
    variable loaded 1
    # Test hooks: override to point at a scratch registry base key / temp file.
    variable reg_base {HKEY_CURRENT_USER\Software\INI2MAP Tester}
    variable reg_value "v2_salt"
    variable carrier_file "settings.local.cfg"
    # Salt scope: which tester build owns this salt (see header for resolution).
    variable scope ""
    variable scope_explicit 0
    variable source ""
    variable pending {}
    variable here [file dirname [file normalize [info script]]]
}

# --- Set the scope explicitly (salt_scope from settings.cfg; "" = keep auto) ---
proc ::Salt::set_scope {s} {
    variable scope
    variable scope_explicit
    set s [string trim $s]
    if {$s eq ""} { return }
    # Scope becomes a registry path segment - no separators allowed
    set s [string map [list "\\" "_" "/" "_"] $s]
    set scope $s
    set scope_explicit 1
}

# --- Current scope: explicit setting > starpack exe name > "default" ---
proc ::Salt::get_scope {} {
    variable scope
    variable scope_explicit
    if {$scope_explicit} { return $scope }
    set exe [file rootname [file tail [info nameofexecutable]]]
    if {[regexp -nocase {^(tclsh|wish|base)} $exe]} { return "default" }
    return [string tolower $exe]
}

# --- Full registry key for the current scope ---
proc ::Salt::reg_path {} {
    variable reg_base
    set scope [::Salt::get_scope]
    if {$scope eq ""} { return $reg_base }
    return "$reg_base\\$scope"
}

# --- Hex sanity: even-length hex string, non-empty ---
proc ::Salt::_hex {s} {
    expr {$s ne "" && [string length $s] % 2 == 0 && [regexp {^[0-9a-fA-F]+$} $s]}
}

# --- SHA-256 (package is preloaded by main.tcl; lazy-load for standalone tools) ---
proc ::Salt::_sha {str} {
    if {![llength [info commands ::sha2::sha256]]} {
        if {[catch {package require sha256}]} {
            variable here
            catch {source [file join $here "others" "sha256" "sha256.tcl"]}
            if {![llength [info commands ::sha2::sha256]]} { return "" }
        }
    }
    return [string tolower [::sha2::sha256 -hex $str]]
}

# --------------------------------------------------------------------------
# Registry access (Windows: registry package ships with tclsh86 / tclkit)
# --------------------------------------------------------------------------
proc ::Salt::read_registry {} {
    variable reg_value
    if {[catch {package require registry}]} { return "" }
    set key [::Salt::reg_path]
    if {[catch {set v [registry get $key $reg_value]}]} { return "" }
    set v [string trim $v]
    if {![::Salt::_hex $v]} { return "" }
    return [string tolower $v]
}

proc ::Salt::write_registry {hex} {
    variable reg_base
    variable reg_value
    if {[catch {package require registry}]} { return 0 }
    set key [::Salt::reg_path]
    # Make sure the base key exists (registry set only creates the leaf)
    if {$key ne $reg_base} { catch {registry set $reg_base} }
    if {[catch {registry set $key $reg_value $hex}]} { return 0 }
    return 1
}

proc ::Salt::delete_registry {} {
    variable reg_value
    if {[catch {package require registry}]} { return 0 }
    set key [::Salt::reg_path]
    if {[catch {registry delete $key $reg_value}]} { return 0 }
    return 1
}

# --------------------------------------------------------------------------
# Obfuscation XOR: hex string, key repeats over the payload (byte aligned)
# --------------------------------------------------------------------------
proc ::Salt::xor_hex {data_hex key_hex} {
    if {![::Salt::_hex $data_hex] || ![::Salt::_hex $key_hex]} { return "" }
    set klen [string length $key_hex]
    set dlen [string length $data_hex]
    set out ""
    for {set i 0} {$i < $dlen} {incr i 2} {
        set kidx [expr {$i % $klen}]
        scan [string range $data_hex $i [expr {$i + 1}]] %x dv
        scan [string range $key_hex $kidx [expr {$kidx + 1}]] %x kv
        append out [format %02x [expr {$dv ^ $kv}]]
    }
    return $out
}

proc ::Salt::carrier_key {dll_hash} {
    return [::Salt::_sha "${dll_hash}[::Salt::get_scope]ini2map-carrier"]
}

proc ::Salt::encode_carrier {salt_hex dll_hash} {
    set key [::Salt::carrier_key $dll_hash]
    if {$key eq ""} { return "" }
    return [::Salt::xor_hex $salt_hex $key]
}

proc ::Salt::decode_carrier {payload_hex dll_hash} {
    set key [::Salt::carrier_key $dll_hash]
    if {$key eq ""} { return "" }
    set s [::Salt::xor_hex $payload_hex $key]
    if {![::Salt::_hex $s]} { return "" }
    return [string tolower $s]
}

# --------------------------------------------------------------------------
# Carrier file path / IO
# Absolute carrier_file (test hook) wins; otherwise it lives in ::app_dir.
# --------------------------------------------------------------------------
proc ::Salt::carrier_path {} {
    variable carrier_file
    if {[file pathtype $carrier_file] eq "absolute"} { return $carrier_file }
    set base "."
    if {[info exists ::app_dir]} { set base $::app_dir }
    return [file join $base $carrier_file]
}

# Returns the obfuscated payload hex ("" when absent/unreadable/not v1 format)
proc ::Salt::carrier_read {} {
    set path [::Salt::carrier_path]
    if {![file exists $path]} { return "" }
    if {[catch {set fh [open $path r]}]} { return "" }
    set payload ""
    if {![catch {
        while {[gets $fh line] >= 0} {
            set t [string trim $line]
            if {$t eq "" || [string index $t 0] eq "#"} continue
            if {[regexp {^carrier1\s+([0-9a-fA-F]+)\s*$} $t -> hex]} {
                set payload $hex
            }
            break
        }
    }]} {}
    catch {close $fh}
    return [string tolower $payload]
}

# Writes the carrier file, returns its path ("" on failure)
proc ::Salt::carrier_write {salt_hex dll_hash} {
    set path [::Salt::carrier_path]
    set payload [::Salt::encode_carrier $salt_hex $dll_hash]
    if {$payload eq ""} { return "" }
    # A previous build marks the carrier Hidden+System via attrib; such a file
    # cannot be reopened for writing, so remove it first.
    if {[file exists $path]} { catch {file delete -force $path} }
    if {[catch {set fh [open $path w]}]} { return "" }
    puts $fh "# INI2MAP Tester salt carrier (obfuscated, not encrypted)"
    puts $fh "# Imported into the user registry on the first run, then deleted."
    puts $fh "# scope: [::Salt::get_scope]"
    puts $fh "carrier1 $payload"
    catch {close $fh}
    return $path
}

# --------------------------------------------------------------------------
# Deferred notices: config load runs before ::Data::logproc is installed and
# before ::Data::maperr is reset, so messages are queued and flushed later
# from logwrite() (see logging.tcl).
# --------------------------------------------------------------------------
proc ::Salt::notice {msg} {
    variable pending
    lappend pending $msg
    if {[info exists ::Data::quiet_mode] && $::Data::quiet_mode} { return }
    puts "NOTICE -> $msg"
}

proc ::Salt::flush_pending {} {
    variable pending
    if {![llength $pending]} { return }
    if {![llength [info procs logputs]]} { return }
    if {![info exists ::Data::logproc] || $::Data::logproc eq ""} { return }
    set rest {}
    foreach m $pending {
        if {[catch {logputs "NOTICE -> $m"}]} { lappend rest $m }
    }
    set pending $rest
}

# --------------------------------------------------------------------------
# Carrier import / consistency checks (dll_hash = crypto_dll_expected_hash)
# --------------------------------------------------------------------------

# Registry already holds a salt: drop the carrier when it matches, warn when
# it carries a different one (ignored per policy).
proc ::Salt::_check_carrier {dll_hash reg_salt} {
    set payload [::Salt::carrier_read]
    if {$payload eq ""} { return }
    set salt [::Salt::decode_carrier $payload $dll_hash]
    if {$salt eq ""} {
        ::Salt::notice "settings.local.cfg carrier is not decodable (wrong DLL hash or tester scope?) - ignored"
        return
    }
    if {$salt eq $reg_salt} {
        # Same salt already in the registry: remove the redundant carrier.
        catch {file delete -force [::Salt::carrier_path]}
        return
    }
    ::Salt::notice "settings.local.cfg carries a different salt than the registry (scope [::Salt::get_scope]) - ignored"
}

# Registry is empty: import the carrier, then delete it.
# Returns the salt to use this run ("" = no carrier / not decodable).
proc ::Salt::_import_carrier {dll_hash} {
    variable source
    set payload [::Salt::carrier_read]
    if {$payload eq ""} { return "" }
    set salt [::Salt::decode_carrier $payload $dll_hash]
    if {$salt eq ""} {
        ::Salt::notice "settings.local.cfg carrier is not decodable (wrong DLL hash or tester scope?) - ignored"
        return ""
    }
    if {![::Salt::write_registry $salt]} {
        ::Salt::notice "Cannot write the salt to the registry - carrier kept for the next run"
        set source "carrier"
        return $salt
    }
    catch {file delete -force [::Salt::carrier_path]}
    ::Salt::notice "Salt imported from settings.local.cfg into the registry (scope [::Salt::get_scope], carrier file removed)"
    set source "carrier"
    return $salt
}

# --------------------------------------------------------------------------
# Resolve: env > registry > carrier > settings.cfg (legacy)
# dll_hash comes from crypto_dll_expected_hash, legacy from settings.cfg.
# Sets ::Salt::source to one of: env / registry / carrier / settings.cfg / none.
# --------------------------------------------------------------------------
proc ::Salt::resolve {dll_hash legacy} {
    variable source

    # 1. environment
    if {[info exists ::env(INI2MAP_SALT)] && [string trim $::env(INI2MAP_SALT)] ne ""} {
        set v [string trim $::env(INI2MAP_SALT)]
        if {[::Salt::_hex $v]} {
            set source "env"
            return [string tolower $v]
        }
        ::Salt::notice "INI2MAP_SALT is not a valid hex salt - ignored"
    }

    # 2. registry
    set reg [::Salt::read_registry]
    if {$reg ne ""} {
        ::Salt::_check_carrier $dll_hash $reg
        if {$legacy ne "" && $legacy ne $reg} {
            ::Salt::notice "Registry salt (scope [::Salt::get_scope]) differs from settings.cfg v2_salt (registry wins)"
        }
        set source "registry"
        return $reg
    }

    # 3. carrier (lazy import into the registry)
    set salt [::Salt::_import_carrier $dll_hash]
    if {$salt ne ""} { return $salt }

    # 4. legacy settings.cfg
    if {$legacy ne ""} {
        set source "settings.cfg"
        return $legacy
    }

    set source "none"
    return ""
}

# --------------------------------------------------------------------------
# Convenience for standalone tools (check_key / reencrypt_all / crypto_utils):
# resolve the salt using a settings.cfg file (scope + dll hash + legacy salt).
# --------------------------------------------------------------------------
proc ::Salt::resolve_from_cfg {cfg_path} {
    set cfg [dict create]
    if {[file exists $cfg_path]} { catch {set cfg [source $cfg_path]} }
    if {[catch {dict size $cfg}]} { set cfg [dict create] }
    set legacy ""
    catch {set legacy [dict get $cfg v2_salt]}
    set scope ""
    catch {set scope [dict get $cfg salt_scope]}
    set dllh ""
    catch {set dllh [dict get $cfg crypto_dll_expected_hash]}
    # scope_locked (set by explicit --scope) keeps the caller's scope.
    if {![info exists ::Salt::scope_locked] || !$::Salt::scope_locked} {
        ::Salt::set_scope $scope
    }
    return [::Salt::resolve $dllh $legacy]
}

# --------------------------------------------------------------------------
# --show-salt: print source, value and the backup command, then exit
# --------------------------------------------------------------------------
proc ::Salt::show {} {
    variable source

    set salt ""
    set src $source
    if {[info exists ::CLI::salt] && $::CLI::salt ne ""} {
        set salt $::CLI::salt
        set src "cli"
    } elseif {[info exists ::Config::v2_salt]} {
        set salt $::Config::v2_salt
    }

    if {$src eq ""} { set src "none" }
    puts "Salt scope:  [::Salt::get_scope]"
    puts "Salt source: $src"
    if {$salt eq ""} {
        puts "V2 salt: <not set>"
        puts "No salt available - .enc files cannot be decrypted."
        return
    }
    puts "V2 salt: $salt"
    if {$src eq "registry" || [::Salt::read_registry] ne ""} {
        puts ""
        puts "Back up the salts of this user (HKDF is one-way - losing them loses all .enc data):"
        puts "  reg export \"[::Salt::reg_path]\" salt-backup.reg /y"
        puts "All scopes at once:"
        puts "  reg export \"[set ::Salt::reg_base]\" salt-backup-all.reg /y"
    }
}
