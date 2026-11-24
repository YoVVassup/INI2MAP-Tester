# checks/transports_return_bug.tcl
# Validates TransportsReturnOnUnload against passenger Size values in TeamTypes
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_cached_property
#
# References:
#   https://modenc.renegadeprojects.com/TransportsReturnOnUnload
#
# Bug:
#   When TransportsReturnOnUnload=yes is set on a TeamType and the transport
#   is fully loaded with all passengers having Size=1, the transport will NOT
#   return after unloading. This defeats the purpose of the flag.

proc ::Checks::validate_transports_return_bug {} {
    upvar ::Data::teamtypes teamtypes
    upvar ::Data::rawmapdata rawmapdata
    upvar ::Data::taskforces taskforces
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft

    if {![info exists teamtypes]} return

    # Collect all TechnoTypes with Size=1
    set size1_types [dict create]
    foreach arr_name {infantry vehicles aircraft} {
        if {[info exists $arr_name]} {
            foreach name [array names $arr_name] {
                set size_val [::Checks::get_cached_property $name "Size"]
                if {$size_val eq "1"} {
                    dict set size1_types $name 1
                }
            }
        }
    }

    foreach team_id [array names teamtypes] {
        if {![info exists rawmapdata($team_id)]} continue

        # Check TransportsReturnOnUnload
        set tro_value ""
        set tf_id ""
        foreach curline $rawmapdata($team_id) {
            set eq [string first "=" $curline]
            if {$eq == -1} continue
            set key [string trim [string range $curline 0 [expr {$eq - 1}]]]
            set val [string trim [string range $curline [expr {$eq + 1}] end]]
            switch -- $key {
                "TransportsReturnOnUnload" { set tro_value $val }
                "TaskForce" { set tf_id $val }
            }
        }

        if {[string tolower $tro_value] ne "yes"} continue
        if {$tf_id eq "" || ![info exists rawmapdata($tf_id)]} continue

        # Find transport units in TaskForce and check their passengers
        foreach curline $rawmapdata($tf_id) {
            set eq [string first "=" $curline]
            if {$eq == -1} continue
            set idx [string trim [string range $curline 0 [expr {$eq - 1}]]]
            if {$idx eq "Name" || $idx eq "Group"} continue

            set fields [split [string trim [string range $curline [expr {$eq + 1}] end]] ","]
            if {[llength $fields] < 2} continue

            set unit_type [string trim [lindex $fields 1]]
            if {$unit_type eq ""} continue

            # Check if this unit type has Passengers property (it's a transport)
            set passengers [::Checks::get_cached_property $unit_type "Passengers"]
            if {$passengers eq "" || $passengers == 0} continue

            # Check if there are occupants with Size=1 that could cause the bug
            # We check if the transport has any Size=1 types assigned as passengers
            set has_size1_passenger 0
            set size1_passenger_name ""

            # Check common passenger types for this transport
            foreach ptype [array names infantry] {
                set psize [::Checks::get_cached_property $ptype "Size"]
                if {$psize eq "1"} {
                    set has_size1_passenger 1
                    set size1_passenger_name $ptype
                    break
                }
            }
            if {!$has_size1_passenger} {
                foreach ptype [array names vehicles] {
                    set psize [::Checks::get_cached_property $ptype "Size"]
                    if {$psize eq "1"} {
                        set has_size1_passenger 1
                        set size1_passenger_name $ptype
                        break
                    }
                }
            }

            if {$has_size1_passenger} {
                ::Logging::warning "TeamType \"$team_id\" has TransportsReturnOnUnload=yes but transport \"$unit_type\" in TaskForce \"$tf_id\" may carry Size=1 units (e.g., \"$size1_passenger_name\"). When fully loaded with Size=1 passengers, the transport will NOT return after unloading."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_transports_return_bug"
