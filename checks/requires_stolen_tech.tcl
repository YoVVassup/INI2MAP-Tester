# checks/requires_stolen_tech.tcl
# Validates stolen tech requirement flags that AI ignores
# Game modes: YR/Ares/Phobos (excludes RA2)
# Uses: ::Checks::is_true, ::Checks::get_cached_property

# Helper: check a single techno type for stolen tech flags
proc ::Checks::_st_check {type_name} {
    set allied [::Checks::get_cached_property $type_name "RequiresStolenAlliedTech"]
    set soviet [::Checks::get_cached_property $type_name "RequiresStolenSovietTech"]
    set third  [::Checks::get_cached_property $type_name "RequiresStolenThirdTech"]

    set flags ""
    if {[::Checks::is_true $allied]} { append flags " RequiresStolenAlliedTech=yes" }
    if {[::Checks::is_true $soviet]} { append flags " RequiresStolenSovietTech=yes" }
    if {[::Checks::is_true $third]}  { append flags " RequiresStolenThirdTech=yes" }

    if {$flags eq ""} { return }

    if {[info exists ::Data::buildings($type_name)]} {
        set ai_build_this [::Checks::get_cached_property $type_name "AIBuildThis"]
        if {[::Checks::is_true $ai_build_this]} {
            ::Logging::warning "Building \"$type_name\" has$flags. AI ignores stolen tech requirements and will build this building. Consider adding AIBuildThis=no if you want AI to respect the requirement."
        } else {
            ::Logging::notice "Building \"$type_name\" has$flags. AI ignores stolen tech requirements, but AIBuildThis=no is set, so AI will not build it anyway."
        }
    } else {
        ::Logging::warning "$type_name has$flags. AI ignores stolen tech requirements. Players also cannot build this unit, which may affect multiplayer balance."
    }
}

proc ::Checks::validate_requires_stolen_tech {} {
    upvar ::Data::gamemode gamemode
    upvar ::Data::infantry infantry
    upvar ::Data::vehicles vehicles
    upvar ::Data::aircraft aircraft
    upvar ::Data::buildings buildings

    if {$gamemode eq "ra2"} {
        return
    }

    if {[info exists infantry]} {
        foreach name [array names infantry] { ::Checks::_st_check $name }
    }
    if {[info exists vehicles]} {
        foreach name [array names vehicles] { ::Checks::_st_check $name }
    }
    if {[info exists aircraft]} {
        foreach name [array names aircraft] { ::Checks::_st_check $name }
    }
    if {[info exists buildings]} {
        foreach name [array names buildings] { ::Checks::_st_check $name }
    }
}

::Checks::register_check "validate_requires_stolen_tech"