-----------------------------------------------------
--File Name    : BattleItemLogEventOpOld.lua
--Author       : zhiyuan
--Create Time  : 2019-11-28
--Description  : 战斗中道具相关的数据埋点
-----------------------------------------------------
local luaclass = require("luaclass")
local LogEventOpBase = dynamic_require("LogEventOpBase")
local BattleItemLogEventOpOld = luaclass("BattleItemLogEventOpOld", LogEventOpBase)

local AIHelper = require("AIHelper")
local CommonEventDef = require("CommonEventDef")
local Analytics = require("DungeonAnalyticsProtoNames")
local SceneItemHelper = require("SceneItemHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local MaterialItemHelper = require("MaterialItemHelper")
local BattleItemSourceDef = require("BattleItemSourceDef")
local BattlePrepareSystem = require("BattlePrepareSystem")
local BattleItemDataTable = require("BattleItemDataTable")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")


-- 被拾取的空投id列表
BattleItemLogEventOpOld.tbPickedUpAirDrops = nil
-- 被创建的空投箱子总数
BattleItemLogEventOpOld.nAirDropBoxCount = nil

-- 记录每个大类型被拾取的数量
-- self.tbPlayerItemRecords = {}
-- local nPlayerId = 11
-- local tbRecord = {}
-- tbRecord.nParachutionEndTime = nil -- 跳伞结束时间
-- tbRecord.bHasPicked = false --是否拾取过
-- tbRecord.bHasPickedDiamond = false --是否拾取过宝石
-- tbRecord.bHasCostDiamond = false --是否消耗过宝石
-- tbRecord.bHasBuilt = false -- 是否建造过
-- tbRecord.nMaterialGetCount = 0  -- 材料获取总量
-- tbRecord.nMaterialCostCount = 0  -- 材料消耗总量
-- tbRecord.nDiamondGetCount = 0  -- 宝石获取总量
-- tbRecord.nDiamondCostCount = 0  -- 宝石消耗总量
-- tbRecord.tbCategoryPickupRecord = {} -- 每个大类拾取的数量记录
-- tbRecord.tbCategoryEquipRecord = {} -- 每个大类装备的记录
-- self.tbPlayerItemRecords[nPlayerId] = tbRecord
BattleItemLogEventOpOld.tbPlayerItemRecords = nil

local DIAMOND_TEMPLATE_ID = 11010004

local TB_NEED_LOG_TOTAL_PICKED_UP_CATEGORY =
{
    BattleItemCategoryDef.BUILD_KEY_ITEM,
    BattleItemCategoryDef.HUMAN_THROWN_ITEM,
    BattleItemCategoryDef.HUMAN_CONSUMABLE
}

local TB_NEED_LOG_EQUIP_CATEGORY =
{
    BattleItemCategoryDef.SHIP_WEAPON,
    BattleItemCategoryDef.SHIP_PART,
    BattleItemCategoryDef.HUMAN_WEAPON,
    BattleItemCategoryDef.HUMAN_ARMOR,
    BattleItemCategoryDef.SHIP,
}

local TB_NEED_LOG_FIRST_PICKED_UP_CATEGORY =
{
    BattleItemCategoryDef.MATERIAL,
    BattleItemCategoryDef.HUMAN_WEAPON
}

-----------------------------------------------------------local function--------------------------------------------------

local function LOG(...)
    log("[BattleItemLogEventOpOld]", ...)
end

local function IsBot(nPlayerId)
    return BattlePrepareSystem:IsBot(nPlayerId)
end

-- 判断是不是玩家
local function IsPlayerSelfAndNotBot(tbPlayer)
    if tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf
         and not AIHelper.IsAIControlled(tbPlayer) then
        return true
    end
    return false
end

local function Contains(tbArray, tbElement)
    for _, v in ipairs(tbArray) do
        if tbElement == v then
            return true
        end
    end
    return false
end

local function NeedLogCategoryFirstPickup(nCategory)
    return Contains(TB_NEED_LOG_FIRST_PICKED_UP_CATEGORY, nCategory)
end

local function NeedLogEquip(nCategory)
    return Contains(TB_NEED_LOG_EQUIP_CATEGORY, nCategory)
end

local function GetElapsedTime(self, nPlayerId)
    local nStartTime = nil
    local tbRecord = self.tbPlayerItemRecords[nPlayerId]
    if tbRecord then
        nStartTime = tbRecord.nParachutionEndTime
    end

    if nStartTime == nil then
        -- 没有setting就不统计，下面需要setting里去取starttimestamp
        local tbGameMode = BattleGameModeSystem:GetGameMode()
        if not tbGameMode then
            logwarning("GetElapsedTime:Cannot get game mode!")
            return nil
        end
        nStartTime = tbGameMode:GetBattleStartTimestamp()
    end

    return GlobalVariableSystem:GetLocalTime() - nStartTime
end

local function InitPickupRecord(self)
    self.tbPickedUpAirDrops = {}
    self.nAirDropBoxCount = 0
    self.tbPlayerItemRecords = {}
end

local function ClearPickupRecord(self)
    self.tbPickedUpAirDrops = nil
    self.nAirDropBoxCount = nil
    self.tbPlayerItemRecords = nil
end

local function GetOrCreatePickupRecord(self, nPlayerId)
    local tbRecord = self.tbPlayerItemRecords[nPlayerId]
    if tbRecord then
        return tbRecord
    else
        tbRecord = {}
        self.tbPlayerItemRecords[nPlayerId] = tbRecord
        tbRecord.nParachutionEndTime = nil
        tbRecord.bHasPicked = false
        tbRecord.bHasPickedDiamond = false
        tbRecord.bHasCostDiamond = false
        tbRecord.bHasBuilt = false
        tbRecord.nMaterialGetCount = 0
        tbRecord.nMaterialCostCount = 0
        tbRecord.nDiamondGetCount = 0
        tbRecord.nDiamondCostCount = 0
        tbRecord.tbCategoryPickupRecord = {}
        tbRecord.tbCategoryEquipRecord = {}
        return tbRecord
    end
end

local function HasPicked(self, nPlayerId)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    return tbRecord.bHasPicked
end

local function HasPickedDiamond(self, nPlayerId)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    return tbRecord.bHasPickedDiamond
end

local function HasPickedCategory(self, nPlayerId, nCategory)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    local tbCategoryPickupRecord = tbRecord.tbCategoryPickupRecord
    local nPickedUpCount = tbCategoryPickupRecord[nCategory]
    if nPickedUpCount ~= nil and nPickedUpCount > 0 then
        return true
    end
    return false
end

local function HasEquipCategoryAndGrade(self, nPlayerId, nCategory, nGrade)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    local tbCategoryEquipRecord = tbRecord.tbCategoryEquipRecord
    local tbGradeRecords = tbCategoryEquipRecord[nCategory]
    if tbGradeRecords ~= nil then
        local bEquip = tbGradeRecords[nGrade]
        if bEquip ~= nil then
            return bEquip
        end
        return false
    end
    return false
end

local function HasBuilt(self, nPlayerId)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    return tbRecord.bHasBuilt
end

local function HasCostDiamond(self, nPlayerId)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    return tbRecord.nDiamondCostCount > 0
end

local function AddPickedUpAirDropRecord(self, nRoomActorId)
    if SceneItemHelper.IsAirDrop(nRoomActorId) then
        local bHasPicked = false
        for _, v in ipairs(self.tbPickedUpAirDrops) do
            if v == nRoomActorId then
                bHasPicked = true
                break
            end
        end
        if not bHasPicked then
            table.insert(self.tbPickedUpAirDrops, nRoomActorId)
        end
    end
end

local function AddPickedUpRecord(self, nPlayerId, nCategory, nItemTemplateId, nCount)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    tbRecord.bHasPicked = true
    if nItemTemplateId == DIAMOND_TEMPLATE_ID then
        tbRecord.bHasPickedDiamond = true
        tbRecord.nDiamondGetCount = tbRecord.nDiamondGetCount + nCount
    end
    if nCategory == BattleItemCategoryDef.MATERIAL then
        tbRecord.nMaterialGetCount = tbRecord.nMaterialGetCount + nCount
    end
    local tbCategoryPickupRecord = tbRecord.tbCategoryPickupRecord
    local nPickedUpCount = tbCategoryPickupRecord[nCategory]
    if not nPickedUpCount then
        nPickedUpCount = 0
    end
    tbCategoryPickupRecord[nCategory] = nPickedUpCount + nCount
end

local function DecreaseMaterialPickupRecord(self, nPlayerId, nItemTemplateId, nCount)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    tbRecord.nMaterialGetCount = math.max(0, tbRecord.nMaterialGetCount - nCount)
    if nItemTemplateId == DIAMOND_TEMPLATE_ID then
        tbRecord.nDiamondGetCount = math.max(0, tbRecord.nDiamondGetCount - nCount)
    end
end

local function AddEquipRecord(self, nPlayerId, nCategory, nGrade)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    local tbGradeRecords = tbRecord.tbCategoryEquipRecord[nCategory]
    if tbGradeRecords == nil then
        tbRecord.tbCategoryEquipRecord[nCategory] = {}
        tbGradeRecords = tbRecord.tbCategoryEquipRecord[nCategory]
    end
    tbGradeRecords[nGrade] = true
end

local function AddBuildRecord(self, nPlayerId)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    tbRecord.bHasBuilt = true
end

local function AddCostMaterialRecord(self, nPlayerId, nItemTemplateId, nCount)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    tbRecord.nMaterialCostCount = tbRecord.nMaterialCostCount + nCount
    if nItemTemplateId == DIAMOND_TEMPLATE_ID then
        tbRecord.nDiamondCostCount = tbRecord.nDiamondCostCount + nCount
    end
end

--------------------------------------------------------local log table 构造和发送-------------------------------------------------------------
-- 拾取
local function LogPickup(self, tbPlayer, nItemTemplateId, nCount, bIsFirst)
    local nPlayerId = tbPlayer:GetPlayerId()
    local tbPacket = {}
    tbPacket.common_infos = self:GetBattleCommonPropertys()
    tbPacket.player_id = nPlayerId
    tbPacket.grid_region_type = self:GetPlayerGridRegionType(tbPlayer)
    tbPacket.battle_item_detail = self:GetBattleItemDetail(nItemTemplateId)
    tbPacket.count = nCount
    tbPacket.is_first = bIsFirst
    if bIsFirst then
        local nElapsedTime = GetElapsedTime(self, nPlayerId)
        if not nElapsedTime then -- 如果获取不到就不统计
            return
        end
        tbPacket.elapsed_time = nElapsedTime
    end
    self:LogEvent(Analytics.Pickup, tbPacket)
    LOG("Analytics.Pickup", t2s(tbPacket))
    return tbPacket
end

-- 首次拾取
local function LogFirstPickup(self, tbPlayer)
    local nPlayerId = tbPlayer:GetPlayerId()
    local nElapsedTime = GetElapsedTime(self, nPlayerId)
    if not nElapsedTime then -- 如果获取不到就不统计
        return
    end

    local tbPacket = {}
    tbPacket.common_infos = self:GetBattleCommonPropertys()
    tbPacket.player_id = nPlayerId
    tbPacket.grid_region_type = self:GetPlayerGridRegionType(tbPlayer)
    tbPacket.elapsed_time = nElapsedTime
    self:LogEvent(Analytics.FirstPickup, tbPacket)
    LOG("Analytics.FirstPickup", t2s(tbPacket))
end

-- 首次拾取宝石
local function LogFirstPickupDiamond(self, tbPlayer)
    local nPlayerId = tbPlayer:GetPlayerId()
    local nElapsedTime = GetElapsedTime(self, nPlayerId)
    if not nElapsedTime then -- 如果获取不到就不统计
        return
    end

    local tbPacket = {}
    tbPacket.common_infos = self:GetBattleCommonPropertys()
    tbPacket.player_id = nPlayerId
    tbPacket.grid_region_type = self:GetPlayerGridRegionType(tbPlayer)
    tbPacket.elapsed_time = nElapsedTime
    self:LogEvent(Analytics.FirstPickupDiamond, tbPacket)
    LOG("Analytics.FirstPickupDiamond", t2s(tbPacket))
end

-- 拾取总量
local function LogTotalPickup(self, nPlayerId, nCategory, nCount)
    local tbPacket = {}
    tbPacket.common_infos = self:GetBattleCommonPropertys()
    tbPacket.player_id = nPlayerId
    tbPacket.category = nCategory
    tbPacket.count = nCount
    self:LogEvent(Analytics.TotalPickup, tbPacket)
    LOG("Analytics.TotalPickup", t2s(tbPacket))
    return tbPacket
end

local function LogTotalMaterialDetails(self, nPlayerId)
    local tbPacket = {}
    tbPacket.common_infos = self:GetBattleCommonPropertys()
    tbPacket.player_id = nPlayerId
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    tbPacket.total_cost_material = tbRecord.nMaterialCostCount
    tbPacket.total_get_material = tbRecord.nMaterialGetCount
    tbPacket.total_cost_diamond = tbRecord.nDiamondCostCount
    tbPacket.total_get_diamond = tbRecord.nDiamondGetCount
    self:LogEvent(Analytics.TotalMaterialDetails, tbPacket)
    LOG("Analytics.TotalMaterialDetails", t2s(tbPacket))
    return tbPacket
end

local function LogPlayerAllTotalPickup(self, nPlayerId)
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    local tbCategoryPickupRecord = tbRecord.tbCategoryPickupRecord
    for _, nCategory in ipairs(TB_NEED_LOG_TOTAL_PICKED_UP_CATEGORY) do
        local nCount = tbCategoryPickupRecord[nCategory]
        if not nCount then
            nCount = 0
        end
        LogTotalPickup(self, nPlayerId, nCategory, nCount)
    end
end

local function LogEquip(self, nPlayerId, nItemTemplateId, nSourceType, bIsFirst)
    local tbPacket = {}
    tbPacket.common_infos = self:GetBattleCommonPropertys()
    tbPacket.player_id = nPlayerId
    tbPacket.source_type = nSourceType
    tbPacket.is_first = bIsFirst
    if bIsFirst then
        local nElapsedTime = GetElapsedTime(self, nPlayerId)
        if not nElapsedTime then -- 如果获取不到就不统计
            return
        end
        tbPacket.elapsed_time = nElapsedTime
    end
    tbPacket.battle_item_detail = self:GetBattleItemDetail(nItemTemplateId)
    self:LogEvent(Analytics.Equip, tbPacket)
    LOG("Analytics.Equip", t2s(tbPacket))
    return tbPacket
end

local function LogAirDrop(self)
    local tbPacket = {}
    tbPacket.common_infos = self:GetBattleCommonPropertys()
    tbPacket.pickup_count = #self.tbPickedUpAirDrops

    tbPacket.total_air_drop_count = self.nAirDropBoxCount

    self:LogEvent(Analytics.AirDrop, tbPacket)
    LOG("Analytics.AirDrop", t2s(tbPacket))
    return tbPacket
end

-- 首次建造
local function LogFirstBuild(self, tbPlayer)
    local nPlayerId = tbPlayer:GetPlayerId()
    local nElapsedTime = GetElapsedTime(self, nPlayerId)
    if not nElapsedTime then -- 如果获取不到就不统计
        return
    end

    local tbPacket = {}
    tbPacket.common_infos = self:GetBattleCommonPropertys()
    tbPacket.player_id = nPlayerId
    tbPacket.grid_region_type = self:GetPlayerGridRegionType(tbPlayer)
    tbPacket.elapsed_time = nElapsedTime
    self:LogEvent(Analytics.FirstBuild, tbPacket)
    LOG("Analytics.FirstBuild", t2s(tbPacket))
end

local function LogBuild(self, nPlayerId, nItemTemplateId, bIsFirst)
    local tbPacket = {}
    tbPacket.common_infos = self:GetBattleCommonPropertys()
    tbPacket.player_id = nPlayerId
    tbPacket.is_first = bIsFirst
    if bIsFirst then
        local nElapsedTime = GetElapsedTime(self, nPlayerId)
        if not nElapsedTime then -- 如果获取不到就不统计
            return
        end
        tbPacket.elapsed_time = nElapsedTime
    end
    tbPacket.battle_item_detail = self:GetBattleItemDetail(nItemTemplateId)
    self:LogEvent(Analytics.Build, tbPacket)
    LOG("Analytics.Build", t2s(tbPacket))
    return tbPacket
end

local function LogMaterialCost(self, nPlayerId, nItemTemplateId, nCount, bIsFirstCostDiamond)
    local tbPacket = {}
    tbPacket.common_infos = self:GetBattleCommonPropertys()
    tbPacket.player_id = nPlayerId
    tbPacket.is_first = bIsFirstCostDiamond
    if bIsFirstCostDiamond then
        local nElapsedTime = GetElapsedTime(self, nPlayerId)
        if not nElapsedTime then -- 如果获取不到就不统计
            return
        end
        tbPacket.elapsed_time = nElapsedTime
    end
    tbPacket.battle_item_detail = self:GetBattleItemDetail(nItemTemplateId)
    tbPacket.nCount = nCount
    self:LogEvent(Analytics.MaterialCost, tbPacket)
    LOG("Analytics.MaterialCost", t2s(tbPacket))
    return tbPacket
end

-- 建造消耗材料事件
local function OnMaterialCost(self, tbPlayer, nItemTemplateId, nCount)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    if nCategory ~= BattleItemCategoryDef.MATERIAL then
        return
    end
    local nPlayerId = tbPlayer:GetPlayerId()
    local bIsFirstCostDiamond = ((nItemTemplateId == DIAMOND_TEMPLATE_ID) and (not HasCostDiamond(self, nPlayerId)))
    LogMaterialCost(self, nPlayerId, nItemTemplateId, nCount, bIsFirstCostDiamond)
    AddCostMaterialRecord(self, nPlayerId, nItemTemplateId, nCount)
end

-- 所有人的整局数据上报
local function LogWhenBattleEnd(self)
    local tbPrepareInfos = BattlePrepareSystem:GetAllPlayerPrepareInfos()
    for nPlayerId, _ in pairs(tbPrepareInfos) do
        if not IsBot(nPlayerId) then
            LogPlayerAllTotalPickup(self, nPlayerId)
            LogTotalMaterialDetails(self, nPlayerId)
        end
    end
    LogAirDrop(self)
end

--------------------------------------------------------听事件的回调-------------------------------------------------------------

-- 拾取事件
local function OnEventPickup(self, tbPlayer, AddedItem, bSuccess, nRoomActorId, nCount)
    if not bSuccess then
        return
    end
    if not IsPlayerSelfAndNotBot(tbPlayer) then
        return
    end

    local nItemTemplateId = AddedItem:GetTemplateId()
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory

    local nPlayerId = tbPlayer:GetPlayerId()

    local bIsFirst = NeedLogCategoryFirstPickup(nCategory) and (not HasPickedCategory(self, nPlayerId, nCategory))

    LogPickup(self, tbPlayer, nItemTemplateId, nCount, bIsFirst)

    if not HasPicked(self, nPlayerId) then
        LogFirstPickup(self, tbPlayer)
    end
    if not HasPickedDiamond(self, nPlayerId) and nItemTemplateId == DIAMOND_TEMPLATE_ID then
        LogFirstPickupDiamond(self, tbPlayer)
    end
    AddPickedUpRecord(self, nPlayerId, nCategory, nItemTemplateId, nCount)
    AddPickedUpAirDropRecord(self, nRoomActorId)
end

-- 装备事件
local function OnEventEquip(self, tbPlayer, Item, _, _, _, nBattleItemSource)
    if not (nBattleItemSource == BattleItemSourceDef.BUILD or nBattleItemSource == BattleItemSourceDef.PICK_UP) then
        return
    end
    if not IsPlayerSelfAndNotBot(tbPlayer) then
        return
    end
    local nItemTemplateId = Item:GetTemplateId()
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    if not NeedLogEquip(nCategory) then
        return
    end
    local nPlayerId = tbPlayer:GetPlayerId()
    local nGrade = tbTemplate.nGrade
    local bIsFirst = not HasEquipCategoryAndGrade(self, nPlayerId, nCategory, nGrade)
    if nCategory == BattleItemCategoryDef.SHIP and nGrade == 1 then -- 一级船不算首次，因为初始道具里有
        bIsFirst = false
    end
    local nSourceType = Analytics.Equip_SourceType.PICK_UP
    if nBattleItemSource == BattleItemSourceDef.BUILD then
        nSourceType = Analytics.Equip_SourceType.BUILD
    end
    LogEquip(self, nPlayerId, nItemTemplateId, nSourceType, bIsFirst)
    AddEquipRecord(self, nPlayerId, nCategory, nGrade)
end

-- 建造事件
local function OnEventBuild(self, tbPlayer, _, nItemTemplateId, tbCosts)
    if not IsPlayerSelfAndNotBot(tbPlayer) then
        return
    end
    local nPlayerId = tbPlayer:GetPlayerId()
    local bIsFirst = not HasBuilt(self, nPlayerId)
    if bIsFirst then
        LogFirstBuild(self, tbPlayer)
    end
    LogBuild(self, nPlayerId, nItemTemplateId, bIsFirst)

    AddBuildRecord(self, nPlayerId)

    if tbCosts then
        for nIndex, nCount in pairs(tbCosts) do
            if nCount > 0 then
                local nMaterialTemplateId = MaterialItemHelper:GetMaterialTemplateId(nIndex)
                OnMaterialCost(self, tbPlayer, nMaterialTemplateId, nCount)
            end
        end
    end
end

-- 丢弃材料事件
local function OnEventThrowItem(self, nCharacterInstanceId, _, nItemTemplateId, nCount)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    if nCategory ~= BattleItemCategoryDef.MATERIAL then
        return
    end
    local tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    if not IsPlayerSelfAndNotBot(tbPlayer) then
        return
    end
    local nPlayerId = tbPlayer:GetPlayerId()
    DecreaseMaterialPickupRecord(self, nPlayerId, nItemTemplateId, nCount)
end

-- 创建空投宝箱
local function OnEventCreateAirDropBox(self)
    self.nAirDropBoxCount = self.nAirDropBoxCount + 1
end

-- 跳伞结束
local function OnEventParachutionEnd(self, tbPlayer)
    local nPlayerId = tbPlayer:GetPlayerId()
    local tbRecord = GetOrCreatePickupRecord(self, nPlayerId)
    tbRecord.nParachutionEndTime = GlobalVariableSystem:GetLocalTime()
end

------------------------------------------------------------LogEventOpBase的接口---------------------------------------------------------

function BattleItemLogEventOpOld:Init()
    BattleItemLogEventOpOld.super.Init(self)
    self.tbItemCategoryPickupRecord = {}
end

function BattleItemLogEventOpOld:Uninit()
    BattleItemLogEventOpOld.super.Uninit(self)
end

--游戏开始时(选点界面弹出)触发
function BattleItemLogEventOpOld:OnBattleBegin()
    BattleItemLogEventOpOld.super.OnBattleBegin(self)
    InitPickupRecord(self)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_FINISH_SERVER, self, OnEventPickup)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_EQUIPED_SERVER, self, OnEventEquip)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_BUILD_FINISH_SERVER, self, OnEventBuild)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_THROW_AWAY_ITEM_FINISH_SERVER, self, OnEventThrowItem)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_CREATE_AIRDROP_BOX, self, OnEventCreateAirDropBox)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_FFA_PARACHUTION_END, self, OnEventParachutionEnd)
end

--游戏结束时(有队伍吃鸡或者副本回收)触发
function BattleItemLogEventOpOld:OnBattleEnd()
    LogWhenBattleEnd(self)
    ClearPickupRecord(self)
    BattleItemLogEventOpOld.super.OnBattleEnd(self)
end

return BattleItemLogEventOpOld