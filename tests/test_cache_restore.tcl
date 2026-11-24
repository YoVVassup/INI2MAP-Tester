#----------------------------------------------------------------------------------------------------------
# test_cache_restore.tcl - Batch cache regression: everything saved by
# ::RulesCache::save must survive the batch pre-map clear that main.tcl:239-250
# performs (array unset of ALL ::Data arrays + scalar resets).
# Repro for the original bug: "can't read ::Data::armortypes(flak)" on map 2+.
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file normalize [info script]]]
set map_dir    [file dirname $script_dir]

namespace eval ::Data {}
source [file join $map_dir "cache.tcl"]

# --- simulate state produced by ::Rules::load_all (pre-load snapshot) ----------
array set ::Data::armortypes     {flak "flakgrenade"}
array set ::Data::attacheffects  {0 "PUREEFFECT"}
array set ::Data::radiationtypes {0 "TESTRAD"}
array set ::Data::shieldtypes    {0 "TESTSHIELD"}
array set ::Data::ai_defs        {E1 1}
array set ::Data::teamtypes      {TT1 ""}
array set ::Data::taskforces     {TF1 ""}
array set ::Data::scripts        {S1 ""}
array set ::Data::infantry       {E1 ""}
set ::Data::armortypes_order {flak}
set ::Data::countrycnt 5

::RulesCache::save

# --- mimic main.tcl:239-250 batch clear ----------------------------------------
foreach arrName [info vars ::Data::*] {
    if {[array exists $arrName]} { catch {array unset $arrName} }
}
foreach varName {mapunits sound_defaults maperr animlog started rules_loaded theme} {
    catch {set ::Data::$varName {}}
}
foreach varName {mismap newini mhouses ignoreglobals maspect} {
    catch {set ::Data::$varName 0}
}
set ::Data::rules_loaded 0

::RulesCache::restore

proc array_has {arr key} {
    expr {[array exists $arr] && [info exists ${arr}($key)]}
}

test cache-restore.1 "armortypes restored after batch clear" -body {
    list [array_has ::Data::armortypes flak] $::Data::armortypes(flak)
} -result {1 flakgrenade}

test cache-restore.2 "armortypes_order (scalar) restored" -body {
    expr {$::Data::armortypes_order eq "flak"}
} -result 1

test cache-restore.3 "attacheffects restored" -body {
    list [array_has ::Data::attacheffects 0] $::Data::attacheffects(0)
} -result {1 PUREEFFECT}

test cache-restore.4 "radiationtypes restored" -body {
    list [array_has ::Data::radiationtypes 0] $::Data::radiationtypes(0)
} -result {1 TESTRAD}

test cache-restore.5 "shieldtypes restored" -body {
    list [array_has ::Data::shieldtypes 0] $::Data::shieldtypes(0)
} -result {1 TESTSHIELD}

test cache-restore.6 "ai_defs restored" -body {
    array_has ::Data::ai_defs E1
} -result 1

test cache-restore.7 "teamtypes restored" -body {
    array_has ::Data::teamtypes TT1
} -result 1

test cache-restore.8 "taskforces restored" -body {
    array_has ::Data::taskforces TF1
} -result 1

test cache-restore.9 "scripts restored" -body {
    array_has ::Data::scripts S1
} -result 1

test cache-restore.10 "previously cached arrays still restored" -body {
    list [array_has ::Data::infantry E1] $::Data::countrycnt $::Data::rules_loaded
} -result {1 5 1}

cleanupTests
