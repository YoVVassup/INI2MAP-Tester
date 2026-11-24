#----------------------------------------------------------------------------------------------------------
# aicheck.tcl - AI cross-check module aggregator
#----------------------------------------------------------------------------------------------------------
# Loads and runs all AI cross-check submodules from the aicheck/ directory.
# Based on aicheck9 by G-E, adapted for INI2MAP Tester.
#
# Checks performed:
#   - VoxelAnim property validation
#   - ART data validation (missing ART for units)
#   - Prerequisite building validation
#   - Weapon/Warhead/Projectile cross-referencing
#   - Animation reference validation
#   - [Colors] section validation
#   - 100 Unit Bug detection
#----------------------------------------------------------------------------------------------------------

namespace eval ::AICheck {
    variable loaded 0
}

# Store directory at load time
set ::AICheck::script_dir [file dirname [info script]]

# Source submodules
source [file join $::AICheck::script_dir "core.tcl"]
source [file join $::AICheck::script_dir "voxel_check.tcl"]
source [file join $::AICheck::script_dir "art_check.tcl"]
source [file join $::AICheck::script_dir "prereq_check.tcl"]
source [file join $::AICheck::script_dir "ref_check.tcl"]
source [file join $::AICheck::script_dir "color_check.tcl"]

# --- Run all AI cross-checks ---
proc ::AICheck::run_all {} {
    if {[info exists ::Data::quiet_mode] && !$::Data::quiet_mode} {
        puts "\nRunning AI cross-checks..."
    }

    foreach check {check_voxelanims check_art_data check_prerequisites check_references check_colors} {
        if {[catch {::AICheck::$check} err]} {
            ::Logging::error "AI cross-check '$check' failed: $err"
        }
    }
}
