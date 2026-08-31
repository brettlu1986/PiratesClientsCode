local DataTableExportRegisterClient = {}

DataTableExportRegisterClient.szPath = "Scripts/Editor/Client/DataTables"

function DataTableExportRegisterClient:Register(Exporter)
    Exporter:Register("BackgroundMusicDataTable")

    -- UI
    Exporter:Register("PrefabDataTable")
    Exporter:Register("WidgetDataTable")
    Exporter:Register("WndDataTable")
    Exporter:Register("GMQADataTable")
    Exporter:Register("DebugPanelDefDataTable")
    Exporter:Register("UIMapOperationGroupDataTable")
    Exporter:Register("UIMapModeDataTable")
    Exporter:Register("UIMapResDataTable")
    Exporter:Register("NpcUiTable")
    Exporter:Register("BossNameCardDataTable")
    Exporter:Register("ChapterNameDataTable")
    Exporter:Register("BossHpBarResDataTable")
    Exporter:Register("NpcDialogBoardDataTable")
    Exporter:Register("FFAMapPointCategoryDataTable")
    Exporter:Register("FFAMapPointDataTable")
    Exporter:Register("FFAMapQuestDataTable")
    Exporter:Register("MapGameObjectPointDataTable")
    Exporter:Register("LobbyPopOpenLevelDataTable")
    Exporter:Register("LoadingTipsDataTable")

    -- CreateRole
    Exporter:Register("CodePointData")
    Exporter:Register("RandomNameTable")
    Exporter:Register("CreateRoleData")
    Exporter:Register("MessageCodePointData")

    -- Text
    Exporter:Register("DialogTextDataTable")
    Exporter:Register("ToastTextDataTable")
    Exporter:Register("MiscTextDataTable")

    Exporter:Register("NpcHeadIconRes")

    --guide
    Exporter:Register("GuideResDataTable")
    Exporter:Register("GuideDataTable")
    Exporter:Register("GuideBattleDataTable")
    Exporter:Register("GuideSingleDataTable")
    Exporter:Register("GuideActionDataTable")
    Exporter:Register("GuideTriggerDataTable")
    Exporter:Register("GuideModuleDataTable")

    -- human
    Exporter:Register("HumanNPCPathMoveDataTable")
    Exporter:Register("DialogHeadIconResData")

    Exporter:Register("SoundEffectData")
    Exporter:Register("ShipMovingSoundDataTable")
    Exporter:Register("FunctionalUIIconData")

    Exporter:Register("GMIDiomDataTable")

    -- Buff
    -- Exporter:Register("BuffIconResData")


    --CameraShot
    Exporter:Register("ShotMontageDataTable")

    --战斗副本boss血条
    Exporter:Register("BattleBossInfoTable")

    Exporter:Register("MediaDataTable")

    Exporter:Register("BattleGroundDivisionDataTable")

    -- Matinee
    Exporter:Register("MatineeIntroductionData")
    Exporter:Register("MatineeSubTitleData")
    Exporter:Register("MatineeBindActorData")

    -- QTE
    Exporter:Register("QTEDataTable")

    Exporter:Register("TextDataTable")

    Exporter:Register("FFADialogDataTable")

    --camera
    Exporter:Register("HumanCameraDataTable")
    Exporter:Register("ShipCameraDataTable")
    Exporter:Register("CameraGroupDataTable")
    Exporter:Register("DeadCameraDataTable")
    Exporter:Register("TransporterCameraDataTable")
    Exporter:Register("VehicleCameraDataTable")
    -- 水手
    Exporter:Register("SailorSlotDataTable")
    Exporter:Register("SailorSummonDataTable")

    -- 船备战
    Exporter:Register("ShipSlotDataTable")
    Exporter:Register("ShipWeaponCharacteristicDataTable")
    Exporter:Register("ItemChangedEffectDataTable")

    -- 伙伴
    Exporter:Register("PartnerGradeDataTable")
    Exporter:Register("PartnerPoolDataTable")

    --副本外组队
    Exporter:Register("TeamRefuseReasonDataTable")
    -- 副本内聊天
    Exporter:Register("QuickChatDataTable")
    -- 大厅内聊天
    Exporter:Register("TeamChatDataTable")
    Exporter:Register("SystemNotifactionDataTable")

    -- 家园
    Exporter:Register("BuildingTypeDataTable")
    Exporter:Register("RegionDataTable")
    -- 放置在 BuildingTypeDataTable 之后，有配置关联检查
    Exporter:Register("BlockTypeDataTable")
    -- 放置在 BlockTypeDataTable 之后，有配置关联检查
    -- 放置在 RegionDataTable 之后，有配置关联检查
    Exporter:Register("HomelandSceneDataTable")
    Exporter:Register("BuildingUiDataTable")
    Exporter:Register("HomelandResDataTable")
    -- 放置在 HomelandSceneDataTable 之后，有配置关联检查
    -- 放置在 HomelandResDataTable 之后，有配置关联检查
    Exporter:Register("BuildingDataTable")
    Exporter:Register("BuildingRotationDataTable")
    Exporter:Register("BuildingExchangeDataTable")
    Exporter:Register("ItemResearchDataTable")
    Exporter:Register("ResearchBuildingDescDataTable")

    Exporter:Register("BattleTierRewardEffectDataTable")
    Exporter:Register("SceneMapPointDataTable")
    Exporter:Register("BattleResultAvatarPositionDataTable")
    Exporter:Register("ScoreResDataTable")
    Exporter:Register("TreasurePlaceDataTable")

    Exporter:Register("MatineeEventDatatable")

    Exporter:Register("SettingLayoutDataTable")
    Exporter:Register("SettingLayoutDefaultDataTable")
    Exporter:Register("SettingCameraDataTable")
    Exporter:Register("SettingGyroDataTable")

    Exporter:Register("RoundedScreenDataTable")

    Exporter:Register("ShopDataTable")
    Exporter:Register("IAPDataTable")
    Exporter:Register("IAPResultToastDataTable")

    -- 活动
    Exporter:Register("ScheduleUITable")
    Exporter:Register("CheckInTable")
    Exporter:Register("NoobLoginDataTable")
    Exporter:Register("TimedAwardDataTable")
    Exporter:Register("ContinuousDataTable")
    Exporter:Register("ScheduleTable")

    Exporter:Register("AwardGiftBoxDataTable")

    Exporter:Register("WelfareDataTable")
    Exporter:Register("VipCardDataTable")
    Exporter:Register("BattleStaticsCustomItemDataTable")

    -- 登录
    Exporter:Register("LoginSDKBtnDataTable")
    Exporter:Register("EnterLastDungeonDataTable")

    Exporter:Register("HumanWeaponAnimationDataTable")

    -- season
    Exporter:Register("BattleTierDataTable")
    Exporter:Register("BattleTierRewardDataTable")
    Exporter:Register("SeasonDataTable")
    Exporter:Register("RankDataTable")
    Exporter:Register("ChallengeSubIndexDataTable")
    Exporter:Register("BattlePassRewardDataTable")

    -- setting
    Exporter:Register("SettingDataTable")

    Exporter:Register("LobbySubLevelDataTable")
    --lobby captain
    Exporter:Register("LobbyDefaultBasicFashionIconDataTable")
    Exporter:Register("LobbyWeaponMiscDataTable")
    Exporter:Register("LobbyDecorationResDataTable")
    Exporter:Register("LobbyArmorMiscDataTable")

    Exporter:Register("UIShipDataTable")
    Exporter:Register("UISailorResDataTable")

    Exporter:Register("BattleHumanEffectDataTable")
    Exporter:Register("ShipHurtTagDataTable")
    Exporter:Register("SoundExperienceDataTable")

    Exporter:Register("GameShakeDataTable")
    
end

return DataTableExportRegisterClient