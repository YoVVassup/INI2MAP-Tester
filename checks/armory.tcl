# checks/armory.tcl
# Validates Armory=yes building configurations for conflicts with ConstructionYard, Factory, Cloning, Ammo, and weapon settings that cause glitchy behavior
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::is_true, ::Checks::get_cached_property

proc ::Checks::validate_armory {} {
    upvar ::Data::buildings buildings

    if {![info exists buildings]} return

    foreach bldg [array names buildings] {
        set armory [::Checks::get_cached_property $bldg "Armory"]
        if {![::Checks::is_true $armory]} continue

        set conyard [::Checks::get_cached_property $bldg "ConstructionYard"]
        if {[::Checks::is_true $conyard]} {
            ::Logging::error "Building \"$bldg\" has both Armory=yes and ConstructionYard=yes. This causes glitchy behavior: infantry will enter and never come back out (building cycles image frames rapidly)."
        }

        set factory [::Checks::get_cached_property $bldg "Factory"]
        if {$factory ne ""} {
            if {$factory eq "InfantryType"} {
                ::Logging::notice "Building \"$bldg\" uses Armory=yes with Factory=InfantryType. This workaround allows a rally point but causes Cloning buildings to spawn unpromoted copies."
            }
            ::Logging::warning "Building \"$bldg\" has Armory=yes and a Factory set. AI may spam only the first buildable unit type from this building."
        }

        set cloning [::Checks::get_cached_property $bldg "Cloning"]
        if {[::Checks::is_true $cloning]} {
            ::Logging::notice "Building \"$bldg\" has Armory=yes and Cloning=yes. If used with Factory=InfantryType, Cloning will spawn unpromoted copies of promoted units."
        }

        set primary [::Checks::get_cached_property $bldg "Primary"]
        set secondary [::Checks::get_cached_property $bldg "Secondary"]
        set has_weapon [expr {$primary ne "" || $secondary ne ""}]
        set ammo [::Checks::get_cached_property $bldg "Ammo"]
        if {$has_weapon} {
            if {[string is integer -strict $ammo] && $ammo > 0} {
                ::Logging::warning "Armory \"$bldg\" has a weapon and Ammo=$ammo. Both promoting infantry and firing decrease Ammo. Once Ammo=0, it can no longer promote or fire (Armory tag prevents reload)."
            }
        }

        if {$ammo eq "" || (![string is integer -strict $ammo] || $ammo == 0)} {
            ::Logging::warning "Building \"$bldg\" has Armory=yes but Ammo not set. Without Ammo, it can only promote one infantry unit ever. Set Ammo to desired limit (e.g., 999)."
        } elseif {[string is integer -strict $ammo] && $ammo < 0} {
            ::Logging::notice "Armory \"$bldg\" has Ammo=$ammo (negative). Game takes absolute value for ammo count (|-1| = 1)."
        }

        ::Logging::notice "Armory \"$bldg\": infantry cannot directly attack this building (requires tag-based attacks)."
    }
}

# Register this check
::Checks::register_check "validate_armory"