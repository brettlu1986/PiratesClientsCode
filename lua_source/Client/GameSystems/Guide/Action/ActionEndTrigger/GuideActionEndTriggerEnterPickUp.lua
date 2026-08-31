-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerEnterPickUp      = luaclass("GuideActionEndTriggerEnterPickUp", GuideActionEndTriggerBase)

local ClientEventDef    = require("ClientEventDef")
local BattlePickTypeDef = require("BattlePickTypeDef")
-----------------------------------------------------

local function OnEnterPickUpTrigger(self, nPickType, nInstanceId)
    local szPickType = self.tbParam[1]
    local bResult = false
    if szPickType == "item" then
        bResult = nPickType == BattlePickTypeDef.ITEM
    elseif szPickType == "box" then
        bResult = nPickType == BattlePickTypeDef.BOX
    end
    self:DebugLog("OnEnterPickUpTrigger, bResult = " .. tostring(bResult))
    if bResult then
        self:Triggered()
    end
end

function GuideActionEndTriggerEnterPickUp:BindEvent(tbParam)
    GuideActionEndTriggerEnterPickUp.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_PICKUP_ENTER, self, OnEnterPickUpTrigger)
end

return GuideActionEndTriggerEnterPickUp
