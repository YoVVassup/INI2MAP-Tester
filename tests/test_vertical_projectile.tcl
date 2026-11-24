#----------------------------------------------------------------------------------------------------------
# test_vertical_projectile.tcl - Unit tests for checks/vertical_projectile.tcl
# Tests: Vertical=yes + ROT/Arcing conflict detection
#----------------------------------------------------------------------------------------------------------

package require tcltest
namespace import ::tcltest::*

# --------------------------------------------------------------------------
# Source required modules
# --------------------------------------------------------------------------
set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir "constants.tcl"]
source [file join $script_dir "data.tcl"]
source [file join $script_dir "logging.tcl"]
source [file join $script_dir "checks.tcl"]
source [file join $script_dir "checks" "vertical_projectile.tcl"]

# --------------------------------------------------------------------------
# Helper: reset state between tests
# --------------------------------------------------------------------------
proc reset_state {} {
    array unset ::Data::projectiles
    array unset ::Data::rawmapdata
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} {
    ::Checks::build_index
}

# --------------------------------------------------------------------------
# Test 1: Vertical=yes + ROT=5 — should warn
# --------------------------------------------------------------------------
test vp-rot "Vertical+ROT warns" -body {
    reset_state
    set ::Data::projectiles(0) "Invis"
    set ::Data::rawmapdata(Invis) {Vertical=yes ROT=5}
    setup_index
    ::Checks::validate_vertical_projectile
    expr {$::Logging::warning_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 2: Vertical=yes + Arcing=yes — should error
# --------------------------------------------------------------------------
test vp-arcing "Vertical+Arcing errors" -body {
    reset_state
    set ::Data::projectiles(0) "Invis"
    set ::Data::rawmapdata(Invis) {Vertical=yes Arcing=yes}
    setup_index
    ::Checks::validate_vertical_projectile
    expr {$::Logging::error_count > 0}
} -result 1

# --------------------------------------------------------------------------
# Test 3: Vertical=yes + ROT=0 — should pass
# --------------------------------------------------------------------------
test vp-rot0 "Vertical+ROT=0 is OK" -body {
    reset_state
    set ::Data::projectiles(0) "Invis"
    set ::Data::rawmapdata(Invis) {Vertical=yes ROT=0}
    setup_index
    ::Checks::validate_vertical_projectile
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 4: Vertical=yes without ROT or Arcing — should pass
# --------------------------------------------------------------------------
test vp-ok "Vertical=yes alone is OK" -body {
    reset_state
    set ::Data::projectiles(0) "Invis"
    set ::Data::rawmapdata(Invis) {Vertical=yes}
    setup_index
    ::Checks::validate_vertical_projectile
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Test 5: Vertical=no — should pass
# --------------------------------------------------------------------------
test vp-no "Vertical=no is OK" -body {
    reset_state
    set ::Data::projectiles(0) "Invis"
    set ::Data::rawmapdata(Invis) {Vertical=no ROT=5 Arcing=yes}
    setup_index
    ::Checks::validate_vertical_projectile
    expr {$::Logging::warning_count == 0 && $::Logging::error_count == 0}
} -result 1

# --------------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------------
reset_state

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
cleanupTests
