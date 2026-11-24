# test_taglist_section.tcl - Section-aware tag collection (::TagList::_section_owner)
#
# A type name can be listed in one category while the section carrying that
# name belongs to another one: Mental Omega lists VENOM in [Animations] and
# still defines the aircraft section [VENOM]. Such a section must be checked
# only against its owning category, never against the category that merely
# references the name.

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]

set ::app_dir $script_dir
source [file join $script_dir "taglist" "taglist.tcl"]

namespace eval ::Data { variable gamemode "ares" }
set ::Data::logproc ::Logging::logputs_impl

# Run inside a scratch taglist dir so validate_all never touches the
# project's tags-ext.cfg (it appends every unknown tag there).
set tmp_dir [file join $script_dir "tests" "_tmp_section"]
file delete -force $tmp_dir
file mkdir $tmp_dir
file copy -force [file join $script_dir "tags-ares.cfg"] [file join $tmp_dir "tags-ares.cfg"]
set ::TagList::taglist_dir $tmp_dir

proc read_file {path} {
    if {![file exists $path]} { return "" }
    set fh [open $path r]
    set content [read $fh]
    close $fh
    set content
}

proc clear_array {name} {
    catch {array unset ::Data::$name}
    if {![info exists ::Data::$name] || ![array exists ::Data::$name]} {
        set ::Data::${name}(__dummy__) 1
        unset ::Data::${name}(__dummy__)
    }
}

proc reset_fixtures {} {
    foreach v {infantry vehicles aircraft buildings anims weapons warheads \
               projectiles superweapons particles particlesys vanims \
               attacheffects radiationtypes shieldtypes \
               rulesdata rawmapdata} {
        clear_array $v
    }
    set ::Data::maperr {}
    ::Logging::reset_counts
    file delete -force [file join $::TagList::taglist_dir "tags-ext.cfg"]
    set ::TagList::loaded 0
    set ::TagList::owner_map_built 0
}

proc run_validation {} {
    ::TagList::validate_all
    set ::Data::maperr
}

proc has_message {pattern} {
    expr {[lsearch -glob $::Data::maperr $pattern] >= 0}
}

# ---------------------------------------------------------------------------
# Fixtures: VENOM is an aircraft section and an [Animations] reference at the
# same time, ANIMY is an animation only.
# ---------------------------------------------------------------------------
proc setup_collision {} {
    reset_fixtures
    set ::Data::aircraft(VENOM) ""
    set ::Data::anims(VENOM) ""
    set ::Data::rulesdata(VENOM) {UIName=NAME:VENOM BogusAircraftTag=1}

    set ::Data::anims(ANIMY) ""
    set ::Data::rulesdata(ANIMY) {LoopEnd=10 NoSuchAnimTag=1}
}

setup_collision
run_validation

test section-owner-collision-skip "unit section is not checked as an animation" -body {
    list [has_message "NOTICE -> VENOM Unknown tag: UIName (not in Animations)"] \
         [has_message "NOTICE -> VENOM Unknown tag: BogusAircraftTag (not in Animations)"]
} -result {0 0}

test section-owner-collision-checked "the same section is still checked as an aircraft" -body {
    has_message "NOTICE -> VENOM Unknown tag: BogusAircraftTag (not in AircraftTypes)"
} -result 1

test section-owner-animation-checked "animation-only names keep their own whitelist" -body {
    list [has_message "NOTICE -> ANIMY Unknown tag: NoSuchAnimTag (not in Animations)"] \
         [has_message "NOTICE -> ANIMY Unknown tag: LoopEnd (not in Animations)"]
} -result {1 0}

test section-owner-lookup "owner lookup reports the owning category" -body {
    list [::TagList::_section_owner "VENOM"] \
         [::TagList::_section_owner "venom"] \
         [::TagList::_section_owner "ANIMY"] \
         [::TagList::_section_owner "NoSuchTypeName"]
} -result {AircraftTypes AircraftTypes Animations {}}

test section-owner-rebuilt "the owner map follows a registry change" -body {
    setup_collision
    set before [::TagList::_section_owner "VENOM"]
    clear_array aircraft
    set ::TagList::owner_map_built 0
    set after [::TagList::_section_owner "VENOM"]
    list $before $after
} -result {AircraftTypes Animations}

test section-owner-no-ext-leak "unknown tags are not written to project tags-ext.cfg (audit mode default)" -body {
    set project_ext [file join $script_dir "tags-ext.cfg"]
    set before [read_file $project_ext]

    reset_fixtures
    set ::Data::aircraft(VENOM) ""
    set ::Data::rulesdata(VENOM) {BogusTagOnlyInScratch=1}
    run_validation

    # Audit mode (default): unknown tags are logged but NOT written to tags-ext.cfg
    set scratch_has [expr {[string match "*BogusTagOnlyInScratch*" \
        [read_file [file join $tmp_dir "tags-ext.cfg"]]] ? 1 : 0}]
    set project_untouched [expr {$before eq [read_file $project_ext]}]
    list $scratch_has $project_untouched
} -result {0 1}

test section-owner-write-mode "validate_all 0 writes unknown tags to tags-ext.cfg" -body {
    reset_fixtures
    file delete -force [file join $::TagList::taglist_dir "tags-ext.cfg"]
    set ::Data::aircraft(VENOM) ""
    set ::Data::rulesdata(VENOM) {BogusTagForWriteMode=1}
    ::TagList::validate_all 0
    expr {[string match "*BogusTagForWriteMode*" \
        [read_file [file join $tmp_dir "tags-ext.cfg"]]] ? 1 : 0}
} -result 1

file delete -force $tmp_dir

cleanupTests
