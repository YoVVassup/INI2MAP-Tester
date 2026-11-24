#----------------------------------------------------------------------------------------------------------
# rules_parser/load_art.tcl - Parse artmo.enc (art/graphics rules)
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Rules::load_art_loaded]} { return }
set ::Rules::load_art_loaded 1

proc ::Rules::load_art {filepath} {
    if {![file exists $filepath]} {
        puts ">> [file tail $filepath] not found, skipping..."
        return
    }

    set content [::Rules::_load_ini $filepath]

    set lines [split $content "\n"]
    set in_movies 0
    set movie_idx 0
    set curtag ""

    foreach rawline $lines {
        set line [::Rules::_strip_line $rawline]
        if {$line eq ""} continue

        set sec [::Rules::_parse_section $line]
        if {$sec ne ""} {
            set curtag $sec
            if {$curtag eq "Movies"} {
                set in_movies 1
                set movie_idx 0
            } else {
                set in_movies 0
                set ::Data::art_sections($curtag) 1
                if {[info exists ::Data::buildings($curtag)]} {
                    set ::Data::artery($curtag) "1x1"
                }
            }
            continue
        }

        if {$in_movies} {
            set kv [::util::_parse_keyval $line]
            if {$kv ne ""} {
                set name [lindex $kv 1]
            } else {
                set name $line
            }
            set ::Data::movies($movie_idx) $name
            incr movie_idx
            continue
        }

        set kv [::util::_parse_keyval $line]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set val [lindex $kv 1]

        if {$pfx eq "Report" || $pfx eq "StartSound"} {
            set ::Data::used_sounds_art([string tolower $val]) 1
        }

        if {$pfx eq "Foundation"} {
            set plop [string tolower $val]
            if {[info exists ::Data::terrains($curtag)]} {
                set ::Data::terrain_foundation($curtag) $plop
            } elseif {$plop ne "0x0"} {
                set p2 [split $plop "x"]
                if {[string is integer [lindex $p2 0]] && [string is integer [lindex $p2 1]]} {
                    set ::Data::artery($curtag) $plop
                } elseif {![info exists ::Data::artery($curtag)]} {
                    set ::Data::artery($curtag) "1x1"
                }
            }
        }
    }

    if {[info exists ::Data::art]} {
        foreach {bldg img} [array get ::Data::art] {
            if {[info exists ::Data::artery($img)]} {
                set ::Data::artery($bldg) $::Data::artery($img)
            } else {
                ::Logging::warning "Building \"$bldg\" has missing ART, unable to set correct foundation"
                set ::Data::artery($bldg) "1x1"
            }
        }
    }
}
