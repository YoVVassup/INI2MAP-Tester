# checks/state_ai_advance.tcl
# Validates StateAIAdvance value in [Particles]
# Game modes: All (RA2/YR/Ares/Phobos)
# Uses: ::Checks::get_cached_property
#
# Reference: https://modenc.renegadeprojects.com/StateAIAdvance
# Bug: Unreasonable values trigger EIP#0062C67E
# Default: 1

proc ::Checks::validate_state_ai_advance {} {
    # Check [Particles] section
    foreach section {Particles} {
        if {![info exists ::Data::rulesdata($section)]} continue

        foreach line $::Data::rulesdata($section) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set pfx [string trim [string range $line 0 [expr {$eq-1}]]]
            set val [string trim [string range $line [expr {$eq+1}] end]]

            if {$pfx ne "StateAIAdvance" || $val eq ""} continue

            # Check for non-numeric value
            if {![string is integer -strict $val]} {
                ::Logging::warning "\[Particles\] StateAIAdvance=\"$val\" is not a valid integer."
                continue
            }

            # Warn about zero or negative values
            if {$val <= 0} {
                ::Logging::warning "\[Particles\] StateAIAdvance=$val will trigger EIP crash."
                continue
            }

            # Warn about extremely large values
            if {$val > 100} {
                ::Logging::notice "\[Particles\] StateAIAdvance=$val is very large. Values > 100 may cause issues."
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_state_ai_advance"
