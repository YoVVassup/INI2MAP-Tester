# checks/taskforce_duplicates.tcl
# Validates that no TaskForce contains the same unit type more than once
# Game modes: RA2/YR/Ares/Phobos
# Uses: None (reads rawmapdata directly)
#
# References:
#   https://modenc.renegadeprojects.com/TaskForces
#
# Bugs:
#   Duplicate unit types in a TaskForce cause the later group to be silently dropped.
#   If the duplicate is the last entry, it triggers Internal Error:
#     YR:  EIP#0065D99F (lost pointer)
#     TS:  EIP#005BF525 (lost pointer)

proc ::Checks::validate_taskforce_duplicates {} {
    upvar ::Data::taskforces taskforces
    upvar ::Data::rawmapdata rawmapdata

    if {![info exists taskforces]} return

    foreach tf_id [array names taskforces] {
        if {![info exists rawmapdata($tf_id)]} continue

        set tf_name ""
        array set unit_types {}

        foreach curline $rawmapdata($tf_id) {
            set eq [string first "=" $curline]
            if {$eq == -1} continue
            set key [string trim [string range $curline 0 [expr {$eq - 1}]]]
            set val [string trim [string range $curline [expr {$eq + 1}] end]]

            if {$key eq "Name"} {
                set tf_name $val
                continue
            }
            if {$key eq "Group"} continue

            # Entry format: Index=Count,UnitType
            set fields [split $val ","]
            if {[llength $fields] < 2} continue

            set unit_type [string trim [lindex $fields 1]]
            if {$unit_type eq ""} continue

            if {[info exists unit_types($unit_type)]} {
                ::Logging::error "TaskForce \"$tf_id\" (\"$tf_name\") contains duplicate unit type \"$unit_type\". This will cause the later group to be dropped and may trigger an Internal Error (EIP#0065D99F in YR, EIP#005BF525 in TS) if it is the last entry."
            }
            set unit_types($unit_type) 1
        }

        array unset unit_types
    }
}

# Register this check
::Checks::register_check "validate_taskforce_duplicates"
