local IniExportRegisterCommon = {}

IniExportRegisterCommon.szPath = "Scripts/Editor/Common/IniConfigs"

function IniExportRegisterCommon:Register(Exporter)
    Exporter:Register("ShipMovementIni")
    Exporter:Register("FFAItemIni")
    Exporter:Register("HumanMovementIni")
    Exporter:Register("DungeonIni")
    Exporter:Register("CreateRoleCameraIni")
    Exporter:Register("ParachutingNewIni")
    Exporter:Register("HumanMoraleIni")
    Exporter:Register("HumanWeaponAttachmentMiscIni")
    Exporter:Register("HumanFallingDamageIni")
    Exporter:Register("ShipMoraleIni")
    Exporter:Register("RadarmapSoundListenIni")
    Exporter:Register("BotIni")
    Exporter:Register("HumanSwimmingIni")
    Exporter:Register("NpcAIIni")
    Exporter:Register("ScoreIni")
    Exporter:Register("ChatIni")
    Exporter:Register("TriggerIni")
    Exporter:Register("HumanCommonIni")
    Exporter:Register("LobbyItemIni")
    Exporter:Register("CurrencyIni")
    Exporter:Register("InitItemIni")
    Exporter:Register("SDKMiscIni")
    Exporter:Register("IapIni")
    Exporter:Register("ActivityMiscIni")
    Exporter:Register("HumanConcealIni")
    Exporter:Register("HumanMiscPropertyDefaultIni")
    Exporter:Register("VehicleMovementIni")
    Exporter:Register("BattleResultServerIni")
end

return IniExportRegisterCommon