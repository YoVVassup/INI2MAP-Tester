#----------------------------------------------------------------------------------------------------------
# rules_parser/collect_used_sounds.tcl - Scan rulesdata for sound-related fields
#----------------------------------------------------------------------------------------------------------

# Guard against double loading
if {[info exists ::Rules::collect_used_sounds_loaded]} { return }
set ::Rules::collect_used_sounds_loaded 1

proc ::Rules::collect_used_sounds {} {
    set sound_fields {
        ActivateSound AddPlanningModeCommandSound AirstrikeAbortSound
        AirstrikeAttackVoice AmbientSound AuxSound1 AuxSound2
        BaseUnderAttackSound BombAttachSound BombTickingSound BounceSound
        BuildingDamageSound BuildingDieSound BuildingDrop BuildingGarrisonedSound
        BuildingRepairedSound BuildingSlam BunkerWallsDownSound BunkerWallsUpSound
        CheerSound ChronoInSound ChronoOutSound ChuteSound CloakSound Construction
        CrashingSound CrateArmourSound CrateFireSound CrateMoneySound CratePromoteSound
        CrateRevealSound CrateSpeedSound CrateUnitSound CreateAircraftSound
        CreateInfantrySound CreateSound CreateUnitSound CrushSound DamageSound
        DeactivateSound DeploySound DieSound DigSound DisklaserChargeUp
        EndPlanningModeSound EnterBioReactorSound EnterGrinderSound EnterTransportSound
        EnterWaterSound ExecutePlanSound ExpireSound GameClosed GameForming GateDown
        GateUp GenericBeep GenericClick GeneticMutatorActivateSound GuardSound
        GUIBuildSound GUICheckBoxSound GUICloseSound GUIComboCloseSound GUIComboOpenSound
        GUIMainButtonSound GUIMoveInSound GUIMoveOutSound GUIOpenSound GUITabSound
        IFVTransformSound ImpactLandSound ImpactWaterSound IncomingMessage
        LeaveBioReactorSound LeaveGrinderSound LeaveTransportSound LeaveWaterSound
        LetsDoTheTimeWarpInAgain LetsDoTheTimeWarpOutAgain LightningSounds
        MastermindOverloadDeathSound MessageCharTyped MindClearedSound MoveSound
        MovieOff MovieOn NotWorkingSound OptionsChanged PlaceBeaconSound PlayerJoined
        PlayerLeft PsychicDominatorActivateSound PsychicRevealActivateSound
        PsychicSensorDetectAttach RadarOff RadarOn RepairBridgeSound Report
        ScatterSound ScoldSound ScoreAnimSound SellSound ShellButtonSlideSound
        SinkingSound SlaveMinerDeploySound SlaveMinerUndeploySound SlavesFreeSound
        SpecialSound SpyPlaneCamera SpyPlaneCameraFrames SpySatActivationSound
        SpySatDeactivationSound StartPlanningModeSound StartSound StopSound
        StormSound SystemError TeslaCharge TeslaZap TurretRotateSound UndeploySound
        UpgradeEliteSound UpgradeVeteranSound VoiceAttack VoiceCapture VoiceCrashing
        VoiceDeploy VoiceEnter VoiceHarvest VoiceFeedback VoiceIFVRepair VoiceMove
        VoiceSecondaryWeaponAttack VoiceSelect VoiceSpecialAttack VoiceUndeploy
        WorkingSound YuriMindControlSound Promote.VeteranSound Promote.EliteSound
        DieSound.Override VoiceDie.Override DigInSound DigOutSound DecloakSound
        SW.Sound SW.ActivationSound VoiceAirstrikeAttack VoiceAirstrikeAbort
    }

    set extra_fields {
        DieSound MoveSound AttackSound VoiceSelect VoiceMove VoiceAttack
        VoiceFeedback VoiceSpecialAttack VoiceCrashing VoiceDeploy VoiceUndeploy
        EnterTransportSound LeaveTransportSound StartSound StopSound Report
        DamageSound CrushSound DeploySound UndeploySound
    }
    # Build dict for O(1) lookups (linear `in` on ~110 fields × ~100k lines = O(11M))
    set sound_fields_dict [dict create]
    foreach f [concat $sound_fields $extra_fields] {
        dict set sound_fields_dict $f 1
    }

    foreach section [array names ::Data::rulesdata] {
        foreach line $::Data::rulesdata($section) {
            set kv [::util::_parse_keyval $line]
            if {$kv eq ""} continue
            set key [lindex $kv 0]
            set val [lindex $kv 1]
            if {[dict exists $sound_fields_dict $key]} {
                set ::Data::used_sounds_rules([string tolower $val]) 1
            }
            if {$key eq "CreditTicks" && $section eq "General"} {
                foreach snd [split $val ","] {
                    set trimmed [string trim $snd]
                    if {$trimmed ne ""} {
                        set ::Data::used_sounds_rules([string tolower $trimmed]) 1
                    }
                }
            }
        }
    }
}
