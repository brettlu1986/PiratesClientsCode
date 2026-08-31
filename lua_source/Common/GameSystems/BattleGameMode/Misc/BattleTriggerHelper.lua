local BattleTriggerHelper = {}

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local LinkedList = require("LinkedList")

local tbTriggers = nil
local tbTriggerData = nil
local tbCallbacks = nil

local function CallCallback(self, nTriggerId, GameObject, bEnter)    
    local tbHead = tbCallbacks[nTriggerId]
    local Next = LinkedList.Next
    while(tbHead) do        
        tbHead.Value(nTriggerId, GameObject, bEnter)
        tbHead = Next(tbHead)
    end
end

local function OnEnterTrigger(self, Trigger, GameObject)
    local nTriggerId = Trigger.nTriggerId
    local tbObjects = tbTriggers[nTriggerId]
    if(nil == tbObjects) then
        tbObjects = {}
        tbTriggers[nTriggerId] = tbObjects
    end

    for i, v in ipairs(tbObjects) do
        if(v == GameObject) then
            return
        end
    end
    table.insert(tbObjects, GameObject)
    CallCallback(self, nTriggerId, GameObject, true)
end

local function OnLeaveTrigger(self, Trigger, GameObject)
    local nTriggerId = Trigger.nTriggerId
    local tbObjects = tbTriggers[nTriggerId]
    if(nil == tbObjects) then
        return
    end

    for i, v in ipairs(tbObjects) do
        if(v == GameObject) then
            table.remove(tbObjects, i)
            break
        end
    end

    CallCallback(self, nTriggerId, GameObject, false)
end

-- 死亡,离开副本算作离开trigger
local function OnSpecialLeave(self, GameObject)
    for TriggerId, tbTrigger in pairs(tbTriggers) do
        for i, Object in ipairs(tbTrigger) do
            if (Object == GameObject) then
                table.remove(tbTrigger, i)
                CallCallback(self, TriggerId, Object, false)
                break
            end
        end
    end
end

local function OnObjectDestroy(self, GameObject)
    if(GameObject.ObjectType == GameObjectTypeDef.Trigger) then
        tbTriggers[GameObject.nTriggerId] = nil
        tbCallbacks[GameObject.nTriggerId] = nil
    end
    OnSpecialLeave(self, GameObject)
end

local function OnPawnDead(self, tbDeadActor)
    OnSpecialLeave(self, tbDeadActor)
end


local function OnLogout(self, tbGamePlayer)
    OnSpecialLeave(self, tbGamePlayer)
end

function BattleTriggerHelper:AddCallback(nTriggerId, fnCallback)
    -- 这里搞成了链表，防止回调中删除callback引起调用错误
    assert(fnCallback ~= nil)

    local Head = tbCallbacks[nTriggerId]
    if(Head == nil) then
        tbCallbacks[nTriggerId] = LinkedList.New(fnCallback)
    else
        tbCallbacks[nTriggerId] = LinkedList.Add(Head, fnCallback)
    end
end

function BattleTriggerHelper:RemoveCallback(nTriggerId, fnCallback)
    assert(fnCallback ~= nil)
    local tbHead = tbCallbacks[nTriggerId]
    if(tbHead) then
        tbCallbacks[nTriggerId] = LinkedList.Remove(tbHead, fnCallback)
    end
end

function BattleTriggerHelper:GetObjectCount(nTriggerId)
    local tbObjects = tbTriggers[nTriggerId]
    if(tbObjects == nil) then
        return 0
    end

    return #tbObjects
end

function BattleTriggerHelper:GetObjects(nTriggerId)
    return tbTriggers[nTriggerId]
end

function BattleTriggerHelper:SetTriggerData(tbJsonData)
    if(tbJsonData) then
        for _, v in ipairs(tbJsonData) do
            tbTriggerData[v.TriggerId] = v
        end
    end
end

function BattleTriggerHelper:SpawnTrigger(nTriggerId)
    local tbJsonData = tbTriggerData[nTriggerId]
    if(tbJsonData == nil) then
        error("Spawn trigger failed, can not find triggerid: "..nTriggerId)
        return nil
    end
    local tbData = {tbJsonData = tbJsonData}
    return GameObjectSystem:CreateTriggerInGameMode(tbData)
end

function BattleTriggerHelper:SpawnAllTriggers()
    local tbRet = {}
    for _, v in pairs(tbTriggerData) do
        local tbData = {tbJsonData = v}
        local Trigger = GameObjectSystem:CreateTriggerInGameMode(tbData)
        table.insert(tbRet, Trigger)
    end
    return tbRet
end

function BattleTriggerHelper:Init(tbJsonData)
    tbTriggers = {}
    tbTriggerData = {}
    tbCallbacks = {}
    self:SetTriggerData(tbJsonData)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_DESTORY, self, OnObjectDestroy)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_TRIGGER_ENTER, self, OnEnterTrigger)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_TRIGGER_LEAVE, self, OnLeaveTrigger)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, OnLogout)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
end

function BattleTriggerHelper:Uninit()
    tbTriggers = nil
    tbTriggerData = nil
    tbCallbacks = nil
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_DESTORY, self, OnObjectDestroy)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_TRIGGER_ENTER, self, OnEnterTrigger)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_TRIGGER_LEAVE, self, OnLeaveTrigger)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, OnLogout)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
end


return BattleTriggerHelper