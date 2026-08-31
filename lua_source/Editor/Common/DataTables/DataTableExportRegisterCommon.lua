local DataTableExportRegisterCommon = {}

DataTableExportRegisterCommon.szPath = "Scripts/Editor/Common/DataTables"

function DataTableExportRegisterCommon:Register(Exporter)
    Exporter:Register("SceneResDataTable")
    Exporter:Register("SceneDataTable")
    Exporter:Register("DungeonModeDataTable")
    -- 放置在 DungeonModeDataTable 之后，有副本模式检查
    Exporter:Register("DungeonDataTable")

    -- Ship
    Exporter:Register("ShipResDataTable")
    Exporter:Register("ShipGearDataTable")
    Exporter:Register("ShipPathMoveGearDataTable")
    Exporter:Register("ShipWeaponCategoryDataTable")
    Exporter:Register("ShipDataTable") -- 在Ship的表里最后初始化

    --human
    Exporter:Register("HumanFightDataTable")
    Exporter:Register("HumanMovementSpeedDataTable")

    -- item
    Exporter:Register("BattleItemResDataTable")

    --Interaction
    Exporter:Register("BattleBuffDataTable")
    Exporter:Register("ProgressBarTableNew")
    Exporter:Register("ProgressBarAbortTable")
    Exporter:Register("ProgressBarProhibitTable")
    --放置在 BattleItemDataTable 之前，itemdata里面会用
    Exporter:Register("HumanWeaponRecoilDataTable")
    -- battle item
        -- 放置在 ProgressBarTable 之后，有类型检查
        -- 放置在 ProgressBarTableNew 之后，有类型检查
        -- 放置在 BattleBuffDataTable 之后，有类型检查
        -- 放置在 ShipDataTable 之后，有类型检查
    Exporter:Register("BattleItemDataTable")
    Exporter:Register("BattleItemCategoryDataTable")
        -- BattleItemDropGroupDataTable
        -- 放置在 BattleItemDropDataTable 之前，有联表查询依赖
        -- 放置在 BattleItemDataTable 之后，有物品合法性检查
    Exporter:Register("BattleItemDropGroupDataTable")
        -- 放置在 BattleItemDataTable 之后，有物品合法性检查
    Exporter:Register("BattleItemDropDataTable")

        -- 放置在 BattleItemDataTable 之后，有物品类型检查
        -- 放置在 ProgressBarTable 之后，有类型检查
        -- 放置在 ProgressBarTableNew 之后，有类型检查
    Exporter:Register("BattleItemBuildDataTable")

        -- 放置在 BattleItemDataTable 之后，有物品类型检查
    Exporter:Register("InitItemDataTable")
        -- 放置在 BattleItemDataTable 之后，有物品类型检查
    Exporter:Register("PvpInitItemDataTable")

    -- NPC

    -- 放在BattleItemDataTable之后，有数据关联
    -- TODO: 等冉洁删
    Exporter:Register("NPCDataTable")
    Exporter:Register("DungeonAIDataTable")
    Exporter:Register("DungeonAITypeDataTable")
    Exporter:Register("DungeonAITargetingDataTable")
    Exporter:Register("NpcAIConditionDataTable")
    Exporter:Register("ShipAIConditionDataTable")
    -- 放置在 BattleItemDataTable 之后，有物品合法性检查
    Exporter:Register("NpcInitItemRandomDataTable")

    -- Human
    Exporter:Register("HumanResDataTable")
    Exporter:Register("HeadIconResDataTable")
    Exporter:Register("HumanDataTable")
    Exporter:Register("AvatarDataTable")

    -- Player
    -- Exporter:Register("AnimationResDataTable")
    Exporter:Register("AnimationResDataTableNew")
    Exporter:Register("PlayerLevelDataTable")
    Exporter:Register("ThrowStateResDataTable")

    -- Dungeon
    Exporter:Register("DungeonTypeDataTable")
    Exporter:Register("PVPOccupyDataTable")
    Exporter:Register("SocietyGuardDataTable")
    Exporter:Register("SocietyExplorerDataTable")
    Exporter:Register("SocietyPrivateerDataTable")
    Exporter:Register("SmuggleDataTable")
    Exporter:Register("EscortDataTable")
    Exporter:Register("PVE01DataTable")
    Exporter:Register("PVE02DataTable")
    Exporter:Register("SideQuest01DataTable")
    Exporter:Register("TutorialDataTable")
    Exporter:Register("GroupTriggerDataTable")
    Exporter:Register("TriggerBuffDataTable")
    Exporter:Register("ObjectiveDataTable")
    Exporter:Register("ShipPlayerAIDataTable")
    Exporter:Register("CampTypeRelationDataTable")
    Exporter:Register("DungeonDifficultyDataTable")

    Exporter:Register("MockDungeonDataTable")
    Exporter:Register("MockClientDataTable")
    Exporter:Register("DungeonCollectionTable")
    Exporter:Register("GameInitDataDataTable")

    Exporter:Register("QuestDataTable")
    -- Faction
    Exporter:Register("FactionDataTable")
    Exporter:Register("FactionLevelTable")

    -- AVG
    Exporter:Register("AVGDataTable")

    -- Trigger
    Exporter:Register("TriggerResDataTable")

    -- Effect
    Exporter:Register("EffectResDataTable")

    -- Collection
    Exporter:Register("CollectionResDataTable")
    Exporter:Register("CollectionDataTable")

    -- Fog
    Exporter:Register("FogDataTable")

    -- Dummy
    Exporter:Register("DummyResDataTable")

    -- BattleAbility
    Exporter:Register("SkillResDataTable")
    -- Exporter:Register("BattleBuffDataTable") -- 移上去了，要在 Item 前，有配置表检查依赖关系
    Exporter:Register("BattleBuffResDataTable")
    Exporter:Register("SummonObjectDataTable")
    Exporter:Register("AbilityParticleEffectResDataTable")
    Exporter:Register("AbilityMaterialEffectResDataTable")
    Exporter:Register("AbilityPostProcessEffectResDataTable")
    Exporter:Register("SkillDataTable")
    Exporter:Register("ShipSkillDataTable")
    Exporter:Register("NpcSkillDataTable")
    Exporter:Register("JumpBuffDataTable")

    -- Matinee
    Exporter:Register("MatineeDataTable")

    --Misc
    Exporter:Register("BPTableRootDataTable")

    --loading
    Exporter:Register("LoadingBgDataTable")

    --battleground
    Exporter:Register("BattleGroundDataTable")

    -- FFA
    Exporter:Register("PoisonCircleDataTable")
    Exporter:Register("PoisonCircleSettingDataTable")
    Exporter:Register("ShipMoraleDataTable")
    Exporter:Register("HumanMoraleDataTable")
    Exporter:Register("ShipArmorDataTableEx")
    Exporter:Register("AirdropDataTable")
    Exporter:Register("HumanWeaponCategoryPropertyDataTable")
    -- Exporter:Register("FogDataTable")
    Exporter:Register("HumanWeaponScopeResDataTable")
    -- Exporter:Register("DestructibleObjectDataTable")
    Exporter:Register("DestructibleObjectNewDataTable")
    Exporter:Register("FFAToastDataTable")
    Exporter:Register("AITypeDataTable")
    Exporter:Register("HumanWeaponMeleeDataTable")
    Exporter:Register("HumanCapsuleDataTable")
    Exporter:Register("HumanWeaponCameraTimeDataTable")
    Exporter:Register("ShipGradeDataTable")
    Exporter:Register("FFANoobDataTable")


    -- BOT
        -- 放置在 BotTemplateDataTable 之前，有联表查询依赖
    Exporter:Register("BotLevelDataTable")
    Exporter:Register("BotWeaponDataTable")
        -- 放置在 BotGroupDataTable 之前，有联表查询依赖
    Exporter:Register("BotTemplateDataTable")
    Exporter:Register("BotNameDataTable")

        -- 放置在 BattleItemDataTable 之后，有联表查询依赖
    Exporter:Register("BotInitItemRandomDataTable")
    Exporter:Register("BotSupplyItemRandomDataTable")
    Exporter:Register("BotGroupDataTable")
    Exporter:Register("BotSupplyDataTable")

    -- ITEM
    Exporter:Register("ItemSourceDataTable")
        -- 放置在 ItemDataTable 之前，有联表查询依赖
    Exporter:Register("ItemResDataTable")
    Exporter:Register("ItemDataTable")
    Exporter:Register("BackpackDataTable")

    Exporter:Register("TransporterDataTable")
    Exporter:Register("AwardDataTable")

    -- MATCHMAKING
    Exporter:Register("MatchmakingTeamModeDataTable")
    Exporter:Register("MatchmakingDataTable")
    -- NpcAI
    Exporter:Register("NpcLevelDataTable")
    Exporter:Register("NpcWeaponDataTable")
    Exporter:Register("NpcTemplateDataTable")
    Exporter:Register("NpcTemplateGradeDataTable")

    --mail
    Exporter:Register("MailTemplateDataTable")

    -- property combo, 必须先注册Define
    Exporter:Register("PropertyComboDefineDataTable")
    Exporter:Register("PropertyComboDataTable")

    Exporter:Register("SurvivalScoreDataTable")
    Exporter:Register("RankScoreDataTable")
    Exporter:Register("MoveDistanceScoreDataTable")
    Exporter:Register("KillScoreDataTable")
    Exporter:Register("GradeScoreDataTable")
    Exporter:Register("HumanDamageScoreDataTable")
    Exporter:Register("ShipDamageScoreDataTable")
    Exporter:Register("GradeValueRatioDataTable")
    Exporter:Register("BattleAwardDataTable")
    Exporter:Register("BattleResultAwardDataTable")
    Exporter:Register("AssistScoreDataTable")
    Exporter:Register("AppliedDamageScoreDataTable")
    Exporter:Register("ScoreRateDataTable")
    Exporter:Register("RescueScoreDataTable")
    Exporter:Register("ItemScoreDataTable")
    Exporter:Register("HumanCureScoreDataTable")
    Exporter:Register("ShipCureScoreDataTable")

    -- 伙伴羁绊
    Exporter:Register("PartnerRelationDataTable")

    -- 载具
    Exporter:Register("VehicleResTable")
    Exporter:Register("VehicleDropTable")
    Exporter:Register("VehicleDropGroupTable")
    Exporter:Register("VehicleDataTable")

    -- 家园
    Exporter:Register("LandmarkBuildingTypeDataTable")
    -- 放置在 LandmarkBuildingTypeDataTable 之后，有配置关联检查
    Exporter:Register("LandmarkBuildingUpgradeDataTable")

    --系统消息
    Exporter:Register("NotifyItemDataTable")

    -- Debug数值使用
    Exporter:Register("GMSearchablePropDataTable")

    -- setting
    Exporter:Register("SettingPickUpDataTable")


    -- radar map sound
    Exporter:Register("RadarMapSoundDataTable")

    Exporter:Register("BuffResData")
    Exporter:Register("BuffDataTable")
    Exporter:Register("RenameCardDataTable")


    Exporter:Register("GameCurveDataTable")
    --新版装备相关
    Exporter:Register("HumanArmorAffectWeaponPropertyDataTable")
    Exporter:Register("HumanArmorAffectActionPropertyDataTable")
    --新版外装相关
    Exporter:Register("AvatarColorDataTable")
    Exporter:Register("HumanArmorDefaultFashionDataTable")
    Exporter:Register("HumanArmorFashionDataTable")
    Exporter:Register("HumanBasicFashionDataTable")
    Exporter:Register("HumanWeaponFashionDataTable")
    --创建角色相关
    Exporter:Register("DefaultAppearanceDataTable")

    Exporter:Register("BattleItemToLobbyItemDataTable")

    Exporter:Register("FriendRelationShipLevelDataTable")
    Exporter:Register("FriendRelationShipDataTable")

    Exporter:Register("BattleSkyDataTable")
    
    Exporter:Register("AvatarRandomDataTable")
end

return DataTableExportRegisterCommon