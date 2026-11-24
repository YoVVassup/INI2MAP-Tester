# checks/airburst_split.tcl
# Validates AirburstSpread and Splits projectile properties are not combined (incompatible) and flags their use outside Ares/Phobos where they are unsupported
# Game modes: Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_airburst_split {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::projectiles projectiles

    if {$gamemode ne "ares" && $gamemode ne "phobos"} return
    if {![info exists projectiles]} return

    foreach {idx proj_name} [array get projectiles] {
        set airburst [::Checks::get_cached_property $proj_name "AirburstSpread"]
        set splits   [::Checks::get_cached_property $proj_name "Splits"]

        if {$airburst eq "" && $splits eq ""} continue

        if {$airburst ne ""} {
            if {![string is double -strict $airburst]} {
                ::Logging::error "Projectile \"$proj_name\" has non-numeric AirburstSpread: $airburst"
                continue
            }
        }

        set has_airburst [expr {$airburst ne "" && [string is double -strict $airburst] && $airburst > 0}]
        set has_splits   [::Checks::is_true $splits]

        if {$has_airburst && $has_splits} {
            ::Logging::warning "Projectile \"$proj_name\" has both AirburstSpread=$airburst and Splits=yes. These flags are incompatible and may cause crashes or unexpected behavior."
        }
    }
}

# Register this check
::Checks::register_check "validate_airburst_split"