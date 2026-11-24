# checks/unit_crate_type_base_unit.tcl
# Validates UnitCrateType in [CrateRules] against [General]→BaseUnit
# Game modes: RA2/YR/Ares/Phobos
# Uses: ::Checks::get_section_property
#
# References:
#   https://modenc.renegadeprojects.com/UnitCrateType
#
# Bug:
#   If UnitCrateType in [CrateRules] is set to a type that doesn't match
#   [General]→BaseUnit, FreeMCV crate triggers create an infinite loop:
#   FreeMCV forces next crate to Unit type, but UnitCrateType grants a
#   non-MCV unit. The player never gets an MCV, FreeMCV keeps triggering,
#   and every subsequent crate grants the same wrong unit.

proc ::Checks::validate_unit_crate_type_base_unit {} {
    set unit_crate [::Checks::get_section_property "CrateRules" "UnitCrateType"]
    if {$unit_crate eq ""} return

    set base_unit [::Checks::get_section_property "General" "BaseUnit"]
    if {$base_unit eq ""} {
        ::Logging::warning "\[CrateRules\]→UnitCrateType=\"$unit_crate\" is set but \[General\]→BaseUnit is not defined. If FreeMCV is used, this may create an infinite loop where crates never grant an MCV."
        return
    }

    if {[string tolower $unit_crate] ne [string tolower $base_unit]} {
        ::Logging::warning "\[CrateRules\]->UnitCrateType=\"$unit_crate\" does not match \[General\]->BaseUnit=\"$base_unit\". If FreeMCV crate triggers are used, crates will never grant an MCV and every subsequent crate will grant \"$unit_crate\" instead."
    }
}

# Register this check
::Checks::register_check "validate_unit_crate_type_base_unit"
