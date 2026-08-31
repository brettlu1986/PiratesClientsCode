-----------------------------------------------------
--File Name    : GuideTriggerEnterSceneTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerEnterSceneTrigger     = luaclass("GuideTriggerEnterSceneTrigger",GuideTrigger)

local CommonEventDef        = require("CommonEventDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local GameObjectTypeDef     = require("GameObjectTypeDef")
-----------------------------------------------------
GuideTriggerEnterSceneTrigger.nTriggerTemplateId = nil
-----------------------------------------------------
local function OnEnterTrigger(self, Owner, GameObj)
    if GameObj ~= GamePlayerSelfHelper:Get() then
        return
    end
    if Owner:GetObjectType() ~= GameObjectTypeDef.Trigger then
        return
    end
    local nTriggerId = nil
    local szTriggerId = self.tbTemplate.tbParam[1]
    if szTriggerId then
        nTriggerId = tonumber(szTriggerId)
    end
    self:DebugLog("rTrigger nTriggerId = " .. tostring(nTriggerId) .. " GameObj.nTriggerId =  " .. tostring(Owner.nTriggerId))
    if Owner.nTriggerId == nTriggerId or not nTriggerId then
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerEnterSceneTrigger:Begin()
    GuideTriggerEnterSceneTrigger.super.Begin(self)
    local szParam = self.tbTemplate.tbParam[1]
    if szParam then
        self.nTriggerTemplateId = tonumber(szParam)
    end
end

function GuideTriggerEnterSceneTrigger:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_ENTER, self, OnEnterTrigger)
end


return GuideTriggerEnterSceneTrigger
