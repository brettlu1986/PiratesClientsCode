-----------------------------------------------------
--File Name    : GuideActionTextGuide.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionTextGuide              = require("GuideActionTextGuide")
local GuideActionWaitDungonTextGuide    = luaclass("GuideActionWaitDungonTextGuide",GuideActionTextGuide)

local ClientEventDef    = require("ClientEventDef")
----------------------------------------------------------

function GuideActionWaitDungonTextGuide:BindEvent()
    GuideActionWaitDungonTextGuide.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_PRE_LEVEL_LOBBY, self, self.OnWaitingDungeon)
end

function GuideActionWaitDungonTextGuide:OnWaitingDungeon()
    self:DebugLog("OnWaitingDungeon")
    self:EndAction()
end

return GuideActionWaitDungonTextGuide
