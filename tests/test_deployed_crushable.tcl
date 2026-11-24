package require tcltest
namespace import ::tcltest::*

set script_dir [file dirname [file dirname [info script]]]
source [file join $script_dir constants.tcl]
source [file join $script_dir data.tcl]
source [file join $script_dir logging.tcl]
source [file join $script_dir checks.tcl]
source [file join $script_dir checks deployed_crushable.tcl]

proc reset_state {} {
    array unset ::Data::rawmapdata
    array unset ::Data::infantry
    array unset ::Data::vehicles
    array unset ::Data::aircraft
    array unset ::Data::buildings
    array unset ::Data::projectiles
    array unset ::Data::warheads
    array unset ::Data::weapons
    array unset ::Data::teamtypes
    array unset ::Data::taskforces
    array unset ::Data::superweapons
    ::Logging::reset_counts
    set ::Data::maperr {}
    set ::Data::logproc ::Logging::logputs_impl
    ::Checks::clear_cache
}

proc setup_index {} { ::Checks::build_index }

test dc-conflict "DeployedCrushable=yes + Crushable=no warns" -body {
    reset_state
    set ::Data::infantry(DEP) ""
    set ::Data::rawmapdata(DEP) {DeployedCrushable=yes Crushable=no}
    setup_index
    ::Checks::validate_deployed_crushable
    expr {$::Logging::warning_count > 0}
} -result 1

test dc-ok "DeployedCrushable=yes + Crushable=yes OK" -body {
    reset_state
    set ::Data::infantry(DEP) ""
    set ::Data::rawmapdata(DEP) {DeployedCrushable=yes Crushable=yes}
    setup_index
    ::Checks::validate_deployed_crushable
    expr {$::Logging::warning_count == 0}
} -result 1

test dc-nodep "DeployedCrushable=no no warning" -body {
    reset_state
    set ::Data::infantry(DEP) ""
    set ::Data::rawmapdata(DEP) {DeployedCrushable=no Crushable=no}
    setup_index
    ::Checks::validate_deployed_crushable
    expr {$::Logging::warning_count == 0}
} -result 1

reset_state
cleanupTests
