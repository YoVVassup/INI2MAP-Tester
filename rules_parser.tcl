#----------------------------------------------------------------------------------------------------------
# rules_parser.tcl - Aggregator for rules parsing submodules
#----------------------------------------------------------------------------------------------------------

# Ensure the namespace exists
namespace eval ::Rules {
    variable loaded 0
}

# Core helpers
source [file join [file dirname [info script]] "rules_parser" "core.tcl"]

# Loaders for each INI file type
source [file join [file dirname [info script]] "rules_parser" "load_rules.tcl"]
source [file join [file dirname [info script]] "rules_parser" "load_ai.tcl"]
source [file join [file dirname [info script]] "rules_parser" "load_art.tcl"]
source [file join [file dirname [info script]] "rules_parser" "load_sound.tcl"]
source [file join [file dirname [info script]] "rules_parser" "load_theme.tcl"]
source [file join [file dirname [info script]] "rules_parser" "load_eva.tcl"]

# Sound collection from rulesdata
source [file join [file dirname [info script]] "rules_parser" "collect_used_sounds.tcl"]

# --------------------------------------------------------------------------
# Main entry point: loads all required files and collects used sounds
# --------------------------------------------------------------------------
proc ::Rules::load_all {ra2dir rules_file ai_file art_file sound_file theme_file eva_file} {
    # Pre-decrypt all rules .enc files in one subprocess spawn
    set enc_paths {}
    foreach f [list $rules_file $ai_file $art_file $sound_file $theme_file $eva_file] {
        if {$f ne ""} { lappend enc_paths [file join $ra2dir $f] }
    }
    catch {::Crypto::prefetch_enc_files $enc_paths}

    set rules_path [file join $ra2dir $rules_file]
    if {[catch {::Rules::load_rules $rules_path} err]} {
        puts stderr "FATAL: Cannot load rules file: $err"
        exit 1
    }

    set ai_path [file join $ra2dir $ai_file]
    if {[catch {::Rules::load_ai $ai_path} err]} {
        puts stderr "FATAL: Cannot load AI file: $err"
        exit 1
    }

    if {$art_file ne ""} {
        set art_path [file join $ra2dir $art_file]
        if {[catch {::Rules::load_art $art_path} err]} {
            ::Logging::warning "Cannot load art file: $err"
        }
    }
    if {$sound_file ne ""} {
        set sound_path [file join $ra2dir $sound_file]
        if {[catch {::Rules::load_sound $sound_path} err]} {
            ::Logging::warning "Cannot load sound file: $err"
        }
    }
    if {$theme_file ne ""} {
        set theme_path [file join $ra2dir $theme_file]
        if {[catch {::Rules::load_theme $theme_path} err]} {
            ::Logging::warning "Cannot load theme file: $err"
        }
    }
    if {$eva_file ne ""} {
        set eva_path [file join $ra2dir $eva_file]
        if {[catch {::Rules::load_eva $eva_path} err]} {
            ::Logging::warning "Cannot load EVA file: $err"
        }
    }

    ::Rules::collect_used_sounds
}

return
