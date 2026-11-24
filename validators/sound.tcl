#----------------------------------------------------------------------------------------------------------
# validators_sound.tcl - Sound validation for INI2MAP Tester (case-insensitive, with defaults)
#----------------------------------------------------------------------------------------------------------

# --- _in_list ---
# Checks if a value exists in a list (case-insensitive).
proc ::Validators::_in_list {val list} {
    foreach item $list {
        if {[string equal -nocase $val $item]} { return 1 }
    }
    return 0
}

# --- Sound Validation ---
# Validate sound definitions: checks existence, parameter ranges, audio resources, and unused sounds.
# --- validate_sounds ---
# Validates sound definitions, parameters, and audio resources.
proc ::Validators::validate_sounds {} {
    if {!$::Data::sound_validation} {
        return
    }

    if {![info exists ::Data::sound_params] || [array size ::Data::sound_params] == 0} {
        ::Logging::warning "No sound objects loaded from sound.ini. Sound validation skipped."
        return
    }

    # Load defaults if available
    if {[info exists ::Data::sound_defaults]} {
        set defaults $::Data::sound_defaults
    } else {
        set defaults [dict create]
    }

    set used_in_rules [array names ::Data::used_sounds_rules]
    set used_in_art   [array names ::Data::used_sounds_art]

    # 1. Check that all used sounds exist in sound.ini
    foreach snd $used_in_rules {
        if {![info exists ::Data::sound_params($snd)]} {
            ::Logging::error "Sound \"$snd\" used in rules.ini is not defined in sound.ini."
        }
    }
    foreach snd $used_in_art {
        if {![info exists ::Data::sound_params($snd)]} {
            ::Logging::error "Sound \"$snd\" used in art.ini is not defined in sound.ini."
        }
    }

    # Extended valid Type values (from RA2/YR/Ares/Phobos)
    set valid_type {
        global ambient violent movement quiet loud normal screen local
        player gun_shy noise_shy shroud unshroud
    }

    # 2. Validate parameters of each sound object
    foreach snd [array names ::Data::sound_params] {
        # Merge defaults with sound's own parameters
        set params $::Data::sound_params($snd)
        set effective $defaults
        dict for {key val} $params {
            dict set effective $key $val
        }

        # ---- Control ----
        if {[dict exists $effective Control]} {
            set control_val [dict get $effective Control]
            set valid_control {random loop all predelay interrupt ambient attack decay}
            foreach ctrl $control_val {
                if {![::Validators::_in_list $ctrl $valid_control]} {
                    ::Logging::warning "Sound \"$snd\" has unrecognized Control value: $ctrl"
                }
            }
        }

        # ---- Type & Range ----
        set type_val ""
        if {[dict exists $effective Type]} {
            set type_val [dict get $effective Type]
            # Split by whitespace (may be multiple)
            foreach t $type_val {
                if {![::Validators::_in_list $t $valid_type]} {
                    ::Logging::warning "Sound \"$snd\" has invalid Type value: $t"
                }
            }
        }
        set range_val ""
        if {[dict exists $effective Range]} {
            set range_val [dict get $effective Range]
            if {![string is integer -strict $range_val]} {
                ::Logging::warning "Sound \"$snd\" has non-integer Range: $range_val"
            } elseif {$range_val < 1 || $range_val > 50} {
                ::Logging::warning "Sound \"$snd\" has Range=$range_val (should be 1-50)."
            }
        }
        # Consistency: if Type contains "local", Range must be present
        set has_local 0
        if {$type_val ne ""} {
            foreach t $type_val {
                if {[string equal -nocase $t "local"]} {
                    set has_local 1
                    break
                }
            }
        }
        if {$has_local && $range_val eq ""} {
            ::Logging::warning "Sound \"$snd\" has Type=local but no Range defined (neither explicitly nor via defaults)."
        }

        # ---- Volume ----
        if {[dict exists $effective Volume]} {
            set vol [dict get $effective Volume]
            if {![string is integer -strict $vol]} {
                ::Logging::warning "Sound \"$snd\" has non-integer Volume: $vol"
            } elseif {$vol < 0 || $vol > 100} {
                ::Logging::warning "Sound \"$snd\" has Volume=$vol (should be 0-100)."
            }
        }

        # ---- Priority ----
        if {[dict exists $effective Priority]} {
            set prio [dict get $effective Priority]
            set valid_prio {lowest low normal high critical}
            if {![::Validators::_in_list $prio $valid_prio]} {
                ::Logging::warning "Sound \"$snd\" has invalid Priority: $prio"
            }
        }

        # ---- Limit, Loop, Decay, Attack ----
        foreach param {Limit Loop Decay Attack} {
            if {[dict exists $effective $param]} {
                set val [dict get $effective $param]
                if {![string is integer -strict $val]} {
                    ::Logging::warning "Sound \"$snd\" has non-integer $param: $val"
                } elseif {$val < 0 || $val > 10} {
                    ::Logging::warning "Sound \"$snd\" has $param=$val (should be 0-10)."
                }
            }
        }

        # ---- VShift / FShift ----
        foreach param {VShift FShift} {
            if {[dict exists $effective $param]} {
                set val [dict get $effective $param]
                if {[llength $val] < 1 || [llength $val] > 2} {
                    ::Logging::warning "Sound \"$snd\" has invalid $param (expected 1 or 2 values)."
                }
                foreach num $val {
                    if {![string is integer -strict $num]} {
                        ::Logging::warning "Sound \"$snd\" has non-integer $param: $num"
                    } elseif {$num < -50 || $num > 50} {
                        ::Logging::warning "Sound \"$snd\" has $param=$num (should be -50..50)."
                    }
                }
            }
        }
    }

    # 3. Validate audio resources (if audio.idx available)
    if {[info exists ::Data::audio_idx_available] && $::Data::audio_idx_available} {
        foreach snd [array names ::Data::sound_resources] {
            set reslist $::Data::sound_resources($snd)
            if {[llength $reslist] == 0} {
                ::Logging::warning "Sound \"$snd\" has no audio resources (Sounds= line missing or empty)."
                continue
            }
            set missing_resources [list]
            foreach res $reslist {
                if {![info exists ::Data::audio_resources($res)]} {
                    lappend missing_resources $res
                }
            }
            if {[llength $missing_resources] > 0} {
                ::Logging::error "Sound \"$snd\" references missing audio resource(s): [join $missing_resources ", "]"
            }

            if {[info exists ::Data::sound_warn_duplicate_resources] && $::Data::sound_warn_duplicate_resources} {
                set unique [lsort -unique $reslist]
                if {[llength $unique] != [llength $reslist]} {
                    ::Logging::warning "Sound \"$snd\" has duplicate resource entries."
                }
            }
        }

        if {[info exists ::Data::sound_warn_orphan_resources] && $::Data::sound_warn_orphan_resources} {
            array set used_resources {}
            foreach snd [array names ::Data::sound_resources] {
                foreach res $::Data::sound_resources($snd) {
                    set used_resources($res) 1
                }
            }
            set orphans [list]
            foreach res [array names ::Data::audio_resources] {
                if {![info exists used_resources($res)]} {
                    lappend orphans $res
                }
            }
            if {[llength $orphans] > 0} {
                ::Logging::notice "Unused audio resources (orphans): [join [lsort $orphans] ", "]"
            }
        }
    } else {
        if {[info exists ::Data::sound_check_audio] && $::Data::sound_check_audio} {
            ::Logging::notice "audio.idx not available; resource validation skipped."
        }
    }

    # 4. Report unused sound objects
    if {[info exists ::Data::sound_warn_unused] && $::Data::sound_warn_unused} {
        set unused_sounds [list]
        foreach snd [array names ::Data::sound_params] {
            if {![info exists ::Data::used_sounds_rules($snd)] && ![info exists ::Data::used_sounds_art($snd)]} {
                lappend unused_sounds $snd
            }
        }
        if {[llength $unused_sounds] > 0} {
            ::Logging::notice "Unused sound objects: [join [lsort $unused_sounds] ", "]"
        }
    }
}