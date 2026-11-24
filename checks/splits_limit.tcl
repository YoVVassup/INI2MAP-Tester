# checks/splits_limit.tcl
# Validates Splits usage in Projectiles
# Game modes: RA2/YR (vanilla only — fixed in Ares)
# Uses: ::Checks::is_true, ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/Splits
# Bugs in vanilla:
#   1. Speed for new projectiles is hardcoded to ~19
#   2. Damage for new projectiles is always multiplied by 10
#   3. Bright for new projectiles is always set to no

proc ::Checks::validate_splits_limit {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::projectiles projectiles

    # Only check in vanilla modes (fixed in Ares)
    set is_ares [expr {$gamemode eq "ares" || $gamemode eq "phobos"}]
    if {$is_ares} return

    if {![info exists projectiles]} return

    foreach {idx name} [array get projectiles] {
        if {$name eq ""} continue

        set splits [::Checks::get_cached_property $name "Splits"]
        if {![::Checks::is_true $splits]} continue

        ::Logging::notice "Projectile \"$name\" has Splits=yes. In vanilla RA2/YR, split projectiles have hardcoded limitations: Speed=~19, Damage multiplied by 10, Bright=no."
    }
}

# Register this check
::Checks::register_check "validate_splits_limit"
