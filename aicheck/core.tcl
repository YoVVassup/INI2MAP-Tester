#----------------------------------------------------------------------------------------------------------
# aicheck/core.tcl - Core utilities for AI cross-checking
#----------------------------------------------------------------------------------------------------------

namespace eval ::AICheck {
    variable loaded 0
}

# --- Helper: check if value is integer ---
proc ::AICheck::_is_int {val} {
    string is integer -strict $val
}

# --- Helper: check if value is float ---
proc ::AICheck::_is_float {val} {
    string is double -strict $val
}
