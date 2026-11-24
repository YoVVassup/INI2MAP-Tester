#----------------------------------------------------------------------------------------------------------
# rules_parser/load_ai.tcl - Parse aimo.enc (AI trigger types)
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Rules::load_ai_loaded]} { return }
set ::Rules::load_ai_loaded 1

proc ::Rules::load_ai {filepath} {
    upvar ::Data::aitriggertypes aitriggertypes

    set content [::Rules::_load_ini $filepath]

    set lines [split $content "\n"]
    set cmode 0

    foreach rawline $lines {
        set line [::Rules::_strip_line $rawline]
        if {$line eq ""} continue

        set sec [::Rules::_parse_section $line]
        if {$sec ne ""} {
            switch -- $sec {
                "TaskForces"      { set cmode 1 }
                "ScriptTypes"     { set cmode 2 }
                "TeamTypes"       { set cmode 3 }
                "AITriggerTypes"  { set cmode 4 }
                "Digest"          { break }
                default           { set cmode 51 }
            }
            continue
        }

        set kv [::util::_parse_keyval $line]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set val [lindex $kv 1]

        switch -- $cmode {
            1 {
                # TaskForces: format is "index=TaskForceID"
                if {![info exists ::Data::taskforces($val)]} {
                    set ::Data::taskforces($val) ""
                }
                # AI-module content: consumed by global AITriggers, not by the
                # map - never report it as "unused"
                set ::Data::ai_defs($val) 1
            }
            2 {
                # ScriptTypes: format is "index=ScriptID"
                if {![info exists ::Data::scripts($val)]} {
                    set ::Data::scripts($val) ""
                }
                set ::Data::ai_defs($val) 1
            }
            3 {
                # TeamTypes: format is "index=TeamTypeID"
                if {![info exists ::Data::teamtypes($val)]} {
                    set ::Data::teamtypes($val) ""
                }
                set ::Data::ai_defs($val) 1
            }
            4 {
                # AITriggerTypes: format is "TriggerID=Name,..."
                if {![info exists aitriggertypes($pfx)]} {
                    set aitriggertypes($pfx) "x"
                }
            }
        }
    }

    if {![info exists aitriggertypes] || [array size aitriggertypes] == 0} {
        puts "WARNING: No AITriggerTypes loaded from AI file."
    }
    return 1
}
