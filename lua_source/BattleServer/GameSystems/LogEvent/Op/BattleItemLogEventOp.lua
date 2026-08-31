-----------------------------------------------------
--File Name    : BattleItemLogEventOp.lua
--Author       : zhiyuan
--Create Time  : 2019-11-28
--Description  : 战斗中道具相关的数据埋点
-----------------------------------------------------
local luaclass = require("luaclass")
local LogEventOpBase = dynamic_require("LogEventOpBase")
local BattleItemLogEventOp = luaclass("BattleItemLogEventOp", LogEventOpBase)

local AIHelper = require("AIHelper")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local Analytics = require("DungeonAnalyticsProtoNames")
local MaterialItemHelper = require("MaterialItemHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

-- 记录玩家跳伞落地时间
BattleItemLogEventOp.tbPlayerParachutionEndTime = nil
-----------------------------------------------------------local function--------------------------------------------------

local function LOG(...)
    log("[BattleItemLogEventOp]", ...)
end

-- 判断是不是玩家
local function IsPlayerSelfAndNotBot(tbPlayer)
    if tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf
         and not AIHelper.IsAIControlled(tbPlayer) then
        return true
    end
    return false
end

local function GetElapsedTime(self, nPlayerId)
    local nStartTime = self.tbPlayerParachutionEndTime[nPlayerId]

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

--------------------------------------------------------local log table 构造和发送-------------------------------------------------------------
-- 拾取
local function LogPickup(self, tbPlayer, nItemTemplateId, nCount, bInDeadBox)
    local nPlayerId = tbPlayer:GetPlayerId()
    local tbPacket = {}

    self:SavePlayerCommonPropertysToPacket(nPlayerId, tbPacket)

    tbPacket.template_id = nItemTemplateId
    tbPacket.category = self:GetBattleItemCategory(nItemTemplateId)
    tbPacket.count = nCount

    local nElapsedTime = GetElapsedTime(self, nPlayerId)
    if not nElapsedTime then -- 如果获取不到就不统计
        return
    end
    tbPacket.elapsed_time = nElapsedTime

    tbPacket.pick_type = Analytics.Pick_PickType.NORMAL
    if bInDeadBox then
        tbPacket.pick_type = Analytics.Pick_PickType.DEAD_BOX
    end

    self:LogEvent(Analytics.Pick, tbPacket)
    LOG("Analytics.Pick", t2s(tbPacket))
    return tbPacket
end

local function LogBuild(self, nPlayerId, nItemTemplateId, tbCosts)
    local tbPacket = {}

    self:SavePlayerCommonPropertysToPacket(nPlayerId, tbPacket)

    local tbMaterialCost = {}
    if tbCosts then
        for nIndex, nCount in pairs(tbCosts) do
            if nCount > 0 then
                local nMaterialTemplateId = MaterialItemHelper:GetMaterialTemplateId(nIndex)
                tbMaterialCost[nMaterialTemplateId] = nCount
            end
        end
    end

    tbPacket.material_cost = self:MapToString(tbMaterialCost, ",")
    tbPacket.template_id = nItemTemplateId
    tbPacket.item_type = self:GetBattleItemCategory(nItemTemplateId)
    local nElapsedTime = GetElapsedTime(self, nPlayerId)
    if not nElapsedTime then -- 如果获取不到就不统计
        return
    end
    tbPacket.elapsed_time = nElapsedTime
    self:LogEvent(Analytics.ItemBuild, tbPacket)
    LOG("Analytics.ItemBuild", t2s(tbPacket))
    return tbPacket
end

--------------------------------------------------------听事件的回调-------------------------------------------------------------

-- 拾取事件
local function OnEventPickup(self, tbPlayer, AddedItem, bSuccess, nRoomActorId, nCount, bInDeadBox)
    if not bSuccess then
        return
    end
    if not IsPlayerSelfAndNotBot(tbPlayer) then
        return
    end

    local nItemTemplateId = AddedItem:GetTemplateId()

    LogPickup(self, tbPlayer, nItemTemplateId, nCount, bInDeadBox)
end

-- 建造事件
local function OnEventBuild(self, tbPlayer, _, nItemTemplateId, tbCosts)
    if not IsPlayerSelfAndNotBot(tbPlayer) then
        return
    end
    local nPlayerId = tbPlayer:GetPlayerId()

    LogBuild(self, nPlayerId, nItemTemplateId, tbCosts)
end

-- 跳伞结束
local function OnEventParachutionEnd(self, tbPlayer)
    local nPlayerId = tbPlayer:GetPlayerId()
    self.tbPlayerParachutionEndTime[nPlayerId] = GlobalVariableSystem:GetLocalTime()
end

------------------------------------------------------------LogEventOpBase的接口---------------------------------------------------------

function BattleItemLogEventOp:Init()
    BattleItemLogEventOp.super.Init(self)
end

function BattleItemLogEventOp:Uninit()
    BattleItemLogEventOp.super.Uninit(self)
end

--游戏开始时(选点界面弹出)触发
function BattleItemLogEventOp:OnBattleBegin()
    BattleItemLogEventOp.super.OnBattleBegin(self)
    self.tbPlayerParachutionEndTime = {}
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_FINISH_SERVER, self, OnEventPickup)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_BUILD_FINISH_SERVER, self, OnEventBuild)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_FFA_PARACHUTION_END, self, OnEventParachutionEnd)
end

--游戏结束时(有队伍吃鸡或者副本回收)触发
function BattleItemLogEventOp:OnBattleEnd()
    self.tbPlayerParachutionEndTime = nil
    BattleItemLogEventOp.super.OnBattleEnd(self)
end

return BattleItemLogEventOp