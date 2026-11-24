#----------------------------------------------------------------------------------------------------------
# aicheck/color_check.tcl - [Colors] section validation
#----------------------------------------------------------------------------------------------------------
# Validates the structure of the [Colors] section: correct order, valid values.
#----------------------------------------------------------------------------------------------------------

proc ::AICheck::check_colors {} {
    if {![info exists ::Data::rulesdata(Colors)]} return

    set color_names {
        LightGold Gold LightGrey Grey Red DarkRed Orange Magenta Purple
        LightBlue DarkBlue NeonBlue DarkSky Green DarkGreen NeonGreen Yellow
    }
    set idx 0

    foreach line $::Data::rulesdata(Colors) {
        set kv [::util::_parse_keyval $line]
        if {$kv eq ""} continue
        set pfx [lindex $kv 0]
        set val [lindex $kv 1]

        # Check color name is in expected order
        if {$idx < [llength $color_names]} {
            set expected [lindex $color_names $idx]
            if {$pfx ne $expected} {
                ::Logging::notice "\[Colors\] color $idx should be \"$expected\" but found \"$pfx\""
            }
        }
        incr idx

        # Check color value format (R,G,B)
        set parts [split $val ","]
        if {[llength $parts] != 3} {
            ::Logging::warning "\[Colors\] $pfx has invalid color format: $val (expected R,G,B)"
        } else {
            foreach part $parts {
                set part [string trim $part]
                if {![string is integer -strict $part] || $part < 0 || $part > 255} {
                    ::Logging::warning "\[Colors\] $pfx has invalid color value: $part (expected 0-255)"
                }
            }
        }
    }
}
