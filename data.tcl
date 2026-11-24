#----------------------------------------------------------------------------------------------------------
# data.tcl - Central data storage for INI2MAP Tester
# All global state resides in the ::Data namespace to avoid pollution.
# Variables are organized by category with documentation.
#----------------------------------------------------------------------------------------------------------

namespace eval ::Data {
    # ==========================================================================
    # RULES DATA (populated by rules_parser/)
    # ==========================================================================

    # --- Type registries (name -> "" or name -> index) ---
    variable infantry          ; # InfantryTypes: name -> ""
    variable vehicles          ; # VehicleTypes: name -> ""
    variable aircraft          ; # AircraftTypes: name -> ""
    variable buildings         ; # BuildingTypes: name -> ""
    variable vanims            ; # VoxelAnims: index -> name
    variable anims             ; # Animations: name -> ""
    variable ianims            ; # Animations: index -> name
    variable particles         ; # Particles: index -> name
    variable particlesys       ; # ParticleSystems: index -> name
    variable terrains          ; # TerrainTypes: name -> ""
    variable smudges           ; # SmudgeTypes: name -> ""
    variable countries         ; # Countries: name -> index
    variable superweapons      ; # SuperWeaponTypes: index -> name
    variable weapons           ; # WeaponTypes: index -> name
    variable warheads          ; # Warheads: index -> name
    variable projectiles       ; # Projectiles: index -> name
    variable attacheffects     ; # AttachEffectTypes (Phobos): index -> name
    variable radiationtypes    ; # RadiationTypes (Phobos): index -> name
    variable shieldtypes       ; # ShieldTypes (Phobos): index -> name

    # --- Armor type registry (Ares/Phobos) ---
    variable armortypes        ; # ArmorTypes: name -> parent (lowercase)
    variable armortypes_order  ; # ArmorTypes: insertion order list

    # --- Index registries (index -> name) ---
    variable bidx              ; # BuildingTypes: index -> name
    variable uidx              ; # VehicleTypes: index -> name
    variable iidx              ; # InfantryTypes: index -> name
    variable aidx              ; # AircraftTypes: index -> name

    # --- Property maps ---
    variable owners            ; # section -> Owner value
    variable art               ; # building -> Image value
    variable harvy             ; # section -> 1 (has Harvester=yes)
    variable agent             ; # section -> 1 (has Agent=yes)
    variable assaulter         ; # section -> 1 (has Assaulter=yes)
    variable engineer          ; # section -> 1 (has Engineer=yes)
    variable transport         ; # section -> 1 (has Passengers > 0)
    variable paddies           ; # PadAircraft/HarvesterUnit values

    # --- Aggregated type sets ---
    variable allunits          ; # infantry + vehicles + aircraft (name -> "")
    variable allobjects        ; # allunits + buildings (name -> "")

    # --- Variable names ---
    variable globalvars        ; # VariableNames: index -> name
    variable variables         ; # Local variable names from map

    # --- Raw INI data ---
    variable rulesdata         ; # section -> list of lines (all rules sections)
    variable rawmapdata        ; # section -> list of lines (all map sections)

    # ==========================================================================
    # MAP DATA (populated by map_parser/)
    # ==========================================================================

    # --- Trigger system ---
    variable triggers          ; # trigger_id -> trigger definition string
    variable events            ; # trigger_id -> list of events
    variable actions           ; # trigger_id -> action string
    variable tags              ; # tag_id -> tag name
    variable teamtypes         ; # team_id -> team definition
    variable scripts           ; # script_id -> script name
    variable taskforces        ; # tf_id -> taskforce definition

    # --- AI triggers ---
    variable local_aitriggers  ; # local AI trigger data
    variable aitriggertypes    ; # AI trigger type names

    # --- Waypoints ---
    variable waypoints         ; # waypoint_letter -> 0|1 (0=defined, 1=used)
    variable wpcoords          ; # waypoint_number -> "x,y"

    # --- Houses and countries ---
    variable houses            ; # house data from [Houses] section
    variable changeidx         ; # country index mapping
    variable mphouses          ; # multiplayer house indices
    variable parent            ; # house -> parent country

    # --- Per-house data for the WAE event-32 check (B24) ---
    # Captured while the house sections are still live (process_house_data).
    variable house_country     ; # house section -> Country= value
    variable house_playerctl   ; # house section -> 1 (PlayerControl=yes)
    variable house_basenodes   ; # house section -> list of base node building types
    variable house_units       ; # house section -> preplaced [Units] type names

    # --- Placed objects ---
    variable mapunits          ; # placed unit data
    variable tfowner           ; # taskforce owner mapping
    variable artery            ; # building -> foundation format ("1x1", "3x2")
    variable terrain_foundation; # terrain -> foundation format
    variable foundry           ; # "x,y" -> building name (overlap detection)
    variable unitcoord         ; # unit -> coordinate mapping
    variable uhouse            ; # unit -> house
    variable ubldg             ; # unit -> building
    variable uteam             ; # unit -> team
    variable utask             ; # unit -> taskforce
    variable uscript           ; # unit -> script

    # --- Usage tracking (for "unused" reports) ---
    variable uvars             ; # local_var_index -> 1 (used in scripts)
    variable uglobal           ; # global_var_index -> 1 (used in triggers)

    # --- Other map data ---
    variable sndlist           ; # sound names from sound.ini
    variable movies            ; # movie index -> movie name
    variable themes_by_name    ; # theme_name -> 1
    variable dialogs_by_name   ; # dialog_name -> 1

    # ==========================================================================
    # SOUND VALIDATION (populated by rules_parser/load_sound.tcl)
    # ==========================================================================

    variable sound_params           ; # dict: sound_name -> dict of sound.ini key/value pairs
    variable sound_resources        ; # dict: sound_name -> list of resource names (wav)
    variable sound_defaults         ; # dict: default sound parameters from [Defaults]
    variable used_sounds_rules      ; # array: sound_name -> 1 (used in rules.ini)
    variable used_sounds_art        ; # array: sound_name -> 1 (used in art.ini)
    variable audio_idx_available    ; # boolean: 1 if audio.idx loaded successfully
    variable audio_resources        ; # array: resource_name -> 1 (exists in audio.idx)
    variable audio_resource_count   ; # total number of unique resources in audio.idx

    # ==========================================================================
    # SCALAR CONFIGURATION FLAGS
    # ==========================================================================

    # --- Game mode ---
    variable gamemode "ares"        ; # "ra2", "yr", "ares", "phobos"
    variable strictra2 0            ; # 1 = strict RA2 compatibility mode
    variable countrycnt 0           ; # total number of countries loaded

    # --- Map properties ---
    variable mismap 0               ; # 1 = not a multiplayer map (campaign/single)
    variable mhouses 0              ; # 1 = multiplayer houses present
    variable mpsonly 0              ; # 1 = [Basic] MultiplayerOnly=yes (WAE IsLikelyMultiplayer gate)
    variable housecnt 0             ; # number of [Houses] entries (WAE Houses.Count)
    variable houselist {}           ; # house sections in [Houses] order (WAE map.Houses order)
    variable newini 0               ; # 1 = NewINIFormat=4 (new INI format)
    variable theme ""               ; # map theater (SNOW, TEMPERATE, URBAN, etc.)
    variable ignoreglobals 0        ; # 1 = IgnoreGlobalAITriggers=yes

    # --- Map geometry ---
    variable maspect 0              ; # map aspect ratio
    variable corner                 ; # array: tly, bry, tlx, brx, etc.
    variable minx 0                 ; # minimum playable X
    variable miny 0                 ; # minimum playable Y
    variable maxx 0                 ; # maximum playable X
    variable maxy 0                 ; # maximum playable Y

    # --- Validation settings ---
    variable paranoid 1             ; # 1 = extra validation checks
    variable animlog ""             ; # accumulated animation log messages
    variable quiet_mode 0           ; # 1 = suppress console output

    # --- Logging options ---
    variable savelog 0              ; # 1 = append to existing log file
    variable writeanims 1           ; # 1 = log animations used in triggers
    variable showunused 1           ; # 1 = show unused elements report
    variable auto_open_log 1        ; # 1 = auto-open log file after validation

    # --- Sound validation options ---
    variable sound_validation 1     ; # 1 = enable sound validation
    variable sound_check_audio 1    ; # 1 = check audio.idx resources
    variable sound_warn_unused 1    ; # 1 = warn about unused sounds
    variable sound_warn_duplicate_resources 0  ; # 1 = warn about duplicate resources
    variable sound_warn_orphan_resources 1     ; # 1 = report unused audio resources

    # --- Other settings ---
    variable ini_encoding ""        ; # INI file encoding (empty = auto-detect)

    # ==========================================================================
    # PATHS AND RUNTIME STATE
    # ==========================================================================

    variable ra2dir_abs ""          ; # absolute path to game directory
    variable ra2rul ""              ; # rules INI filename
    variable ra2ai ""               ; # AI INI filename
    variable ra2art ""              ; # art INI filename
    variable ra2snd ""              ; # sound INI filename
    variable ra2tm ""               ; # theme INI filename
    variable ra2eva ""              ; # EVA INI filename

    # --- CLI state (set by main.tcl) ---
    variable argv ""                ; # map filename from command line
    variable path ""                ; # script directory path
    variable maperr {}              ; # accumulated log messages
    variable started 0              ; # start timestamp in milliseconds

    # --- Logging handler (can be overridden) ---
    variable logproc ""             ; # custom logging procedure name

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Ensure all array-type variables exist as empty arrays
    foreach varname {
        infantry vehicles aircraft buildings vanims anims ianims particles particlesys
        terrains smudges countries superweapons weapons warheads projectiles
        attacheffects radiationtypes shieldtypes
        bidx uidx iidx aidx owners art harvy agent assaulter engineer transport
        allunits allobjects paddies globalvars variables rulesdata rawmapdata
        triggers events actions tags teamtypes scripts taskforces
        local_aitriggers aitriggertypes waypoints wpcoords houses
        changeidx mphouses parent tfowner artery terrain_foundation
        foundry unitcoord uhouse ubldg uteam utask uscript uvars uglobal
        tagobjects tagcelltags infsubcell basicplayer
        house_country house_playerctl house_basenodes house_units
        sndlist movies themes_by_name dialogs_by_name
        sound_params sound_resources used_sounds_rules used_sounds_art
        audio_resources corner armortypes
    } {
        if {![info exists ::Data::$varname] || [array exists ::Data::$varname] == 0} {
            set ::Data::${varname}(__dummy__) 1
            unset ::Data::${varname}(__dummy__)
        }
    }

    # Initialize list-type variables as empty lists
    if {![info exists ::Data::mapunits]} { set ::Data::mapunits {} }
    if {![info exists ::Data::maperr]} { set ::Data::maperr {} }
    if {![info exists ::Data::armortypes_order]} { set ::Data::armortypes_order {} }
}

# End of data.tcl
