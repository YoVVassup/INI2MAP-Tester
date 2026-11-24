#----------------------------------------------------------------------------------------------------------
# validators.tcl - Main validation module (aggregator)
#----------------------------------------------------------------------------------------------------------
# This file loads all validation sub-modules from the "validators/" subdirectory.
#----------------------------------------------------------------------------------------------------------

set script_dir [file dirname [info script]]

# Load core first (has guard against double loading)
source [file join $script_dir "validators" "core.tcl"]

# Load all other modules (they should NOT source core.tcl themselves)
source [file join $script_dir "validators" "actions.tcl"]
source [file join $script_dir "validators" "events.tcl"]
source [file join $script_dir "validators" "scripts.tcl"]
source [file join $script_dir "validators" "taskforce_teamtype.tcl"]
source [file join $script_dir "validators" "trigger_integrity.tcl"]
source [file join $script_dir "validators" "report_unused.tcl"]
source [file join $script_dir "validators" "report_unused_extended.tcl"]
source [file join $script_dir "validators" "sound.tcl"]

return
