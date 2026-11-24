# checks/map.tcl
# Validates map dimensions against editor limits (FA2, FA2sp, FinalSun, WAE)
#   and checks LocalSize bounds and Theater field casing
# Game modes: RA2/YR/Ares/Phobos
# Uses: None

proc ::Checks::validate_map {} {
    upvar ::Data::rawmapdata rawmapdata
    upvar ::Data::gamemode gamemode

    # ---- Map Size Validation ----
    if {[info exists rawmapdata(Map)]} {
        set width 0
        set height 0
        set localsize 0
        set localsize_width 0
        set localsize_height 0

        # Parse Map section
        foreach line $rawmapdata(Map) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set key [string trim [string range $line 0 [expr {$eq - 1}]]]
            set val [string trim [string range $line [expr {$eq + 1}] end]]

            switch -- [string tolower $key] {
                "size" {
                    set coords [split $val ","]
                    if {[llength $coords] >= 4} {
                        set width [lindex $coords 2]
                        set height [lindex $coords 3]
                    }
                }
                "localsize" {
                    set coords [split $val ","]
                    if {[llength $coords] >= 4} {
                        set localsize_width [lindex $coords 2]
                        set localsize_height [lindex $coords 3]
                        set localsize 1
                    }
                }
            }
        }

        # Skip validation if size parameters are missing or malformed
        if {$width > 0 && $height > 0} {
            set width [expr {$width}]
            set height [expr {$height}]

            # --- Generic engine limits (RA2/YR) ---
            if {$width + $height > 512} {
                ::Logging::warning "Map dimensions: width=$width, height=$height. The sum exceeds 512, which may cause issues with OverlayPack data structure."
            }

            # --- FinalAlert2 v1.02 limits ---
            if {$width < 16 || $width > 200 || $height < 16 || $height > 200} {
                ::Logging::notice "Map dimensions: width=$width, height=$height. Standard FinalAlert2 v1.02 only supports dimensions between 16 and 200."
            }

            # --- FA2sp v1.6.2 limits ---
            if {$width > 256 || $height > 256} {
                ::Logging::notice "Map dimensions: width=$width, height=$height. FA2sp v1.6.2 supports dimensions up to 256."
            }

            # --- Patched FA2 / FinalSun limits ---
            if {$width < 20 || $height < 20} {
                ::Logging::notice "Map dimensions: width=$width, height=$height. Patched FA2/FinalSun require minimum dimensions of 20."
            }
            if {$width > 492 || $height > 492} {
                ::Logging::notice "Map dimensions: width=$width, height=$height. Patched FA2/FinalSun support maximum dimensions of 492."
            }

            # --- World-Altering Editor limits ---
            if {$width < 50 || $height < 50} {
                ::Logging::notice "Map dimensions: width=$width, height=$height. World-Altering Editor requires minimum dimensions of 50."
            }
            if {$width > 273} {
                ::Logging::notice "Map dimensions: width=$width. World-Altering Editor supports a maximum width of 273."
            }

            # --- LocalSize check (viewable area) ---
            if {$localsize} {
                if {$localsize_width > $width || $localsize_height > $height} {
                    ::Logging::error "LocalSize ($localsize_width x $localsize_height) exceeds actual map size ($width x $height). This will cause in-game crashes or graphical issues."
                }
                if {$localsize_width + 2 > $width || $localsize_height + 2 > $height} {
                    ::Logging::warning "LocalSize ($localsize_width x $localsize_height) is too close to map borders. At least 1 cell of buffer is required for reinforcements and aircraft turning."
                }
            }
        }
    }

    # ---- Theater Validation ----
    if {[info exists rawmapdata(Map)]} {
        set theater ""
        foreach line $rawmapdata(Map) {
            set eq [string first "=" $line]
            if {$eq == -1} continue
            set key [string trim [string range $line 0 [expr {$eq - 1}]]]
            if {[string tolower $key] eq "theater"} {
                set theater [string trim [string range $line [expr {$eq + 1}] end]]
                break
            }
        }

        if {$theater ne ""} {
            # List of valid theater values for RA2 / YR
            set valid_theaters { TEMPERATE SNOW URBAN DESERT NEWURBAN LUNAR }
            set theater_upper [string toupper $theater]

            if {$theater_upper ni $valid_theaters} {
                ::Logging::warning "Unknown Theater value: \"$theater\". Valid options are: TEMPERATE, SNOW, URBAN, DESERT, NEWURBAN, LUNAR."
            } elseif {$theater ne $theater_upper} {
                ::Logging::notice "Theater value is mixed/lowercase: \"$theater\". Official FinalAlert2 only supports uppercase, which may cause editor incompatibility."
            }
        }
    }
}

::Checks::register_check "validate_map"