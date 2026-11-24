#----------------------------------------------------------------------------------------------------------
# rules_parser/load_eva.tcl - Parse evamo.enc (EVA dialog lines)
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Rules::load_eva_loaded]} { return }
set ::Rules::load_eva_loaded 1

proc ::Rules::load_eva {filepath} {
    if {![file exists $filepath]} {
        puts ">> [file tail $filepath] not found, skipping..."
        return
    }

    set content [::Rules::_load_ini $filepath]

    set lines [split $content "\n"]
    set in_dialog 0
    set dialog_idx 0
    array set ::Data::dialogs_by_name {}

    foreach rawline $lines {
        set line [::Rules::_strip_line $rawline]
        if {$line eq ""} continue

        set sec [::Rules::_parse_section $line]
        if {$sec ne ""} {
            if {$sec eq "DialogList"} {
                set in_dialog 1
                set dialog_idx 0
            } else {
                set in_dialog 0
            }
            continue
        }

        if {$in_dialog} {
            set kv [::util::_parse_keyval $line]
            if {$kv ne ""} {
                set name [lindex $kv 1]
            } else {
                set name $line
            }
            if {[info exists ::Data::dialogs_by_name($name)]} {
                ::Logging::warning "Duplicate dialog: $name"
            }
            set ::Data::dialogs($dialog_idx) $name
            incr dialog_idx
        }
    }

    foreach {idx name} [array get ::Data::dialogs] {
        set ::Data::dialogs_by_name($name) 1
    }
}
