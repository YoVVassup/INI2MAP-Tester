# checks/sonic_mindcontrol.tcl
# Validates Sonic + MindControl conflict on Warheads
# Game modes: All (RA2/YR/Ares/Phobos)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Sonic
# Bug: If a Warhead has both Sonic=yes and MindControl=yes,
#      the weapon cannot directly repel parasites and there
#      is no parasite removal cursor.

proc ::Checks::validate_sonic_mindcontrol {} {
    upvar ::Data::warheads warheads

    if {![info exists warheads]} return

    foreach {idx name} [array get warheads] {
        if {$name eq ""} continue

        set sonic [::Checks::get_cached_property $name "Sonic"]
        set mind_control [::Checks::get_cached_property $name "MindControl"]

        # Check if both flags are set
        if {[::Checks::is_true $sonic] && [::Checks::is_true $mind_control]} {
            ::Logging::warning "Warhead \"$name\" has both Sonic=yes and MindControl=yes. The weapon cannot directly repel parasites (can only repel by releasing sonic waves along the ground) and there is no parasite removal cursor."
        }
    }
}

# Register this check
::Checks::register_check "validate_sonic_mindcontrol"
