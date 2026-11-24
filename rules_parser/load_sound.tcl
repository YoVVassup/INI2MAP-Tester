#----------------------------------------------------------------------------------------------------------
# rules_parser/load_sound.tcl - Parse soundmo.enc (sound parameters)
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Rules::load_sound_loaded]} { return }
set ::Rules::load_sound_loaded 1

# --- Sound Parser ---
# Parse soundmo.enc: build sound list, per-sound parameters, and resource references.
proc ::Rules::load_sound {filepath} {
    if {![file exists $filepath]} {
        puts ">> [file tail $filepath] not found, skipping..."
        return
    }

    set content [::Rules::_load_ini $filepath]

    set lines [split $content "\n"]
    set cur_sound ""
    set in_soundlist 0
    set in_defaults 0
    set defaults [dict create]

    foreach rawline $lines {
        set line [::Rules::_strip_line $rawline]
        if {$line eq ""} continue

        set sec [::Rules::_parse_section $line]
        if {$sec ne ""} {
            set curtag $sec
            if {$curtag eq "SoundList"} {
                set in_soundlist 1
                set in_defaults 0
                set cur_sound ""
            } elseif {$curtag eq "Defaults"} {
                set in_soundlist 0
                set in_defaults 1
                set cur_sound ""
            } else {
                set in_soundlist 0
                set in_defaults 0
                set cur_sound [string tolower $curtag]
                if {![info exists ::Data::sound_params($cur_sound)]} {
                    set ::Data::sound_params($cur_sound) [dict create]
                    set ::Data::sound_resources($cur_sound) [list]
                }
            }
            continue
        }

        if {$in_soundlist} {
            set kv [::util::_parse_keyval $line]
            if {$kv eq ""} continue
            set sound_name [string tolower [lindex $kv 1]]
            if {[info exists ::Data::sound_params($sound_name)]} {
                ::Logging::warning "Duplicate sound in SoundList: $sound_name"
            }
            set cur_sound $sound_name
            set ::Data::sndlist($sound_name) ""
            set ::Data::sound_params($sound_name) [dict create]
            set ::Data::sound_resources($sound_name) [list]
            continue
        }

        if {$in_defaults} {
            set kv [::util::_parse_keyval $line]
            if {$kv eq ""} continue
            dict set defaults [lindex $kv 0] [lindex $kv 1]
            continue
        }

        if {$cur_sound ne ""} {
            set kv [::util::_parse_keyval $line]
            if {$kv eq ""} continue
            set key [lindex $kv 0]
            set val [lindex $kv 1]
            dict set ::Data::sound_params($cur_sound) $key $val
            if {$key eq "Sounds"} {
                regsub -all {\$} $val "" val_no_dollar
                set cleaned [list]
                foreach r [split $val_no_dollar] {
                    set r [string trim $r]
                    if {$r ne ""} {
                        set r [regsub {\.wav$} [string tolower $r] ""]
                        lappend cleaned $r
                    }
                }
                set ::Data::sound_resources($cur_sound) $cleaned
            }
        }
    }

    set ::Data::sound_defaults $defaults
}
