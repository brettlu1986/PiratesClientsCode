-----------------------------------------------------
--File Name    : GuideTriggerPuzzleRightPos.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerPuzzleRightPos = luaclass("GuideTriggerPuzzleRightPos",GuideTrigger)

local ClientEventDef = require("ClientEventDef")


--override
function GuideTriggerPuzzleRightPos:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_PUZZLE_ITEM_IN_POSITION, self, self.OnRightPos)
end

function GuideTriggerPuzzleRightPos:OnRightPos()
    self:Trigger()
end

return GuideTriggerPuzzleRightPos
