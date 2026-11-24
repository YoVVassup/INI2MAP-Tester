#----------------------------------------------------------------------------------------------------------
# utils.tcl - Shared utility procs
#----------------------------------------------------------------------------------------------------------

namespace eval ::util {}

# Parse a key=value line. Returns list of {key value} or empty string.
proc ::util::_parse_keyval {line} {
    set eq [string first "=" $line]
    if {$eq == -1} { return "" }
    set pfx [string trim [string range $line 0 [expr {$eq - 1}]]]
    set val [string trim [string range $line [expr {$eq + 1}] end]]
    return [list $pfx $val]
}
