#----------------------------------------------------------------------------------------------------------
# map_parser/load_map.tcl - Map file loading and basic section removal
# Contains:
#   - load_map_file: reads map file into ::Data::rawmapdata, removes binary sections
#----------------------------------------------------------------------------------------------------------
# All data is accessed directly from ::Data namespace
#----------------------------------------------------------------------------------------------------------

namespace eval ::MapParser {
    # Guard against double loading
    if {[info exists ::MapParser::load_map_loaded]} { return }
    variable load_map_loaded 1
    # Known binary sections: skip their content entirely (can be multi-MB base64 data)
    variable binary_sections {
        IsoMapPack5 OverlayDataPack OverlayPack Preview PreviewPack SpecialFlags
    }
}

# --- load_map_file ---
# Read a map file into the rawmapdata array, stripping binary and digest sections.
proc ::MapParser::load_map_file {filename} {
    if {[catch {open $filename r} of error]} {
        logputs "\n>> $filename not readable: $error"
        return -code error "Cannot open map file: $error"
    }
    # Check for UTF-8 BOM (EF BB BF) at the beginning
    set bom [read $of 3]
    if {[string equal $bom "\xEF\xBB\xBF"]} {
        puts "INFO: UTF-8 BOM detected and skipped in $filename"
    } else {
        seek $of 0 start
    }
    set curtag "default"
    set skip_section 0
    if {[catch {
        while {[gets $of curline] >= 0} {
            # Fast path: if inside a binary/known-skipped section, only look for next header
            if {$skip_section} {
                if {[string index [string trim $curline] 0] eq "\["} {
                    set skip_section 0
                } else {
                    continue
                }
            }

            set cc [string first ";" $curline]
            if {$cc == 0} continue
            if {$cc != -1} {set curline [string range $curline 0 [expr {$cc - 1}]]}
            set curline [string trim $curline]
            if {$curline eq ""} continue

            # Skip lines that are neither section headers nor key=value pairs
            if {[string first "=" $curline] == -1 && [string index $curline 0] ne "\["} continue

            if {[string index $curline 0] eq "\["} {
                set cc [string first "\]" $curline]
                if {$cc == -1} continue
                set curtag [string range $curline 1 [expr {$cc - 1}]]
                if {$curtag eq "Digest"} {
                    set curtag "__digest__"
                    set skip_section 1
                } elseif {$curtag in $::MapParser::binary_sections} {
                    set skip_section 1
                }
                continue
            }
            lappend ::Data::rawmapdata($curtag) $curline
        }
    } read_err]} {
        catch {close $of}
        error "Error reading $filename: $read_err"
    }
    close $of

    # Safety: remove any binary sections that somehow got through
    foreach sec $::MapParser::binary_sections {
        if {[info exists ::Data::rawmapdata($sec)]} {unset ::Data::rawmapdata($sec)}
    }
    if {[info exists ::Data::rawmapdata(__digest__)]} {unset ::Data::rawmapdata(__digest__)}
}