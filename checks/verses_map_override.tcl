# checks/verses_map_override.tcl
# Warns about Verses being overridden in map INI
# Game modes: RA2/YR/Ares/Phobos
# Uses: None (reads rawmapdata directly)
#
# References:
#   https://modenc.renegadeprojects.com/Verses
#
# Bug:
#   Verses is reset to default (all 100%) after being modified through
#   the map's built-in INI or other means. Starting from Ares 0.1,
#   although it still affects targeting, it still uses the original
#   value when causing damage.

proc ::Checks::validate_verses_map_override {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::rawmapdata rawmapdata

    foreach section [array names rawmapdata] {
        foreach line $rawmapdata($section) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set key [string trim [string range $line 0 [expr {$eq - 1}]]]
            if {[string tolower $key] eq "verses"} {
                if {$gamemode eq "ares" || $gamemode eq "phobos"} {
                    ::Logging::notice "Section \[$section\] overrides Verses in map INI. Verses affects targeting but damage uses original values."
                } else {
                    ::Logging::notice "Section \[$section\] overrides Verses in map INI. Verses values are reset to defaults after map loading - both targeting and damage will use original values."
                }
                return
            }
        }
    }
}

# Register this check
::Checks::register_check "validate_verses_map_override"
