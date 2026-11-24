#----------------------------------------------------------------------------------------------------------
# test_orchestrator.tcl - Unit tests for orchestrator.tcl
# Tests: Orchestrator::_elapsed, Orchestrator::_print_timing, mapcheck error handling
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
set test_tmpdir [file join $script_dir "tests" "_tmp"]
file mkdir $test_tmpdir
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]

# Set up minimal CLI namespace
namespace eval ::CLI {
    variable loaded 1
    variable cfg_file ""
    variable cmd_gamemode ""
    variable cmd_no_log_open 0
    variable cmd_quiet 1
    variable cmd_format "text"
    variable cmd_timing 0
    variable map_file ""
    variable batch_mode 0
    variable batch_pattern ""
    variable salt ""
    variable baseline_mode 0
    variable baseline_filter ""
}

set ::app_dir $script_dir
source [file join $script_dir orchestrator.tcl]

proc reset_orch {} {
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    set ::Data::quiet_mode 1
    set ::CLI::cmd_timing 0
    set ::CLI::baseline_filter ""
}

# Create mock namespaces/procs used by mapcheck
proc install_mocks {} {
    foreach ns {::TagList ::Checks ::AICheck ::MapParser ::Validators} {
        if {![namespace exists $ns]} { namespace eval $ns {} }
    }
    proc ::TagList::validate_all {} {}
    proc ::Checks::run_all {} {}
    proc ::AICheck::run_all {} {}
    proc ::Validators::validate_events {} {}
    proc ::Validators::validate_actions {} {}
    proc ::Validators::validate_scripts {} {}
    proc ::Validators::validate_taskforces {} {}
    proc ::Validators::validate_teamtypes {} {}
    proc ::Validators::validate_triggers_integrity {} {}
}

proc remove_mapcheck_mocks {} {
    foreach p {
        ::TagList::validate_all ::Checks::run_all ::AICheck::run_all
        ::MapParser::parse_map
    } {
        if {[info commands $p] ne ""} { rename $p {} }
    }
}

# --------------------------------------------------------------------------
# Test 1: _elapsed returns non-negative integer
# --------------------------------------------------------------------------
test orch-elapsed "elapsed returns non-negative integer" -body {
    reset_orch
    set start [expr {[clock milliseconds] - 100}]
    set result [::Orchestrator::_elapsed $start]
    expr {$result >= 100 && [string is integer -strict $result]}
} -result 1

# --------------------------------------------------------------------------
# Test 2: _elapsed ~0 for immediate call
# --------------------------------------------------------------------------
test orch-elapsed-zero "elapsed near zero for immediate call" -body {
    reset_orch
    set start [clock milliseconds]
    set result [::Orchestrator::_elapsed $start]
    expr {$result >= 0 && $result < 50}
} -result 1

# --------------------------------------------------------------------------
# Test 3: _print_timing suppressed when quiet_mode
# --------------------------------------------------------------------------
test orch-timing-quiet "timing suppressed when quiet" -body {
    reset_orch
    set ::Data::quiet_mode 1
    # Should return without error in quiet mode
    set rc [catch {::Orchestrator::_print_timing [list "Phase" 100]} err]
    list $rc $err
} -result {0 {}}

# --------------------------------------------------------------------------
# Test 4: _print_timing prints in non-quiet mode (no error)
# --------------------------------------------------------------------------
test orch-timing-output "timing prints in non-quiet mode" -body {
    reset_orch
    set ::Data::quiet_mode 0
    set rc [catch {
        ::Orchestrator::_print_timing [list "Phase1" 100 "Phase2" 200]
    } err]
    set ::Data::quiet_mode 1
    list $rc
} -result {0}

# --------------------------------------------------------------------------
# Test 5: _load_audio returns early when sound_check_audio=0
# --------------------------------------------------------------------------
test orch-load-audio-disabled "load_audio returns early when disabled" -body {
    reset_orch
    set ::Data::sound_check_audio 0
    # Should not error even without audio_parser loaded
    set rc [catch {::Orchestrator::_load_audio} err]
    list $rc
} -result {0}

# --------------------------------------------------------------------------
# Test 6: _load_audio returns early when audio already cached
# --------------------------------------------------------------------------
test orch-load-audio-cached "load_audio returns early when cached" -body {
    reset_orch
    set ::Data::sound_check_audio 1
    set ::Data::audio_idx_available 1
    set rc [catch {::Orchestrator::_load_audio} err]
    unset ::Data::audio_idx_available
    list $rc
} -result {0}

# --------------------------------------------------------------------------
# Test 7: _validate_sounds returns early when sound_validation=0
# --------------------------------------------------------------------------
test orch-sounds-disabled "validate_sounds returns early when disabled" -body {
    reset_orch
    set ::Data::sound_validation 0
    set rc [catch {::Orchestrator::_validate_sounds} err]
    list $rc
} -result {0}

# --------------------------------------------------------------------------
# Test 8: _validate_sounds warns when validator not loaded
# --------------------------------------------------------------------------
test orch-sounds-missing-validator "validate_sounds warns when validator missing" -body {
    reset_orch
    set ::Data::sound_validation 1
    # Ensure validate_sounds proc doesn't exist
    if {[info commands ::Validators::validate_sounds] ne ""} {
        # Rename to simulate missing
        rename ::Validators::validate_sounds ::Validators::_save_validate_sounds
    }
    ::Orchestrator::_validate_sounds
    set has_warning 0
    foreach msg $::Data::maperr {
        if {[string match "*Sound validator not loaded*" $msg]} {
            set has_warning 1
        }
    }
    # Restore
    if {[info commands ::Validators::_save_validate_sounds] ne ""} {
        rename ::Validators::_save_validate_sounds ::Validators::validate_sounds
    }
    set has_warning
} -result 1

# --------------------------------------------------------------------------
# Test 9: mapcheck handles parse failure gracefully
# --------------------------------------------------------------------------
test orch-mapcheck-parse-fail "mapcheck handles parse failure" -body {
    reset_orch
    set ::Data::sound_check_audio 0
    set ::Data::sound_validation 0
    set ::Data::showunused 0
    set ::Data::writeanims 0
    set ::Data::animlog ""
    set ::Data::rules_loaded 1
    set ::Data::path [file join $test_tmpdir "_no_such"]
    set ::Data::argv "nonexistent.map"
    set ::Data::quiet_mode 1
    set ::CLI::baseline_filter ""
    set ::CLI::cmd_timing 0
    install_mocks
    proc ::MapParser::parse_map {path} {error "simulated parse failure"}
    set rc [catch {mapcheck} err]
    remove_mapcheck_mocks
    set parse_error_logged 0
    foreach msg $::Data::maperr {
        if {[string match "*Failed to parse map*" $msg]} {
            set parse_error_logged 1
        }
    }
    list $rc $parse_error_logged
} -result {0 1}

# --------------------------------------------------------------------------
# Test 10: mapcheck full flow with mocks
# --------------------------------------------------------------------------
test orch-mapcheck-full "mapcheck full flow with mocks" -body {
    reset_orch
    set ::Data::sound_check_audio 0
    set ::Data::sound_validation 0
    set ::Data::showunused 0
    set ::Data::writeanims 0
    set ::Data::animlog ""
    set ::Data::rules_loaded 1
    set ::Data::path [file join $test_tmpdir "_no_such"]
    set ::Data::argv "test.map"
    set ::Data::quiet_mode 1
    set ::CLI::baseline_filter ""
    set ::CLI::cmd_timing 0
    install_mocks
    proc ::MapParser::parse_map {path} { return }
    set rc [catch {mapcheck} err]
    remove_mapcheck_mocks
    list $rc
} -result {0}

# --------------------------------------------------------------------------
# Cleanup and run
# --------------------------------------------------------------------------
reset_orch
cleanupTests
