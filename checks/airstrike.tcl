# checks/airstrike.tcl
# Validates AirstrikeTeam and AirstrikeTeamType properties are correctly configured on types using Airstrike logic, preventing laser guidance failures and crashes
# Game modes: YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property, ::Checks::get_all_techno_types

proc ::Checks::validate_airstrike {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::aircraft aircraft
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::rawmapdata rawmapdata

    if {$gamemode eq "ra2"} return

    set all_types [::Checks::get_all_techno_types]

    foreach sect {InfantryTypes VehicleTypes} {
        if {[info exists rawmapdata($sect)]} {
            foreach line $rawmapdata($sect) {
                set eq [string first "=" $line]
                if {$eq == -1} continue
                set type_name [string trim [string range $line [expr {$eq+1}] end]]
                if {$type_name ne ""} { lappend all_types $type_name }
            }
        }
    }
    set all_types [lsort -unique $all_types]

    foreach type $all_types {
        set airstrike        [::Checks::get_cached_property $type "Airstrike"]
        set airstrike_team   [::Checks::get_cached_property $type "AirstrikeTeam"]
        set airstrike_teamtype [::Checks::get_cached_property $type "AirstrikeTeamType"]

        if {![::Checks::is_true $airstrike] && $airstrike_team eq "" && $airstrike_teamtype eq ""} {
            continue
        }

        if {$airstrike_team ne ""} {
            if {![string is integer -strict $airstrike_team]} {
                ::Logging::error "Type \"$type\" has AirstrikeTeam=\"$airstrike_team\" which is not an integer. Required for Airstrike to function."
            } elseif {$airstrike_team < 1} {
                ::Logging::error "Type \"$type\" has AirstrikeTeam=$airstrike_team (must be >= 1). No aircraft will be spawned."
            } elseif {$airstrike_team > 8} {
                ::Logging::warning "Type \"$type\" has AirstrikeTeam=$airstrike_team (> 8). Values above 8 may cause unexpected behavior."
            }
        } else {
            if {[::Checks::is_true $airstrike] || $airstrike_teamtype ne ""} {
                ::Logging::error "Type \"$type\" uses Airstrike logic but missing AirstrikeTeam. Laser guidance will not work and may cause IE."
            }
        }

        if {$airstrike_teamtype ne ""} {
            if {![info exists aircraft($airstrike_teamtype)]} {
                ::Logging::error "Type \"$type\" has AirstrikeTeamType=\"$airstrike_teamtype\" which is not a valid AircraftType. Firing will cause crash (EI)."
            }
        } else {
            if {[::Checks::is_true $airstrike] || $airstrike_team ne ""} {
                ::Logging::error "Type \"$type\" uses Airstrike logic but missing AirstrikeTeamType. Firing will cause crash (EI)."
            }
        }
    }
}

::Checks::register_check "validate_airstrike"