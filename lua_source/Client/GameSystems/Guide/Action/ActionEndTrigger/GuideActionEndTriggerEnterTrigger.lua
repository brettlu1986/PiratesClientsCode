-----------------------------------------------------
--File Name    : GuideActionEndTriggerOnMovementChange.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerEnterTrigger         = luaclass("GuideActionEndTriggerEnterTrigger", GuideActionEndTriggerBase)

local CommonEventDef        = require("CommonEventDef")
local GameObjectTypeDef     = require("GameObjectTypeDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

local function OnEnterTrigger(self, Owner, GameObj)
    self:DebugLog("OnEnterTrigger")
    if GameObj ~= GamePlayerSelfHelper:Get() then
        return
    end
    if Owner:GetObjectType() ~= GameObjectTypeDef.Trigger then
        return
    end
    local nTriggerId = nil
    local szTriggerId = self.tbParam[1]
    if szTriggerId then
        nTriggerId = tonumber(szTriggerId)
    end
    if Owner.nTriggerId == nTriggerId or not nTriggerId then
        self:Triggered()
    end
end

function GuideActionEndTriggerEnterTrigger:BindEvent(tbParam)
    GuideActionEndTriggerEnterTrigger.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_ENTER, self, OnEnterTrigger)
end

return GuideActionEndTriggerEnterTrigger
