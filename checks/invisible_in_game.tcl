# checks/invisible_in_game.tcl
# Validates all object types with InvisibleInGame=yes for reconnection errors on player-owned objects, unarmed buildings, and ignored tags (GuardRange, UndeploysInto, CanOccupyFire, Buildup, RevealToAll)
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Helper to check if an object type belongs to a player house on the map
proc ::Checks::_iig_belongs_to_player {obj_name} {
    foreach section {Structures Units Infantry} {
        if {![info exists ::Data::rawmapdata($section)]} continue
        foreach line $::Data::rawmapdata($section) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set values [split [string range $line [expr {$eq+1}] end] ","]
            if {[llength $values] < 2} continue
            set placed_type [string trim [lindex $values 1]]
            if {$placed_type ne $obj_name} continue
            set house_name [string trim [lindex $values 0]]
            if {[info exists ::Data::houses($house_name)]} {
                set pc [::Checks::get_cached_property $house_name "PlayerControl"]
                if {[::Checks::is_true $pc]} {
                    return [list 1 $house_name]
                }
            }
        }
    }
    return [list 0 ""]
}

proc ::Checks::validate_invisible_in_game {} {
    upvar ::Data::buildings buildings
    upvar ::Data::vehicles vehicles
    upvar ::Data::infantry infantry
    upvar ::Data::aircraft aircraft

    # Collect all object types
    set all_types [list]
    if {[info exists infantry]} {
        foreach name [array names infantry] { lappend all_types [list "Infantry" $name] }
    }
    if {[info exists vehicles]} {
        foreach name [array names vehicles] { lappend all_types [list "Vehicle" $name] }
    }
    if {[info exists aircraft]} {
        foreach name [array names aircraft] { lappend all_types [list "Aircraft" $name] }
    }
    if {[info exists buildings]} {
        foreach name [array names buildings] { lappend all_types [list "Building" $name] }
    }

    foreach {type name} $all_types {
        set invisible [::Checks::get_cached_property $name "InvisibleInGame"]
        if {![::Checks::is_true $invisible]} {
            continue
        }

        # Check if this object is placed on the map and owned by a player
        lassign [::Checks::_iig_belongs_to_player $name] belongs_to_player player_house
        if {$belongs_to_player} {
            ::Logging::warning "$type \"$name\" with InvisibleInGame=yes is owned by player house \"$player_house\". This may cause reconnection errors."
        }

        # Buildings become unarmed
        if {$type eq "Building"} {
            set primary [::Checks::get_cached_property $name "Primary"]
            set secondary [::Checks::get_cached_property $name "Secondary"]
            if {$primary ne "" || $secondary ne ""} {
                ::Logging::warning "Building \"$name\" has InvisibleInGame=yes and weapons defined. The building will be unarmed (weapons are ignored)."
            }
        }

        # Ignored tags (only warn if they are explicitly set)
        set guard_range [::Checks::get_cached_property $name "GuardRange"]
        if {$guard_range ne ""} {
            ::Logging::warning "$type \"$name\" has InvisibleInGame=yes and GuardRange=$guard_range. GuardRange will be ignored for wall connections."
        }

        set undeploys_into [::Checks::get_cached_property $name "UndeploysInto"]
        if {$undeploys_into ne ""} {
            ::Logging::warning "$type \"$name\" has InvisibleInGame=yes and UndeploysInto=$undeploys_into. UndeploysInto will be ignored."
        }

        set can_occupy_fire [::Checks::get_cached_property $name "CanOccupyFire"]
        if {[::Checks::is_true $can_occupy_fire]} {
            ::Logging::warning "$type \"$name\" has InvisibleInGame=yes and CanOccupyFire=yes. CanOccupyFire will be ignored."
        }

        set buildup [::Checks::get_cached_property $name "Buildup"]
        if {$buildup ne "" && [::Checks::is_true $buildup]} {
            ::Logging::warning "$type \"$name\" has InvisibleInGame=yes and Buildup=yes. Buildup will be ignored."
        }

        set reveal_to_all [::Checks::get_cached_property $name "RevealToAll"]
        if {[::Checks::is_true $reveal_to_all]} {
            ::Logging::warning "$type \"$name\" has InvisibleInGame=yes and RevealToAll=yes. RevealToAll will be ignored."
        }
    }
}

::Checks::register_check "validate_invisible_in_game"