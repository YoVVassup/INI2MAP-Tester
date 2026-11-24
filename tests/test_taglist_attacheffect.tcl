# test_taglist_attacheffect.tcl - Phobos [AttachEffectTypes] / [RadiationTypes]
#
# Covers the two registry sections added to the pipeline (workbook -> generator
# -> taglist config -> rules_parser -> owner map):
#   * rules_parser/load_rules.tcl stores them as index -> name registries
#     (same shape as [Warheads]);
#   * taglist.tcl knows them as categories, so [SomeEffect] sections are
#     checked against the AttachEffectTypes whitelist;
#   * a name shared with a TechnoType keeps the TechnoType as its owner.

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file normalize [info script]]]
set map_dir    [file normalize [file join $script_dir ".."]]

source [file join $map_dir "constants.tcl"]
source [file join $map_dir "utils.tcl"]
source [file join $map_dir "data.tcl"]
source [file join $map_dir "logging.tcl"]

namespace eval ::Data { variable gamemode "phobos" }
set ::Data::logproc ::Logging::logputs_impl
set ::app_dir $map_dir

namespace eval ::Rules { variable loaded 0 }
source [file join $map_dir "rules_parser" "core.tcl"]
source [file join $map_dir "rules_parser" "load_rules.tcl"]
source [file join $map_dir "taglist" "taglist.tcl"]

# Whitelists from a scratch dir: the project's tags-ext.cfg is filled by real
# validation runs, which would make "unknown tag" cases depend on history.
set cfg_dir [file join $map_dir "test_taglist_ae_tmp_cfg"]
file delete -force $cfg_dir
file mkdir $cfg_dir
foreach cfg {tags-ra2.cfg tags-yr.cfg tags-ares.cfg tags-phobos.cfg} {
    file copy -force [file join $map_dir $cfg] [file join $cfg_dir $cfg]
}
set ::TagList::taglist_dir $cfg_dir
set ::TagList::loaded 0
::TagList::init

proc reload_ae {mode} {
    set ::Data::gamemode $mode
    set ::TagList::loaded 0
    ::TagList::init
}

# --------------------------------------------------------------------------
# Registry parsing: _load_ini is stubbed so no crypto module is needed.
# --------------------------------------------------------------------------
set ::ae_fixture_ini {
[InfantryTypes]
0=E1
[VehicleTypes]
0=PCV
[AircraftTypes]
0=HELI
[BuildingTypes]
0=FACT
[Warheads]
0=TESTWRD
[Projectiles]
0=TESTPRL
[AttachEffectTypes]
0=PUREEFFECT
1=TESTEFFECT
[RadiationTypes]
0=TESTRAD
}

proc ::Rules::_load_ini {filepath} { return $::ae_fixture_ini }

test ae-parser-attacheffect "load_rules fills the AttachEffectTypes registry" -body {
    ::Rules::load_rules "fixture.ini"
    list [array size ::Data::attacheffects] \
         $::Data::attacheffects(0) \
         $::Data::attacheffects(1)
} -result {2 PUREEFFECT TESTEFFECT}

test ae-parser-radiation "load_rules fills the RadiationTypes registry" -body {
    list [array size ::Data::radiationtypes] $::Data::radiationtypes(0)
} -result {1 TESTRAD}

test ae-parser-reset "a second load clears the previous registries" -body {
    set ::ae_fixture_ini {[InfantryTypes]
0=E1
[VehicleTypes]
0=PCV
[BuildingTypes]
0=FACT
[AttachEffectTypes]
0=ONLYONE}
    ::Rules::load_rules "fixture.ini"
    list [array size ::Data::attacheffects] [array size ::Data::radiationtypes]
} -result {1 0}

# --------------------------------------------------------------------------
# Category wiring
# --------------------------------------------------------------------------
test ae-category-wired "both sections are taglist categories" -body {
    list [dict exists $::TagList::categories "AttachEffectTypes"] \
         [dict exists $::TagList::categories "RadiationTypes"] \
         [expr {[dict get $::TagList::categories "AttachEffectTypes"] eq "attacheffects"}] \
         [expr {[dict get $::TagList::categories "RadiationTypes"] eq "radiationtypes"}]
} -result {1 1 1 1}

# --------------------------------------------------------------------------
# Whitelist checks (phobos config = tags-ares.cfg + tags-phobos.cfg)
# --------------------------------------------------------------------------
test ae-whitelist-known "AttachEffectTypes keys from tags-phobos.cfg are accepted" -body {
    list [::TagList::check_tag "Duration" "AttachEffectTypes"] \
         [::TagList::check_tag "Cumulative.MaxCount" "AttachEffectTypes"] \
         [::TagList::check_tag "ReflectDamage.Warhead.Detonate" "AttachEffectTypes"]
} -result {1 1 1}

test ae-whitelist-unknown "unknown AttachEffectTypes keys are rejected" -body {
    list [::TagList::check_tag "NoSuchEffectKey" "AttachEffectTypes"] \
         [::TagList::check_tag "duration" "AttachEffectTypes"]
} -result {3 2}

test ae-whitelist-absent "Phobos-only category is unknown in ares mode" -body {
    reload_ae "ares"
    set result [::TagList::check_tag "Duration" "AttachEffectTypes"]
    reload_ae "phobos"
    set result
} -result 3

# --------------------------------------------------------------------------
# Owner map: registry index -> name, TechnoTypes keep priority on ties
# --------------------------------------------------------------------------
proc reset_ae_registries {} {
    foreach v {infantry vehicles aircraft buildings attacheffects radiationtypes} {
        catch {array unset ::Data::$v}
    }
    set ::TagList::owner_map_built 0
}

test ae-owner-effect "effect and radiation sections are owned by their registry" -body {
    reset_ae_registries
    set ::Data::attacheffects(0) "PUREEFFECT"
    set ::Data::radiationtypes(0) "TESTRAD"
    set ::Data::infantry(TESTEFFECT) ""
    list [::TagList::_section_owner "PureEffect"] \
         [::TagList::_section_owner "TestRad"]
} -result {AttachEffectTypes RadiationTypes}

test ae-owner-techno-wins "a name shared with a unit keeps the TechnoType owner" -body {
    reset_ae_registries
    set ::Data::infantry(TESTEFFECT) ""
    set ::Data::attacheffects(0) "TESTEFFECT"
    ::TagList::_section_owner "TESTEFFECT"
} -result "InfantryTypes"

test ae-owner-unknown "an undeclared section stays unowned" -body {
    reset_ae_registries
    ::TagList::_section_owner "NoSuchSectionEver"
} -result ""

reset_ae_registries

# leave the module in a sane state for anything sourced after this file
reload_ae "ares"
set ::TagList::taglist_dir $::app_dir
file delete -force $cfg_dir

cleanupTests
