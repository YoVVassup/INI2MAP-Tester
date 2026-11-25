#----------------------------------------------------------------------------------------------------------
# logging.tcl - Logging procedures for INI2MAP Tester
#----------------------------------------------------------------------------------------------------------
# Provides logputs (write to log), logwrite (save log to file), and log file opening.
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Logging::loaded]} { return }
namespace eval ::Logging {
    variable loaded 1
    variable error_count 0
    variable warning_count 0
    variable notice_count 0
    variable baseline_messages {}
    variable baseline_loaded 0
    variable suppressed_count 0
}

# --- Internal log handler ---
# Appends a single message to the ::Data::maperr list and counts by severity.
# When baseline filter is active, suppresses messages that match the baseline.
proc ::Logging::logputs_impl {msg} {
    if {[::Logging::_is_baseline_match $msg]} {
        incr ::Logging::suppressed_count
        return
    }

    lappend ::Data::maperr $msg
    if {[string match "ERROR ->*" $msg]} {
        incr ::Logging::error_count
    } elseif {[string match "WARNING ->*" $msg]} {
        incr ::Logging::warning_count
    } elseif {[string match "NOTICE ->*" $msg]} {
        incr ::Logging::notice_count
    }
}

# --- Reset counters (called at start of each validation run) ---
proc ::Logging::reset_counts {} {
    set ::Logging::error_count 0
    set ::Logging::warning_count 0
    set ::Logging::notice_count 0
    set ::Logging::suppressed_count 0
}

# --- Load baseline file for filtering ---
proc ::Logging::load_baseline {filepath} {
    variable baseline_messages
    variable baseline_loaded

    if {![file exists $filepath]} {
        puts stderr "ERROR: Baseline file not found: $filepath"
        set baseline_loaded 0
        return 0
    }

    set fh [open $filepath r]
    set baseline_messages [list]
    while {[gets $fh line] >= 0} {
        set trimmed [string trim $line]
        if {$trimmed eq "" || [string index $trimmed 0] eq "#"} continue
        lappend baseline_messages $trimmed
    }
    close $fh

    set baseline_loaded 1
    if {!$::Data::quiet_mode} {
        puts "Baseline loaded: [llength $baseline_messages] messages from $filepath"
    }
    return 1
}

# --- Save baseline to file ---
proc ::Logging::save_baseline {filepath} {
    variable error_count
    variable warning_count
    variable notice_count

    if {[catch {open $filepath w} fh]} {
        puts stderr "ERROR: Cannot write baseline file: $fh"
        return 0
    }

    puts $fh "# INI2MAP Tester baseline"
    puts $fh "# Generated: [clock format [clock seconds]]"
    puts $fh "# Errors: $error_count, Warnings: $warning_count, Notices: $notice_count"
    puts $fh "#"
    puts $fh "# This file is auto-generated. Do not edit manually."
    puts $fh "# Use --baseline to regenerate."
    puts $fh ""

    foreach line $::Data::maperr {
        puts $fh $line
    }
    close $fh

    if {!$::Data::quiet_mode} {
        puts "Baseline saved: [llength $::Data::maperr] messages to $filepath"
    }
    return 1
}

# --- Check if a message matches any baseline entry ---
proc ::Logging::_is_baseline_match {msg} {
    variable baseline_messages
    variable baseline_loaded

    if {!$baseline_loaded} { return 0 }

    foreach baseline $baseline_messages {
        if {$msg eq $baseline} {
            return 1
        }
    }
    return 0
}

# --- Get exit code based on severity ---
# Returns: 0 = no issues, 1 = warnings only, 2 = errors present
proc ::Logging::get_exit_code {} {
    if {$::Logging::error_count > 0} { return 2 }
    if {$::Logging::warning_count > 0} { return 1 }
    return 0
}

# --- Public logging command ---
# Can be overridden by setting ::Data::logproc to a different procedure name.
proc logputs {msg} {
    $::Data::logproc $msg
}

# --- Unified logging API ---
# All logging should go through these procs for consistent formatting.
proc ::Logging::error {msg} {
    logputs "ERROR -> $msg"
}

proc ::Logging::warning {msg} {
    logputs "WARNING -> $msg"
}

proc ::Logging::notice {msg} {
    logputs "NOTICE -> $msg"
}

# --- Write accumulated log messages to mission.log ---
# Saves the log file and optionally opens it in the default application.
# Supports text and JSON output formats via ::CLI::cmd_format.
# Optional logname lets batch mode save a per-map log (e.g. "x.map.log").
proc logwrite {{logname "mission.log"}} {
    set logpath "[set ::Data::path]$logname"
    if {$::Data::savelog} {
        set mode "a+"
    } else {
        set mode "w"
        catch {file delete -force $logpath}
    }
    if {[catch {open $logpath $mode} fh]} {
        puts stderr "\n>> ERROR: Cannot write to log file: $fh"
    } else {
        # Count by severity
        set errors 0
        set warnings 0
        set notices 0
        foreach line $::Data::maperr {
            if {[string match "ERROR ->*" $line]} { incr errors }
            if {[string match "WARNING ->*" $line]} { incr warnings }
            if {[string match "NOTICE ->*" $line]} { incr notices }
        }
        set processing_time [expr {[clock milliseconds] - $::Data::started}]

        if {[info exists ::CLI::cmd_format] && $::CLI::cmd_format eq "json"} {
            # JSON output
            if {[catch {
                puts $fh "{"
                set safe_map [string map [list "\\" "\\\\" "\"" "\\\"" "\n" "\\n" "\t" "\\t" "\r" "\\r"] $::Data::argv]
                puts $fh "  \"map\": \"$safe_map\","
                puts $fh "  \"summary\": {"
                puts $fh "    \"errors\": $errors,"
                puts $fh "    \"warnings\": $warnings,"
                puts $fh "    \"notices\": $notices"
                puts $fh "  },"
                puts $fh "  \"processing_time_ms\": $processing_time,"
                puts $fh "  \"messages\": \["
                set first 1
                foreach line $::Data::maperr {
                    # Determine severity
                    set severity "info"
                    if {[string match "ERROR ->*" $line]} { set severity "error" }
                    if {[string match "WARNING ->*" $line]} { set severity "warning" }
                    if {[string match "NOTICE ->*" $line]} { set severity "notice" }
                    # Extract message (remove prefix)
                    set msg [string map {"ERROR -> " "" "WARNING -> " "" "NOTICE -> " "" "INFO -> " ""} $line]
                    set msg [string map [list "\\" "\\\\" "\"" "\\\"" "\n" "\\n" "\t" "\\t" "\r" "\\r"] $msg]
                    if {!$first} { puts $fh "," }
                    set first 0
                    puts -nonewline $fh "    \{\"severity\": \"$severity\", \"message\": \"$msg\"\}"
                }
                puts $fh ""
                puts $fh "  \]"
                puts $fh "}"
            } write_err]} {
                ::Logging::error "Error writing JSON log: $write_err"
            }
            catch {close $fh}
        } else {
            # Text output (default)
            if {[catch {
                puts $fh "\n\n---- MISSION REPORT FOR [set ::Data::argv] ----"
                foreach line $::Data::maperr {
                    puts $fh $line
                }
                puts $fh ""
                puts $fh "---- SUMMARY ----"
                puts $fh "Errors:   $errors"
                puts $fh "Warnings: $warnings"
                puts $fh "Notices:  $notices"
                if {$::Logging::suppressed_count > 0} {
                    puts $fh "Suppressed: $::Logging::suppressed_count (baseline filter)"
                }
                puts $fh "\nTotal processing time: ${processing_time}ms"
            } write_err]} {
                ::Logging::error "Error writing text log: $write_err"
            }
            catch {close $fh}
        }
    }

    if {!$::Data::quiet_mode} {
        puts "Log saved to: [file normalize $logpath]"
    }

    if {$::Data::auto_open_log && [file exists $logpath] && [file isfile $logpath]} {
        ::Logging::_open_log [file normalize $logpath]
    }
}

# --- Open log file in default application ---
# Sanitizes path to prevent command injection via special characters.
proc ::Logging::_open_log {abs_logpath} {
    # Validate path: only alphanumerics, spaces, dots, underscores, hyphens, slashes, colons, parens
    # Explicitly excludes: backtick, &, |, %, ^, !, [, ], {, }, <, >, ;, ", '
    if {[regexp {[|&;<>\"'`\[\]{}%\^!]} $abs_logpath]} {
        if {!$::Data::quiet_mode} { puts "  (auto-open skipped: path contains unsafe characters)" }
        return
    }

    switch -- $::tcl_platform(os) {
        "Windows NT" - "Windows" {
            if {[catch {exec cmd /c start "" $abs_logpath} err]} {
                if {!$::Data::quiet_mode} { puts "  (auto-open failed: $err)" }
            }
        }
        "Darwin" {
            if {[catch {exec open $abs_logpath} err]} {
                if {!$::Data::quiet_mode} { puts "  (auto-open failed: $err)" }
            }
        }
        default {
            set open_cmd [auto_execok xdg-open]
            if {$open_cmd ne ""} {
                if {[catch {exec {*}$open_cmd $abs_logpath} err]} {
                    if {!$::Data::quiet_mode} { puts "  (auto-open failed: $err)" }
                }
            } else {
                set open_cmd [auto_execok gnome-open]
                if {$open_cmd ne ""} {
                    if {[catch {exec {*}$open_cmd $abs_logpath} err]} {
                        if {!$::Data::quiet_mode} { puts "  (auto-open failed: $err)" }
                    }
                } else {
                    if {!$::Data::quiet_mode} { puts "  (auto-open not supported on this system)" }
                }
            }
        }
    }
}
