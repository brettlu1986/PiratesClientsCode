-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionEndTriggerBase               = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerHorseUpBtn       = luaclass("GuideActionEndTriggerHorseUpBtn", GuideActionEndTriggerBase)

local ClientEventDef = require("ClientEventDef")
-----------------------------------------------------

local function HorseBtnVisible(self, bVisble)
    local szVisible = self.tbParam[1]
    self:DebugLog("HorseBtnVisible bVisble = " .. tostring(bVisble) .. " szVisible = " .. szVisible)
    if szVisible == "visible" and bVisble then
        self:Triggered()
    elseif szVisible == "invisible" and not bVisble then
        self:Triggered()
    end
end

function GuideActionEndTriggerHorseUpBtn:BindEvent(tbParam)
    GuideActionEndTriggerHorseUpBtn.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_ON_HORSE_BTN_UP_VISIBLE, self, HorseBtnVisible)
end

return GuideActionEndTriggerHorseUpBtn
