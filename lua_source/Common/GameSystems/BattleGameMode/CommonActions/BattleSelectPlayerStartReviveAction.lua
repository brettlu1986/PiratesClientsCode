local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSelectPlayerStartReviveAction = luaclass("BattleSelectPlayerStartReviveAction", BattleActionBase)

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local D2CHelper = require("D2CHelper")
local BattleSelectPlayerStartHelper = require("BattleSelectPlayerStartHelper")
local DelayTimer = require("DelayTimer")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

BattleSelectPlayerStartReviveAction.bUniquePoint = false
BattleSelectPlayerStartReviveAction.nGroupIndex = nil
BattleSelectPlayerStartReviveAction.nSubGroupIndex = nil
BattleSelectPlayerStartReviveAction.nCamp = nil
BattleSelectPlayerStartReviveAction.nBasicDelayTime = nil
BattleSelectPlayerStartReviveAction.nIncreaseDelayTime = nil
BattleSelectPlayerStartReviveAction.nIncreaseDeadCount = nil
BattleSelectPlayerStartReviveAction.nMaxDelayTime = nil
BattleSelectPlayerStartReviveAction.szGetObjKey = nil

function BattleSelectPlayerStartReviveAction:Parse(tbJsonData)    
    self.bUniquePoint = tbJsonData.UniquePoint
    self.nGroupIndex = tbJsonData.Group
    self.nSubGroupIndex = tbJsonData.SubGroup
    self.nCampType = tbJsonData.CampType
    self.nBasicDelayTime = tbJsonData.BasicDelayTime
    self.nIncreaseDelayTime = tbJsonData.IncreaseDelayTime
    self.nIncreaseDeadCount = tbJsonData.IncreaseDeadCount
    self.nMaxDelayTime = tbJsonData.MaxDelayTime
    self.szGetObjKey = tbJsonData.GetObjKey
    return true
end

local function GetPlayerDeadDelayTime(self, tbPlayer)
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbPlayerWaitRevive = tbGameMode.Setting.tbPlayerWaitRevive
    if tbPlayerWaitRevive == nil then
        return self.nBasicDelayTime
    end
    local nPlayerDeadCount = 0
    for _, tbPlayerRevive in ipairs(tbPlayerWaitRevive) do
        if tbPlayerRevive.tbPlayer == tbPlayer then
            nPlayerDeadCount = tbPlayerRevive.nDeadCount
        end
    end
    local nDelayTime = self.nBasicDelayTime
    if self.nIncreaseDelayTime and self.nIncreaseDeadCount and self.nIncreaseDeadCount > 0 then
        nDelayTime = math.floor(nPlayerDeadCount / self.nIncreaseDeadCount) * self.nIncreaseDelayTime + self.nBasicDelayTime
    end
    self.nMaxDelayTime = self.nMaxDelayTime > self.nBasicDelayTime and self.nMaxDelayTime or self.nBasicDelayTime
    if nDelayTime > self.nMaxDelayTime then
        nDelayTime = self.nMaxDelayTime
    end
    return nDelayTime
end

function BattleSelectPlayerStartReviveAction:Execute()    
    BattleOperationHelper:PrintLog(self, "GroupIndex: "..self.nGroupIndex..
    ", BasicDelayTime: "..self.nBasicDelayTime..
    ", IncreaseDelayTime: "..self.nIncreaseDelayTime..
    ", IncreaseDeadCount: "..self.nIncreaseDeadCount..
    ", MaxDelayTime: "..self.nMaxDelayTime)

    local tbPlayer = nil
    if self.szGetObjKey and string.len(self.szGetObjKey) > 0 then
        tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
    end 
    if tbPlayer == nil then
        BattleOperationHelper:PrintLog(self, "Can not find player from blackboard")
        return true
    end
    if not tbPlayer:IsDead() then
        BattleOperationHelper:PrintLog(self, "Can not revive becasue object is still alive, may be logout")
        return true
    end

    local NewPoint = BattleSelectPlayerStartHelper:PlayerSelectPoint(tbPlayer, self.bUniquePoint, self.nCampType, self.nGroupIndex, self.nSubGroupIndex)
    if NewPoint == nil then
        BattleOperationHelper:PrintError(self, "PlayerSelectPoint failed, can not find point")
        return false
    end

    local tbReviveTimer
    local fnRestart = function()
        -- revieve
        DelayTimer:ClearTimer(tbReviveTimer)
        tbReviveTimer = nil

        local tbTransform = NewPoint.Transform
        tbPlayer:Reborn(tbTransform.X, tbTransform.Y, tbTransform.Z, tbTransform.Yaw)
        D2CHelper:PlayerSetCameraYaw(tbPlayer, tbTransform.Yaw)

        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, tbPlayer)
    end
    
    local nReviveDelayTime = GetPlayerDeadDelayTime(self, tbPlayer)
    local tbPacket = {}
    tbPacket.countdown = nReviveDelayTime 
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_Countdown, tbPacket)
    
    tbReviveTimer = DelayTimer:DelayRun(fnRestart, nReviveDelayTime)
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbPlayerWaitRevive = tbGameMode.Setting.tbPlayerWaitRevive
    if tbPlayerWaitRevive == nil then
        tbPlayerWaitRevive = {}
    end
    -- 查找当前表如果玩家存在则赋值Timer
    local bInTable = false
    for _, tbPlayerRevive in ipairs(tbPlayerWaitRevive) do
        if tbPlayerRevive.tbPlayer == tbPlayer then
            -- 先清除老的timer
            if tbPlayerRevive.tbTimer ~= nil then
                DelayTimer:ClearTimer(tbPlayerRevive.tbTimer)
                tbPlayerRevive.tbTimer = nil
            end
            tbPlayerRevive.tbTimer = tbReviveTimer
            bInTable = true
        end
    end
    if not bInTable then
        local tbPlayerAndTimer = {}
        tbPlayerAndTimer.tbPlayer = tbPlayer
        tbPlayerAndTimer.tbTimer = tbReviveTimer
        tbPlayerAndTimer.tbPoint = NewPoint
        tbPlayerAndTimer.nDeadCount = 0
        table.insert( tbPlayerWaitRevive, tbPlayerAndTimer )    
    end

    return true
end


return BattleSelectPlayerStartReviveAction