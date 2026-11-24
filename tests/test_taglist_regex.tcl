# test_taglist_regex.tcl - TagList whitelist configs: literal tags, regex entries and game modes
#
# Covers the config format produced by third_party\tag_reference\generate_tags.ps1:
#   * literal entries -> 1 (exact) / 2 (case differs) / 3 (unknown)
#   * entries starting with ^ are regular expressions for dynamic tag names
#   * phobos mode = tags-ares.cfg + tags-phobos.cfg supplement

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file normalize [info script]]]
set map_dir    [file normalize [file join $script_dir ".."]]

namespace eval ::Data { variable gamemode "ares" }
set ::app_dir $map_dir
source [file join $map_dir "taglist" "taglist.tcl"]

# Load the whitelists from a scratch dir: the project's tags-ext.cfg is filled
# by real validation runs, which would make the "unknown tag" cases below pass
# (or fail) depending on what was validated before the suite.
set cfg_dir [file join $map_dir "test_taglist_tmp_cfg"]
file delete -force $cfg_dir
file mkdir $cfg_dir
foreach cfg {tags-ra2.cfg tags-yr.cfg tags-ares.cfg tags-phobos.cfg} {
    file copy -force [file join $map_dir $cfg] [file join $cfg_dir $cfg]
}
set ::TagList::taglist_dir $cfg_dir

proc reload_tags {mode} {
    set ::Data::gamemode $mode
    set ::TagList::loaded 0
    ::TagList::init
}

reload_tags "ares"

test taglist-literal-exact "known literal tag matches exactly" -body {
    ::TagList::check_tag "Armor" "BuildingTypes"
} -result 1

test taglist-literal-case "literal tag with different case is flagged" -body {
    ::TagList::check_tag "armor" "BuildingTypes"
} -result 2

test taglist-unknown-literal "unknown literal tag is rejected" -body {
    ::TagList::check_tag "NoSuchTagEver" "BuildingTypes"
} -result 3

test taglist-unknown-section "unknown category is rejected" -body {
    ::TagList::check_tag "Armor" "NotACategory"
} -result 3

test taglist-regex-paradrop "dynamic ParaDrop tag with .Plane<N> matches" -body {
    ::TagList::check_tag "ParaDrop.GDI.Plane2.Aircraft" "SuperWeaponTypes"
} -result 1

test taglist-regex-paradrop-plain "dynamic ParaDrop tag without .Plane<N> matches" -body {
    ::TagList::check_tag "ParaDrop.Allied.Count" "SuperWeaponTypes"
} -result 1

test taglist-regex-paradrop-case "dynamic ParaDrop tag in wrong case is flagged" -body {
    ::TagList::check_tag "paradrop.GDI.Plane2.Aircraft" "SuperWeaponTypes"
} -result 2

test taglist-regex-paradrop-scope "ParaDrop pattern does not leak into other sections" -body {
    ::TagList::check_tag "ParaDrop.GDI.Plane2.Aircraft" "BuildingTypes"
} -result 3

test taglist-regex-prereq "Prerequisite.List<N> matches in every type section" -body {
    list [::TagList::check_tag "Prerequisite.List1" "BuildingTypes"] \
         [::TagList::check_tag "Prerequisite.List7" "InfantryTypes"] \
         [::TagList::check_tag "Prerequisite.List0" "BuildingTypes"]
} -result {1 1 3}

test taglist-regex-versus "Versus.<armor> and its sub-tags match" -body {
    list [::TagList::check_tag "Versus.Wood" "Warheads"] \
         [::TagList::check_tag "Versus.Wood.ForceFire" "Warheads"] \
         [::TagList::check_tag "Versus" "Warheads"]
} -result {1 1 3}

test taglist-regex-bad-index "an out-of-range dynamic index does not match" -body {
    ::TagList::check_tag "ParaDrop.GDI.PlaneX.Aircraft" "SuperWeaponTypes"
} -result 3

test taglist-phobos-supplement "phobos mode adds the Phobos-only tags" -body {
    reload_tags "phobos"
    set result [list [::TagList::check_tag "HealthBar.Hide" "BuildingTypes"] \
                     [::TagList::check_tag "Convert.Deploy" "InfantryTypes"] \
                     [::TagList::check_tag "ParaDrop.GDI.Plane2.Aircraft" "SuperWeaponTypes"]]
    reload_tags "ares"
    set result
} -result {1 1 1}

test taglist-ares-has-no-phobos-tags "ares mode does not accept Phobos-only tags" -body {
    reload_tags "ares"
    list [::TagList::check_tag "HealthBar.Hide" "BuildingTypes"] \
         [::TagList::check_tag "IsGattling" "InfantryTypes"]
} -result {3 3}

test taglist-ra2-is-strict "ra2 mode accepts only RA2 tags" -body {
    reload_tags "ra2"
    set result [list [::TagList::check_tag "Armor" "BuildingTypes"] \
                     [::TagList::check_tag "Prerequisite.List1" "BuildingTypes"]]
    reload_tags "ares"
    set result
} -result {1 3}

# --- config parsing in isolation ---------------------------------------------
set tmp_dir [file join $map_dir "test_taglist_tmp"]
file delete -force $tmp_dir
file mkdir $tmp_dir

set fh [open [file join $tmp_dir "base.cfg"] w]
fconfigure $fh -encoding utf-8 -translation lf
puts $fh "; comment line"
puts $fh ""
puts $fh {[BuildingTypes]}
puts $fh "AlphaTag"
puts $fh {[Warheads]}
puts $fh {^Versus\.(Alpha|Beta)$}
close $fh

set fh [open [file join $tmp_dir "extra.cfg"] w]
fconfigure $fh -encoding utf-8 -translation lf
puts $fh {[BuildingTypes]}
puts $fh "BetaTag"
puts $fh {[Warheads]}
puts $fh {^Gamma\.[0-9]+$}
close $fh

test taglist-load-regex-entry "a ^-line is stored as a pattern, not as a literal tag" -body {
    set ::TagList::loaded 0
    ::TagList::_load_config [file join $tmp_dir "base.cfg"]
    set patterns [dict get $::TagList::regex_dict "Warheads"]
    list [expr {[lsearch -exact $patterns "^Versus\\.(Alpha|Beta)$"] >= 0}] \
         [::TagList::check_tag "Versus.Alpha" "Warheads"] \
         [::TagList::check_tag "versus.BETA" "Warheads"] \
         [::TagList::check_tag "Versus.Gamma" "Warheads"] \
         [::TagList::check_tag "AlphaTag" "BuildingTypes"] \
         [::TagList::check_tag "^Versus\\.Alpha$" "Warheads"]
} -result {1 1 2 3 1 3}

test taglist-load-merge "merge=1 keeps the previously loaded config" -body {
    ::TagList::_load_config [file join $tmp_dir "extra.cfg"] 1
    list [::TagList::check_tag "AlphaTag" "BuildingTypes"] \
         [::TagList::check_tag "BetaTag" "BuildingTypes"] \
         [::TagList::check_tag "Gamma.42" "Warheads"]
} -result {1 1 1}

test taglist-load-reset "merge=0 drops the previous config" -body {
    ::TagList::_load_config [file join $tmp_dir "extra.cfg"]
    list [::TagList::check_tag "AlphaTag" "BuildingTypes"] \
         [::TagList::check_tag "BetaTag" "BuildingTypes"]
} -result {3 1}

test taglist-load-missing "a missing config resets the whitelist and warns" -body {
    ::TagList::_load_config [file join $tmp_dir "no_such_file.cfg"]
    ::TagList::check_tag "AlphaTag" "BuildingTypes"
} -result 3

file delete -force $tmp_dir

# leave the module in a sane state for anything sourced after this file
reload_tags "ares"
set ::TagList::taglist_dir $::app_dir
file delete -force $cfg_dir

cleanupTests
