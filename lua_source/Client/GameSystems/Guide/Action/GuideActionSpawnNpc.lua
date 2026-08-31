-----------------------------------------------------
--File Name    : GuideActionSpawnNpc.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideActionFunctional = require("GuideActionFunctional")
local GuideActionSpawnNpc   = luaclass("GuideActionSpawnNpc",GuideActionFunctional)

local ClientEventDef = require("ClientEventDef")

function GuideActionSpawnNpc:DoAction(tbTemplate)
    GuideActionSpawnNpc.super.DoAction(self, tbTemplate)
    self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_DUNGEON_SPAWN_NPC)
end

return GuideActionSpawnNpc
