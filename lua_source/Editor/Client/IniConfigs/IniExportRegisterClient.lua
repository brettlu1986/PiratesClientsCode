local IniExportRegisterClient = {}

IniExportRegisterClient.szPath = "Scripts/Editor/Client/IniConfigs"

function IniExportRegisterClient:Register(Exporter)
    Exporter:Register("PlayerNameIni")
    Exporter:Register("PlayerCullDistanceIni")
    Exporter:Register("BattleGroundIni")
    Exporter:Register("MainMenuIni")
    Exporter:Register("UIMapIni")
    Exporter:Register("MapSoundIni")
    Exporter:Register("HomelandIni")
    Exporter:Register("SettingIni")
    Exporter:Register("FirstBattleIni")
    Exporter:Register("ShipDataDisplayIni")
    Exporter:Register("ShopIni")
    Exporter:Register("TutorialDungeonIni")
    Exporter:Register("BattleResultIni")
    Exporter:Register("HeadHpIni")
    Exporter:Register("UILoadingWndIni")
    Exporter:Register("CameraIni")
    Exporter:Register("ChangeDisplayIni")
    Exporter:Register("BattlePickupIni")
    Exporter:Register("DisplayAwardItemIni")
    Exporter:Register("DestructibleObjectIni")
    Exporter:Register("GMIni")
    Exporter:Register("NotifactionMiscIni")
    Exporter:Register("FriendIni")
    Exporter:Register("ReconnectIni")
    Exporter:Register("SeasonIni")
    Exporter:Register("ScheduleIni")
    Exporter:Register("TeamIni")
    Exporter:Register("LobbyCaptainMiscIni")
    Exporter:Register("PointTipsIni")
    Exporter:Register("BattleExperienceIni")
end

return IniExportRegisterClient
