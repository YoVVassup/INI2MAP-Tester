# checks/tubes_limit.tcl
# Validates that [Tubes] section does not exceed the 127-entry engine limit
# Game modes: RA2/YR/Ares/Phobos
# Uses: None (reads rawmapdata directly)
#
# References:
#   https://modenc.renegadeprojects.com/Tubes
#
# Bug:
#   The engine was not designed to support more than 127 entries in the
#   [Tubes] section (127/6 = ~21 typical tunnel constructs). Exceeding
#   that limit causes undefined behavior / crashes.

proc ::Checks::validate_tubes_limit {} {
    upvar ::Data::rawmapdata rawmapdata

    if {![info exists rawmapdata(Tubes)]} return

    set entry_count 0
    foreach line $rawmapdata(Tubes) {
        set eq [string first "=" $line]
        if {$eq == -1} continue
        set key [string trim [string range $line 0 [expr {$eq - 1}]]]
        if {$key eq "" || $key eq "count"} continue
        # Entries are indexed numerically (0, 1, 2, ...)
        if {[string is integer -strict $key]} {
            incr entry_count

            # B20: entry syntax (WAE MapLoader.ReadTubes):
            # Index=ENTER_X,ENTER_Y,FACING,EXIT_X,EXIT_Y,DIRECTIONS
            # coordinates >= 1, initial facing in -1..TubeDirection.Max (7)
            set value [string trim [string range $line [expr {$eq + 1}] end]]
            set parts [split $value ","]
            set bad 0
            if {[llength $parts] < 6} {
                set bad 1
            } else {
                foreach pi {0 1 3 4} {
                    set pv [lindex $parts $pi]
                    if {![string is integer -strict $pv] || $pv < 1} {
                        set bad 1
                        break
                    }
                }
                if {!$bad} {
                    set fac [lindex $parts 2]
                    if {![string is integer -strict $fac] || $fac < -1 || $fac > 7} {
                        set bad 1
                    }
                }
            }
            if {$bad} {
                ::Logging::warning "Invalid tube entry: $value"
            }
        }
    }

    if {$entry_count > 127} {
        ::Logging::error "\[Tubes\] has $entry_count entries. The engine limit is 127 (approximately 21 tunnel constructs at 6 entries each). Exceeding this limit causes crashes or undefined behavior."
    } elseif {$entry_count > 100} {
        ::Logging::warning "\[Tubes\] has $entry_count entries. Approaching the engine limit of 127. Each tunnel construct typically uses 6 entries (~21 constructs max)."
    }
}

# Register this check
::Checks::register_check "validate_tubes_limit"
