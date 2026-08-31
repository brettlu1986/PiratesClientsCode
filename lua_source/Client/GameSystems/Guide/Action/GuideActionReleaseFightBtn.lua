-----------------------------------------------------
--File Name    : GuideActionReleaseFightBtn.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional         = require("GuideActionFunctional")
local GuideActionReleaseFightBtn    = luaclass("GuideActionReleaseFightBtn",GuideActionFunctional)

--import
local ClientEventDef        = require("ClientEventDef")
--local 

function GuideActionReleaseFightBtn:Begin()
    GuideActionReleaseFightBtn.super.Begin(self)
end

function GuideActionReleaseFightBtn:DoAction(tbTemplate)
    GuideActionReleaseFightBtn.super.DoAction(self, tbTemplate)
    self.EventHelper:FireEvent(ClientEventDef.EV_RELEASE_FIGHT_BTN)
end

return GuideActionReleaseFightBtn
