#----------------------------------------------------------------------------------------------------------
# rules_parser/core.tcl - Core helper functions for INI parsing
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Rules::core_loaded]} { return }
set ::Rules::core_loaded 1

# --------------------------------------------------------------------------
# Helper: strip comments and trim whitespace from a raw line
# Returns empty string if line is blank or comment-only
# --------------------------------------------------------------------------
proc ::Rules::_strip_line {rawline} {
    set cc [string first ";" $rawline]
    if {$cc == 0} { return "" }
    if {$cc != -1} { set rawline [string range $rawline 0 [expr {$cc - 1}]] }
    set line [string trim $rawline]
    return $line
}

# --------------------------------------------------------------------------
# Helper: parse section header [SectionName]
# Returns section name if line is a header, empty string otherwise
# --------------------------------------------------------------------------
proc ::Rules::_parse_section {line} {
    if {[string index $line 0] ne "\["} { return "" }
    set end [string first "\]" $line]
    if {$end == -1} { return "" }
    return [string range $line 1 [expr {$end - 1}]]
}

# --------------------------------------------------------------------------
# Helper: decrypt and decode an INI file
# Returns the decoded content as a string
# --------------------------------------------------------------------------
proc ::Rules::_load_ini {filepath} {
    if {[catch {set content [decrypt_ini_to_string $filepath]} err]} {
        puts stderr "ERROR: Cannot decrypt [file tail $filepath]: $err"
        return -code error "Cannot decrypt [file tail $filepath]: $err"
    }
    if {$content eq ""} {
        puts stderr "ERROR: [file tail $filepath] decrypted to empty content"
        return -code error "Empty content from [file tail $filepath]"
    }
    # Strip UTF-8 BOM if present (as U+FEFF char or raw byte sequence)
    if {[string index $content 0] eq "\uFEFF"} {
        set content [string range $content 1 end]
    } elseif {[string range $content 0 2] eq "\xEF\xBB\xBF"} {
        set content [string range $content 3 end]
    }
    puts ">> [file tail $filepath] (decrypted)"
    return $content
}
