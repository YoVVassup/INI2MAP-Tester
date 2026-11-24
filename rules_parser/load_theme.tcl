#----------------------------------------------------------------------------------------------------------
# rules_parser/load_theme.tcl - Parse thememo.enc (music themes)
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Rules::load_theme_loaded]} { return }
set ::Rules::load_theme_loaded 1

proc ::Rules::load_theme {filepath} {
    if {![file exists $filepath]} {
        puts ">> [file tail $filepath] not found, skipping..."
        return
    }

    set content [::Rules::_load_ini $filepath]

    set lines [split $content "\n"]
    set in_themes 0
    set theme_idx 0
    array set ::Data::themes_by_name {}

    foreach rawline $lines {
        set line [::Rules::_strip_line $rawline]
        if {$line eq ""} continue

        set sec [::Rules::_parse_section $line]
        if {$sec ne ""} {
            if {$sec eq "Themes"} {
                set in_themes 1
                set theme_idx 0
            } else {
                set in_themes 0
            }
            continue
        }

        if {$in_themes} {
            set kv [::util::_parse_keyval $line]
            if {$kv ne ""} {
                set name [lindex $kv 1]
            } else {
                set name $line
            }
            if {[info exists ::Data::themes_by_name($name)]} {
                ::Logging::warning "Duplicate theme: $name"
            }
            set ::Data::themes($theme_idx) $name
            incr theme_idx
        }
    }

    foreach {idx name} [array get ::Data::themes] {
        set ::Data::themes_by_name($name) 1
    }
}
