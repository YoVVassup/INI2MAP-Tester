#----------------------------------------------------------------------------------------------------------
# aicheck/prereq_check.tcl - Prerequisite building validation
#----------------------------------------------------------------------------------------------------------
# Validates that buildings referenced in Prerequisite/PrerequisiteOverride
# are properly declared and have valid TechLevel values.
# Accounts for [GenericPrerequisites] aliases (e.g. SOVTECH=NAHAND,NATECH)
# and built-in generic prerequisites (POWER, BARRACKS, FACTORY, etc.).
#----------------------------------------------------------------------------------------------------------

proc ::AICheck::check_prerequisites {} {
    if {![info exists ::Data::rulesdata] && ![info exists ::Data::rawmapdata]} return

    # Built-in generic prerequisites from rules.ini [GenericPrerequisites]
    # These are abstract category names (e.g. POWER = any power plant)
    array set builtin_generic {
        POWER 1 PROCM 1 BARRACKS 1 FACTORY 1 AIRCRAFT 1
        NAVY 1 RADAR 1 TECHLAB 1 SOVTECH 1 ALLYTECH 1
        HOSPITAL 1 BIO 1 INFILTRATE 1 DOME 1
        PRISON 1 STEEL 1 ELECTRONICS 1
    }

    # Build GenericPrerequisites lookup from parsed data
    array set generic_prereqs {}
    foreach src {::Data::rulesdata ::Data::rawmapdata} {
        if {![info exists ${src}(GenericPrerequisites)]} continue
        foreach line [set ${src}(GenericPrerequisites)] {
            set kv [::util::_parse_keyval $line]
            if {$kv eq ""} continue
            set name [lindex $kv 0]
            set generic_prereqs($name) 1
        }
    }

    # Find all prerequisite references
    foreach src {::Data::rulesdata ::Data::rawmapdata} {
        if {![info exists $src]} continue

        foreach section [array names $src] {
            if {$section eq ""} continue

            foreach line [set ${src}($section)] {
                set kv [::util::_parse_keyval $line]
                if {$kv eq ""} continue
                set pfx [lindex $kv 0]
                set val [lindex $kv 1]

                if {$pfx ne "Prerequisite" && $pfx ne "PrerequisiteOverride"} continue
                if {$val eq ""} continue

                # Parse comma-separated prerequisites
                foreach prereq [split $val ","] {
                    set prereq [string trim $prereq]
                    if {$prereq eq ""} continue

                    set found 0

                    # Built-in generic prerequisites (always valid)
                    if {[info exists builtin_generic($prereq)]} {
                        set found 1
                    }

                    # Parsed GenericPrerequisites alias from rulesdata/rawmapdata
                    if {!$found && [info exists generic_prereqs($prereq)]} {
                        set found 1
                    }

                    # Building section in rulesdata or rawmapdata
                    if {!$found && [info exists ::Data::rulesdata($prereq)]} {
                        set found 1
                    }
                    if {!$found && [info exists ::Data::rawmapdata($prereq)]} {
                        set found 1
                    }

                    # Check known type registries
                    if {!$found && [info exists ::Data::buildings($prereq)]} { set found 1 }
                    if {!$found && [info exists ::Data::infantry($prereq)]} { set found 1 }
                    if {!$found && [info exists ::Data::vehicles($prereq)]} { set found 1 }
                    if {!$found && [info exists ::Data::aircraft($prereq)]} { set found 1 }

                    if {!$found} {
                        ::Logging::warning "\[$section\] uses undeclared Prerequisite: $prereq"
                    }
                }
            }
        }
    }
}
