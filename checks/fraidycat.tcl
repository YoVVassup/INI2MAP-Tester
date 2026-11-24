# checks/fraidycat.tcl
# Validates that InfantryTypes with Slaved=yes do not have conflicting Fraidycat=yes and Fearless=yes flags
# Game modes: RA2/YR/Ares/Phobos
# Uses: is_true, get_cached_property

proc ::Checks::validate_fraidycat {} {
    upvar ::Data::infantry infantry

    if {![info exists infantry]} return

    foreach inf [array names infantry] {
        set fraidycat [::Checks::get_cached_property $inf "Fraidycat"]
        set fearless  [::Checks::get_cached_property $inf "Fearless"]
        set slaved    [::Checks::get_cached_property $inf "Slaved"]

        set hasFraidycat [::Checks::is_true $fraidycat]
        set hasFearless  [::Checks::is_true $fearless]
        set hasSlaved    [::Checks::is_true $slaved]

        if {!$hasFraidycat || !$hasFearless || !$hasSlaved} continue
        ::Logging::warning "InfantryType \"$inf\" is marked as Slaved=yes and has Fraidycat=yes and Fearless=yes. This will prevent the Slave Worker from entering the Slave Miner after harvesting ore."
    }
}

# Register this check
::Checks::register_check "validate_fraidycat"