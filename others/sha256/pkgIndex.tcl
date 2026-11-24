if {![package vsatisfies [package provide Tcl] 8.5 9]} { return }
package ifneeded sha256 1.0.6 [list source [file join $dir sha256.tcl]]