#----------------------------------------------------------------------------------------------------------
# orchestrator.tcl - Main map validation orchestrator for INI2MAP Tester
#----------------------------------------------------------------------------------------------------------
# Loads rules, parses the map, runs all validators and checks.
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Orchestrator::loaded]} { return }
namespace eval ::Orchestrator { variable loaded 1 }

# --- Helper: get elapsed time since start ---
proc ::Orchestrator::_elapsed {start_ms} {
    expr {[clock milliseconds] - $start_ms}
}

# --- Shared phase: load audio indices based on game mode ---
proc ::Orchestrator::_load_audio {} {
    if {!$::Data::sound_check_audio} return
    # Skip if audio already loaded from cache
    if {[info exists ::Data::audio_idx_available] && $::Data::audio_idx_available} return
    if {[info commands ::Utils::load_audio_indices] eq ""} {
        source [file join [file dirname [info script]] "audio_parser.tcl"]
    }
    set idx_files [list]
    set base_dir $::Data::ra2dir_abs

    lappend idx_files [file join $base_dir "audio_ra2.idx"]

    if {$::Data::gamemode eq "yr"} {
        lappend idx_files [file join $base_dir "audio_yr.idx"]
    } elseif {$::Data::gamemode eq "ares" || $::Data::gamemode eq "phobos"} {
        lappend idx_files [file join $base_dir "audio_yr.idx"]
        lappend idx_files [file join $base_dir "audio.idx"]
    }

    ::Utils::load_audio_indices $idx_files
}

# --- Shared phase: run sound validation if enabled ---
proc ::Orchestrator::_validate_sounds {} {
    if {!$::Data::sound_validation} return
    if {[info commands ::Validators::validate_sounds] ne ""} {
        ::Validators::validate_sounds
    } else {
        ::Logging::warning "Sound validator not loaded (validators_sound.tcl missing?)"
    }
}

# --- Shared phase: print timing summary ---
proc ::Orchestrator::_print_timing {phases} {
    if {$::Data::quiet_mode} return
    puts "\n---- TIMING ----"
    foreach {label ms} $phases {
        puts [format "  %-20s %6d ms" $label $ms]
    }
    puts "  -------------------------"
    set total_ms 0
    foreach {label ms} $phases { incr total_ms $ms }
    puts [format "  %-20s %6d ms" "Total" $total_ms]
}

# --- Main map checking procedure ---
# Top-level validation entry point.
proc mapcheck {} {
    set timing 0
    if {[info exists ::CLI::cmd_timing]} { set timing $::CLI::cmd_timing }
    set phase_start [clock milliseconds]

    # Load baseline filter BEFORE any checks to suppress known messages
    if {$::CLI::baseline_filter ne ""} {
        ::Logging::load_baseline $::CLI::baseline_filter
    }

    if {!$::Data::quiet_mode} {
        puts "Loading game rules..."
    }
    if {[info exists ::Data::rules_loaded] && $::Data::rules_loaded} {
        # Rules already loaded from cache — skip decryption
        if {!$::Data::quiet_mode} {
            puts "(rules already cached, skipping decryption)"
        }
    } else {
        ::Rules::load_all $::Data::ra2dir_abs $::Data::ra2rul $::Data::ra2ai $::Data::ra2art $::Data::ra2snd $::Data::ra2tm $::Data::ra2eva
        set ::Data::rules_loaded 1
    }
    set t_rules [::Orchestrator::_elapsed $phase_start]
    set phase_start [clock milliseconds]

    ::TagList::validate_all
    set t_tags [::Orchestrator::_elapsed $phase_start]
    set phase_start [clock milliseconds]

    ::Orchestrator::_load_audio
    ::Orchestrator::_validate_sounds
    set t_sound [::Orchestrator::_elapsed $phase_start]
    set phase_start [clock milliseconds]

    set map_path "$::Data::path$::Data::argv"
    if {!$::Data::quiet_mode} {
        puts "\nchecking MAP: $::Data::argv"
    }
    if {[catch {::MapParser::parse_map $map_path} err]} {
        ::Logging::error "Failed to parse map: $err"
        return
    }
    set t_parse [::Orchestrator::_elapsed $phase_start]
    set phase_start [clock milliseconds]

    ::Validators::validate_events
    ::Validators::validate_actions
    ::Validators::validate_scripts
    ::Validators::validate_taskforces
    ::Validators::validate_teamtypes
    ::Validators::validate_triggers_integrity
    set t_validate [::Orchestrator::_elapsed $phase_start]
    set phase_start [clock milliseconds]

    ::Checks::run_all
    set t_checks [::Orchestrator::_elapsed $phase_start]
    set phase_start [clock milliseconds]

    ::AICheck::run_all
    set t_ai [::Orchestrator::_elapsed $phase_start]

    if {$::Data::showunused} {
        ::Validators::report_unused
        ::Validators::report_unused_extended
    }

    if {$::Data::writeanims == 1 && $::Data::animlog ne ""} {
        logputs $::Data::animlog
    }

    if {$timing} {
        ::Orchestrator::_print_timing [list \
            "Rules loading" $t_rules \
            "Tag validation" $t_tags \
            "Sound loading" $t_sound \
            "Map parsing" $t_parse \
            "Validators" $t_validate \
            "Checks" $t_checks \
            "AI cross-checks" $t_ai \
        ]
    }
}

# --- Baseline generation procedure ---
# Runs INI-only checks without a map file to capture known warnings.
# Saves results to baseline.log for use with --baseline-filter.
proc baseline_check {} {
    set timing 0
    if {[info exists ::CLI::cmd_timing]} { set timing $::CLI::cmd_timing }
    set phase_start [clock milliseconds]

    if {!$::Data::quiet_mode} {
        puts "Loading game rules for baseline..."
    }
    ::Rules::load_all $::Data::ra2dir_abs $::Data::ra2rul $::Data::ra2ai $::Data::ra2art $::Data::ra2snd $::Data::ra2tm $::Data::ra2eva
    set ::Data::rules_loaded 1
    set t_rules [::Orchestrator::_elapsed $phase_start]
    set phase_start [clock milliseconds]

    ::TagList::validate_all
    set t_tags [::Orchestrator::_elapsed $phase_start]
    set phase_start [clock milliseconds]

    ::Orchestrator::_load_audio
    ::Orchestrator::_validate_sounds
    set t_sound [::Orchestrator::_elapsed $phase_start]
    set phase_start [clock milliseconds]

    ::Checks::run_all
    set t_checks [::Orchestrator::_elapsed $phase_start]
    set phase_start [clock milliseconds]

    ::AICheck::run_all
    set t_ai [::Orchestrator::_elapsed $phase_start]

    # Save baseline
    set baseline_path "[file join $::app_dir baseline.log]"
    ::Logging::save_baseline $baseline_path

    if {$timing} {
        ::Orchestrator::_print_timing [list \
            "Rules loading" $t_rules \
            "Tag validation" $t_tags \
            "Sound loading" $t_sound \
            "Checks" $t_checks \
            "AI cross-checks" $t_ai \
        ]
    }
}
