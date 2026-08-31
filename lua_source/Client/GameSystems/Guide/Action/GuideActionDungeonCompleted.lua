-----------------------------------------------------
--File Name    : GuideActionDungeonCompleted.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideActionFunctional = require("GuideActionFunctional")
local GuideActionDungeonCompleted = luaclass("GuideActionDungeonCompleted",GuideActionFunctional)

local ClientEventDef = require("ClientEventDef")

function GuideActionDungeonCompleted:DoAction(tbTemplate)
    GuideActionDungeonCompleted.super.DoAction(self, tbTemplate)
    self:CallShowBlackScreen(true)
    self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_DUNGEON_COMPLETED)
end

return GuideActionDungeonCompleted
