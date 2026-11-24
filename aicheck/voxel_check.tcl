#----------------------------------------------------------------------------------------------------------
# aicheck/voxel_check.tcl - VoxelAnim property validation
#----------------------------------------------------------------------------------------------------------
# Checks VoxelAnims for: missing Warhead, Damage, angular velocity ranges,
# voxel flag in art, deprecated ShareSource usage, etc.
#----------------------------------------------------------------------------------------------------------

proc ::AICheck::check_voxelanims {} {
    if {![array exists ::Data::vanims] || [array size ::Data::vanims] == 0} {
        ::Logging::notice "No VoxelAnims defined, skipping voxel check."
        return
    }
    if {![array exists ::Data::warheads] || [array size ::Data::warheads] == 0} {
        ::Logging::notice "No Warheads defined, skipping voxel check."
        return
    }

    # vanims is keyed by numeric index (load_rules.tcl:112 / typedecl_others.tcl);
    # the anim NAME is the value and rulesdata sections are keyed by name.
    foreach vidx [array names ::Data::vanims] {
        set var $::Data::vanims($vidx)
        set whfound 0
        set damfound 0
        set minv -1
        set maxv -2
        set minz -1
        set maxz -1
        set spawner 0
        set noart 0

        if {![array exists ::Data::rulesdata] || ![info exists ::Data::rulesdata($var)]} continue

        foreach line $::Data::rulesdata($var) {
            set kv [::util::_parse_keyval $line]
            if {$kv eq ""} continue
            set pfx [lindex $kv 0]
            set val [lindex $kv 1]

            switch -- $pfx {
                "Warhead" {
                    set whfound 0
                    foreach idx [array names ::Data::warheads] {
                        if {$::Data::warheads($idx) eq $val} { set whfound 1; break }
                    }
                    if {!$whfound && [info exists ::Data::rawmapdata(Warheads)]} {
                        foreach wl $::Data::rawmapdata(Warheads) {
                            set wkv [::util::_parse_keyval $wl]
                            if {$wkv ne "" && [lindex $wkv 1] eq $val} {
                                set whfound 1; break
                            }
                        }
                    }
                    if {!$whfound} {
                        ::Logging::warning "VoxelAnim \"$var\" uses undeclared Warhead: $val"
                    }
                }
                "Damage" {
                    if {[::AICheck::_is_int $val]} {
                        set damfound 1
                    } else {
                        ::Logging::warning "VoxelAnim \"$var\" has non-numeric Damage: $val"
                    }
                }
                "Image" {
                    if {$val eq "none" || $val eq ""} {
                        set noart 1
                    }
                }
                "Spawns" {
                    # $val is a VoxelAnim NAME; vanims is index-keyed, so match by value
                    set spawn_found 0
                    foreach vname [array values ::Data::vanims] {
                        if {$vname eq $val} { set spawn_found 1; break }
                    }
                    if {!$spawn_found && [info exists ::Data::rulesdata($val)]} {
                        set spawn_found 1
                    } elseif {!$spawn_found && [info exists ::Data::rawmapdata($val)]} {
                        set spawn_found 1
                    }
                    if {!$spawn_found} {
                        ::Logging::warning "VoxelAnim \"$var\" Spawns undeclared VoxelAnim: $val"
                    }
                    incr spawner
                }
                "MinAngularVelocity" {
                    if {[::AICheck::_is_float $val]} { set minv $val }
                }
                "MaxAngularVelocity" {
                    if {[::AICheck::_is_float $val]} { set maxv $val }
                }
                "MinZVel" {
                    if {[::AICheck::_is_float $val]} { set minz $val }
                }
                "MaxZVel" {
                    if {[::AICheck::_is_float $val]} { set maxz $val }
                }
                "ShareSource" {
                    ::Logging::warning "VoxelAnim \"$var\" uses deprecated ShareSource"
                }
                "ShareTurretData" {
                    ::Logging::warning "VoxelAnim \"$var\" uses deprecated ShareTurretData"
                }
                "ShareBarrelData" {
                    ::Logging::warning "VoxelAnim \"$var\" uses deprecated ShareBarrelData"
                }
            }
        }

        if {!$whfound} {
            ::Logging::warning "VoxelAnim \"$var\" missing Warhead"
        }
        if {!$damfound} {
            ::Logging::warning "VoxelAnim \"$var\" missing Damage"
        }
        if {$minv != -1 && $maxv != -2 && $maxv < $minv} {
            ::Logging::warning "VoxelAnim \"$var\" MinAngularVelocity > MaxAngularVelocity: $minv > $maxv"
        }
        if {$minz != -1 && $maxz != -1 && $maxz < $minz} {
            ::Logging::warning "VoxelAnim \"$var\" MinZVel > MaxZVel: $minz > $maxz"
        }
    }
}
