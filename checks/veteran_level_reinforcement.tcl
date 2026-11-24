# checks/veteran_level_reinforcement.tcl
# Validates VeteranLevel usage on TeamTypes for reinforcement override bug
# Game modes: RA2/YR/Ares (fixed in Phobos DevBuild#49)
# Uses: None (reads rawmapdata directly)
#
# References:
#   https://modenc.renegadeprojects.com/VeteranLevel
#
# Bug (fixed in Phobos DevBuild#49):
#   Reinforcement-type map trigger actions forcibly use the level defined
#   by [TeamType]→VeteranLevel, regardless of whether the unit has
#   Trainable=yes. Units will always spawn at the specified level.

proc ::Checks::validate_veteran_level_reinforcement {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::teamtypes teamtypes
    upvar ::Data::rawmapdata rawmapdata

    # Fixed in Phobos
    if {$gamemode eq "phobos"} return

    if {![info exists teamtypes]} return

    foreach team_id [array names teamtypes] {
        if {![info exists rawmapdata($team_id)]} continue

        foreach curline $rawmapdata($team_id) {
            set eq [string first "=" $curline]
            if {$eq == -1} continue
            set key [string trim [string range $curline 0 [expr {$eq - 1}]]]
            set val [string trim [string range $curline [expr {$eq + 1}] end]]

            if {[string tolower $key] eq "veteranlevel" && $val ne "" && $val != 0} {
                ::Logging::notice "TeamType \"$team_id\" has VeteranLevel=$val. Reinforcement trigger actions will forcibly use this level, overriding any Trainable=yes setting on the units."
                break
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_veteran_level_reinforcement"
