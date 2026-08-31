-- 训练营定期移除道具step

local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local TrainingCampRemoveItemStep = luaclass("TrainingCampRemoveItemStep", BattleTargetActionStep)

local BattleItemSystemServer = require("BattleItemSystemServer")
local CommonEventDef = require("CommonEventDef")
local Timer = require("Timer")

local tbCheckTimer = nil
local nRemoveTime = 10

local tbPendingRemoveItemsMap = nil --Key InstanceId, Value remainingTime

local INTERVAL_CHECK_TIME = 1

--local function
--[[
local function LOG(...)
    log("TrainingCampRemoveItemStep: ", ...)
end
]]

local function OnIntervalCheck(self)
    for nInstanceId, nTime in pairs(tbPendingRemoveItemsMap) do
        nTime = nTime - INTERVAL_CHECK_TIME

        if nTime > 0 then
            tbPendingRemoveItemsMap[nInstanceId] = nTime
        else
            tbPendingRemoveItemsMap[nInstanceId] = nil

            BattleItemSystemServer:RemoveSceneItem(nInstanceId)
        end
    end
end

local function StartCheckTimer(self)
    tbCheckTimer = Timer.NewTimerMethod(self, OnIntervalCheck, INTERVAL_CHECK_TIME, true)
end

local function ClearCheckTimer(self)
    if tbCheckTimer then
        tbCheckTimer:Clear()
        tbCheckTimer = nil
    end
end

local function OnSceneItemAdd(self, tbItem, nX, nY, nZ)
    -- 上一个拥有者不是nil，说明是丢弃的物品
    if(tbItem:GetLastOwnerCharacterInstanceId() > 0) then
        local nInstanceId = tbItem:GetInstanceId()
        tbPendingRemoveItemsMap[nInstanceId] = nRemoveTime
    end
end

local function OnSceneItemRemove(self, nInstanceId, nItemTemplateId)
    --被捡走了
    if tbPendingRemoveItemsMap[nInstanceId] then
        tbPendingRemoveItemsMap[nInstanceId] = nil
    end
end

--拾取数量超过背包限制时，遗留在地上的道具也要清理掉
local function OnItemPickupRemain(self, tbRemainItem)
    local nInstanceId = tbRemainItem:GetInstanceId()
    tbPendingRemoveItemsMap[nInstanceId] = nRemoveTime
end
-------------------------------------------------------------


--public function.
function TrainingCampRemoveItemStep:Init()
    TrainingCampRemoveItemStep.super.Init(self)

    self.szName = "TrainingCampRemoveItemStep"
    tbPendingRemoveItemsMap = {}
end

function TrainingCampRemoveItemStep:Parse(tbJsonData)
    if(not TrainingCampRemoveItemStep.super.Parse(self, tbJsonData)) then
        return false
    end

    nRemoveTime = tbJsonData.RemoveTime
    return true
end

function TrainingCampRemoveItemStep:RegisterEvent()
    TrainingCampRemoveItemStep.super.RegisterEvent(self)

    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_SCENE_ITEM_ADD,    self, OnSceneItemAdd)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_SCENE_ITEM_REMOVE, self, OnSceneItemRemove)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_REMAIN_SERVER, self, OnItemPickupRemain)
end

function TrainingCampRemoveItemStep:UnregisterEvent()
    TrainingCampRemoveItemStep.super.UnregisterEvent(self)
end

function TrainingCampRemoveItemStep:Start()
    TrainingCampRemoveItemStep.super.Start(self)

    StartCheckTimer(self)
end

function TrainingCampRemoveItemStep:Uninit()
    TrainingCampRemoveItemStep.super.Uninit(self)

    ClearCheckTimer(self)
end

function TrainingCampRemoveItemStep:ForceStop()
    TrainingCampRemoveItemStep.super.ForceStop(self)
    ClearCheckTimer(self)
end

function TrainingCampRemoveItemStep:OnCompleted()
    TrainingCampRemoveItemStep.super.OnCompleted(self)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function TrainingCampRemoveItemStep:SnapshotToReplicatedProperty()
    return true
end

return TrainingCampRemoveItemStep