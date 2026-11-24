# checks/secret_lab_bonus_count.tcl
# Validates Secret Lab bonus count vs placed labs
# Game modes: RA2/YR (vanilla only — fixed in Ares 0.1)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Secret_Lab_System
# Bug: If you place more labs on the map than there are choices for bonuses,
#      none of the labs will give any bonuses at all.
# Fixed in Ares 0.1.
#
# Bonus pool is built from three lists in [General]:
#   - SecretInfantry
#   - SecretUnits
#   - SecretBuildings

proc ::Checks::validate_secret_lab_bonus_count {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::buildings buildings
    upvar ::Data::rawmapdata rawmapdata
    upvar ::Data::rulesdata rulesdata

    # Only check in vanilla modes (bug fixed in Ares)
    set is_ares [expr {$gamemode eq "ares" || $gamemode eq "phobos"}]
    if {$is_ares} return

    if {![info exists buildings]} return

    # Count Secret Lab buildings on the map
    set lab_count 0
    if {[info exists rawmapdata(Structures)]} {
        foreach line $rawmapdata(Structures) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set val [string trim [string range $line [expr {$eq+1}] end]]
            if {$val eq ""} continue

            # Check if this structure type has SecretLab=yes
            if {[::Checks::is_true [::Checks::get_cached_property $val "SecretLab"]]} {
                incr lab_count
            }
        }
    }

    if {$lab_count == 0} return

    # Count available bonuses from [General] section
    # Pool is built from: SecretInfantry, SecretUnits, SecretBuildings
    set bonus_count 0

    foreach key {SecretInfantry SecretUnits SecretBuildings} {
        set val [::Checks::get_cached_property "General" $key]
        if {$val ne "" && $val ne "none"} {
            # Value can be comma-separated list
            foreach item [split $val ","] {
                set item [string trim $item]
                if {$item ne ""} {
                    incr bonus_count
                }
            }
        }
    }

    if {$bonus_count == 0} return

    # Warn if more labs than bonuses
    if {$lab_count > $bonus_count} {
        ::Logging::warning "Map has $lab_count Secret Labs but only $bonus_count bonus options (SecretInfantry + SecretUnits + SecretBuildings in \[General\]). In vanilla RA2/YR, labs beyond the bonus count will give NO bonuses at all. Add more bonuses or reduce lab count."
    }
}

# Register this check
::Checks::register_check "validate_secret_lab_bonus_count"
