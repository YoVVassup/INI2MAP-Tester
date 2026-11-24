#----------------------------------------------------------------------------------------------------------
# cache.tcl - Rules and audio caching for batch mode performance
#----------------------------------------------------------------------------------------------------------
# Caches decrypted rules data and audio indices so they are not
# re-decrypted for every map in batch mode.
#----------------------------------------------------------------------------------------------------------

namespace eval ::RulesCache {
    variable ready 0

    # Single source of truth for cached array names.
    # Everything ::Rules::load_all / ::Orchestrator::_load_audio put into ::Data
    # MUST be listed here: main.tcl:239-243 unsets ALL ::Data arrays before each
    # batch map, and only these get restored (missing entry = rules data silently
    # gone for maps 2..N).
    variable cached_arrays {
        infantry vehicles aircraft buildings vanims anims ianims
        particles particlesys terrains smudges countries superweapons
        weapons warheads projectiles globalvars rulesdata owners art
        paddies harvy transport agent assaulter engineer
        allunits allobjects iidx uidx aidx bidx
        aitriggertypes
        # Phobos/armor/AI sections (P1 batch restore)
        armortypes attacheffects radiationtypes shieldtypes
        ai_defs teamtypes taskforces scripts
        art_sections artery movies used_sounds_art terrain_foundation
        sndlist sound_params sound_resources
        themes themes_by_name dialogs dialogs_by_name
        used_sounds_rules
        audio_resources
    }

    # Scalar variables to cache
    variable cached_scalars {
        countrycnt sound_defaults audio_resource_count audio_idx_available
        armortypes_order
    }
}

# Save all rules-related ::Data variables into ::RulesCache namespace
proc ::RulesCache::save {} {
    variable ready
    variable cached_arrays
    variable cached_scalars

    foreach arr $cached_arrays {
        if {[info exists ::RulesCache::_${arr}]} {
            array unset ::RulesCache::_${arr}
        }
        if {[array exists ::Data::$arr]} {
            array set ::RulesCache::_${arr} [array get ::Data::$arr]
        }
    }

    foreach var $cached_scalars {
        if {[info exists ::Data::$var]} {
            set ::RulesCache::_${var} [set ::Data::$var]
        }
    }

    set ready 1
    puts "Rules and audio data cached."
}

# Restore all rules-related ::Data variables from ::RulesCache namespace
proc ::RulesCache::restore {} {
    variable ready
    variable cached_arrays
    variable cached_scalars

    if {!$ready} { error "RulesCache not populated. Call ::RulesCache::save first." }

    foreach arr $cached_arrays {
        if {[info exists ::RulesCache::_${arr}]} {
            if {[array exists ::Data::$arr]} {
                array unset ::Data::$arr
            }
            array set ::Data::$arr [array get ::RulesCache::_${arr}]
        }
    }

    foreach var $cached_scalars {
        if {[info exists ::RulesCache::_${var}]} {
            set ::Data::$var [set ::RulesCache::_${var}]
        }
    }

    set ::Data::rules_loaded 1
}
