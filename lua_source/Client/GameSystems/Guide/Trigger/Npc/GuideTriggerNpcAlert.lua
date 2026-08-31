-----------------------------------------------------
--File Name    : GuideTriggerNpcAlert.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerNpcAlert = luaclass("GuideTriggerNpcAlert", GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GuideSharedInfoHelper = require("GuideSharedInfoHelper")

GuideTriggerNpcAlert.nLastAlertLevel = nil
local function CheckAlertLevelTrigger(self, tbGameObject)
    self:DebugLog("GuideTriggerNpcAlert:CheckAlertLevelTrigger",tbGameObject:GetName())
    local tbParam = self.tbTemplate.tbParam
    if not tbParam or #tbParam < 1 then
        return false
    end
    if not tbGameObject.NpcAIStateComponent then
        return false
    end
    local tbAlertTargetInstanceIds = tbGameObject.NpcAIStateComponent.tbAlertTargetInstanceIds
    if not tbAlertTargetInstanceIds or #tbAlertTargetInstanceIds == 0 then
        return false
    end
    local bAlert = tonumber(tbParam[1]) > 0 and true or false
    self:DebugLog("GuideTriggerNpcAlert:CheckAlertLevelTrigger,bAlert=",bAlert,tbAlertTargetInstanceIds[1],tbAlertTargetInstanceIds[2],GamePlayerSelfHelper:GetServerInstanceId())
    if bAlert then
        if tbAlertTargetInstanceIds[1] == GamePlayerSelfHelper:GetServerInstanceId() then
            return true
        end
    else
        if (tbAlertTargetInstanceIds[1] == 0 or tbAlertTargetInstanceIds[1] == nil) and tbAlertTargetInstanceIds[2] == GamePlayerSelfHelper:GetServerInstanceId() then
            return true
        end
    end
    return false
end

local function OnNpcAlertTargetChanged(self, tbGameObject, nTargetServerInstanceId)
    self:DebugLog("GuideTriggerNpcAlert:OnNpcAlertTargetChanged",tbGameObject:GetName())
    if CheckAlertLevelTrigger(self, tbGameObject) then
        GuideSharedInfoHelper.FillObjectNameToSharedInfo(self, tbGameObject)
        self:Trigger()
    end
end

local function CheckAllNpcAlertLevel(self)
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for k, v in pairs(tbObjects) do
        local nObjType = v:GetObjectType()
        if nObjType == GameObjectTypeDef.Npc and CheckAlertLevelTrigger(self, v)then
            GuideSharedInfoHelper.FillObjectNameToSharedInfo(self, v)
            self:Trigger()
        end
    end
end

--override
function GuideTriggerNpcAlert:Begin()
    GuideTriggerNpcAlert.super.Begin(self)
    CheckAllNpcAlertLevel(self)
end

function GuideTriggerNpcAlert:BindEvent(EventHelper)
    GuideTriggerNpcAlert.super.BindEvent(self, EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_NPC_RISKALERTTARGET_CHANGED, self, OnNpcAlertTargetChanged)
end

function GuideTriggerNpcAlert:IsTrigger()
    self.bIsTrigger = CheckAllNpcAlertLevel(self)
    return self.bIsTrigger
end


return GuideTriggerNpcAlert
