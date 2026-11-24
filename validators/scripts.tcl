#----------------------------------------------------------------------------------------------------------
# validators_scripts.tcl - Script validation for INI2MAP Tester
# Contains:
#   - validate_scripts procedure with full script command validation
#   - Uses helper procedures and logging from validators_core.tcl
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Post-validation of Scripts
# --------------------------------------------------------------------------
# --- validate_scripts ---
# Validates all script commands and their parameters.
proc ::Validators::validate_scripts {} {
    foreach scr [array names ::Data::scripts] {
        set lnum 0
        if {![info exists ::Data::rawmapdata($scr)]} continue
        foreach curline $::Data::rawmapdata($scr) {
            set kv [::util::_parse_keyval $curline]
            if {$kv eq ""} continue
            set idx [lindex $kv 0]
            if {$idx eq "Name"} {
                set ::Data::scripts($scr) [lindex $kv 1]
                continue
            }
            set curline [split [lindex $kv 1] ","]
            set cmd [lindex $curline 0]
            set value [lindex $curline 1]
            if {![string is integer -strict $cmd] || ![string is integer -strict $value]} {
                ::Logging::error "Script \"$scr\" has non-numeric Script values"
                continue
            }
            incr lnum
            ::Validators::validate_script_code $scr $lnum $cmd
            # Phobos script commands (>= 10000) only exist in phobos mode; in
            # strict RA2 they are rejected before the parameter switch below.
            if {$cmd >= 10000 && $::Data::strictra2 == 1} {
                ::Logging::error "strict RA2 handling mode: Script \"$scr\" includes Phobos action: $cmd"
                continue
            }

            set outstr ""
            # Script command type groups:
            # - Commands with Waypoint (attack, move, patrol, enter, etc.)
            # - Commands with global variable (12, 38)
            # - Commands with local variable (39, 40)
            # - Commands with structure index (46, 47, 58)
            # - Commands with animation (51)
            # - Change house command (20) — special check
            # - Jump command (6) — check for zero
            # - Command 59 (YR enter structure) — checked when strictRA2
            switch -glob -- $cmd {
                1 {
                    set nom [::MapParser::num2wp $value]
                    if {![info exists ::Data::waypoints($nom)]} {
                        set outstr "cannot attack at invalid Waypoint: $value"
                    } else {
                        set ::Data::waypoints($nom) 1
                        if {$::Data::paranoid == 1 && [info exists ::Data::wpcoords($value)]} {
                            set coord $::Data::wpcoords($value)
                            if {![info exists ::Data::foundry($coord)]} {
                                set outstr "attack at Waypoint: $value, does not overlap with any structure at: $coord"
                            }
                        }
                    }
                }
                3 {
                    set nom [::MapParser::num2wp $value]
                    if {![info exists ::Data::waypoints($nom)]} {
                        set outstr "cannot move to invalid Waypoint: $value"
                    } else {
                        set ::Data::waypoints($nom) 1
                        if {$::Data::paranoid == 1 && [info exists ::Data::wpcoords($value)]} {
                            set coord $::Data::wpcoords($value)
                            if {[info exists ::Data::foundry($coord)]} {
                                set outstr "move to Waypoint: $value, overlaps with: $::Data::foundry($coord)"
                            }
                        }
                    }
                }
                6 {
                    if {$value == 0} {
                        set outstr "cannot jump to line 0, line numbers start at 1"
                    }
                }
                12 - 38 {
                    ::Validators::validate_global_var $scr "line: $lnum" $value
                }
                16 {
                    set nom [::MapParser::num2wp $value]
                    if {![info exists ::Data::waypoints($nom)]} {
                        set outstr "cannot patrol to invalid Waypoint: $value"
                    } else {
                        set ::Data::waypoints($nom) 1
                        if {$::Data::paranoid == 1 && [info exists ::Data::wpcoords($value)]} {
                            set coord $::Data::wpcoords($value)
                            if {[info exists ::Data::foundry($coord)]} {
                                set outstr "patrol to Waypoint: $value, overlaps with: $::Data::foundry($coord)"
                            }
                        }
                    }
                }
                20 {
                    if {[string is integer -strict $value]} {
                        if {$value < 0 || ($value >= $::Data::countrycnt && ![info exists ::Data::changeidx($value)])} {
                            set outstr "change house target refers to invalid Country index: $value"
                        }
                    }
                }
                39 - 40 {
                    if {![info exists ::Data::variables($value)]} {
                        set outstr "cannot set/clear undefined local Variable: $value"
                    } else {
                        set ::Data::uvars($value) 1
                    }
                }
                46 - 47 - 58 {
                    if {$value > 196607} {
                        set value [expr {$value - 196608}]
                    } elseif {$value > 131071} {
                        set value [expr {$value - 131072}]
                    } elseif {$value > 65535} {
                        set value [expr {$value - 65536}]
                    }
                    if {![info exists ::Data::bidx($value)]} {
                        set outstr "cannot use Structure, does not exist"
                    }
                }
                51 {
                    if {$value eq ""} {
                        ::Logging::error "Script \"$scr\" (index: $idx) cannot play blank Animation"
                    } elseif {![info exists ::Data::ianims($value)]} {
                        ::Logging::error "Script \"$scr\" (index: $idx) cannot play invalid Animation: $value"
                    } else {
                        append ::Data::animlog "NOTICE -> Script \"$scr\" (index: $idx) plays Animation: $::Data::ianims($value)\n"
                    }
                }
                59 {
                    if {$::Data::strictra2 == 1} {
                        ::Logging::error "strict RA2 handling mode: Script \"$scr\" includes YR action: 59"
                        continue
                    }
                    set nom [::MapParser::num2wp $value]
                    if {![info exists ::Data::waypoints($nom)]} {
                        set outstr "cannot enter structure at invalid Waypoint: $value"
                    } else {
                        set ::Data::waypoints($nom) 1
                        if {[info exists ::Data::wpcoords($value)]} {
                            set coord $::Data::wpcoords($value)
                            if {![info exists ::Data::foundry($coord)]} {
                                set outstr "cannot enter structure at Waypoint: $value, does not overlap with any structure"
                            }
                        }
                    }
                }
                # ---------- Phobos script actions (>= 10000) ----------
                # Attack / move actions whose argument is one of the 37 generic
                # Target Type# groups (the rest of the block uses AITargetTypes).
                1000[0156] - 1001[0145] - 1005[0369] {
                    ::Validators::_phobos_int_range $scr "line: $lnum" $value "Target Type#" 1 37 "Script"
                }
                1000[234789] - 1001[2367] - 1005[124578] - 1006[01] {
                    ::Validators::_phobos_int_range $scr "line: $lnum" $value "AITargetTypes index" 0 2147483647 "Script"
                }
                12002 {
                    # Set Move Action End Mode: 0..2
                    ::Validators::_phobos_int_range $scr "line: $lnum" $value "Move Action End Mode" 0 2 "Script"
                }
                14004 {
                    # Force OnlyTargetHouseEnemy: -1 (disable), 0, 1, 2 (random)
                    ::Validators::_phobos_int_range $scr "line: $lnum" $value "OnlyTargetHouseEnemy" -1 2 "Script"
                }
                16003 {
                    # Randomly Skip Next Action: 0 (never) .. 100 (always)
                    ::Validators::_phobos_int_range $scr "line: $lnum" $value "skip chance" 0 100 "Script"
                }
                16004 {
                    # Pick a Random Script: 0-based AIScriptsList index
                    ::Validators::_phobos_int_range $scr "line: $lnum" $value "AIScriptsList index" 0 2147483647 "Script"
                }
                1800[0-9] - 1801[0-9] - 1802[0-3] {
                    # Edit Variable: high16 holds the int16 operand
                    ::Validators::_phobos_packed_var $scr $lnum $cmd $value "number"
                }
                1802[4-9] - 1803[0-9] - 1804[0-7] {
                    # Edit Variable using Local Variable
                    ::Validators::_phobos_packed_var $scr $lnum $cmd $value "local"
                }
                1804[89] - 1805[0-9] - 1806[0-9] - 1807[01] {
                    # Edit Variable using Global Variable
                    ::Validators::_phobos_packed_var $scr $lnum $cmd $value "global"
                }
                default {
                    if {$cmd > 59 && $::Data::strictra2 == 1} {
                        ::Logging::error "strict RA2 handling mode: Script \"$scr\" includes YR action: $cmd"
                    }
                }
            }
            if {$outstr ne ""} {
                ::Logging::error "Script \"$scr\" (line: $lnum) $outstr"
            }
        }
        # B10: more than 50 actions is unsupported by the game
        # (WAE MapIssueChecker maxScriptActionCount)
        if {$lnum > 50} {
            set sname $scr
            if {[info exists ::Data::scripts($scr)] && $::Data::scripts($scr) ne ""} {
                set sname $::Data::scripts($scr)
            }
            ::Logging::notice "Script '$sname' has more than 50 actions; the game ignores anything past the 50th. Trim the script or split the actions across several scripts."
        }
    }
}