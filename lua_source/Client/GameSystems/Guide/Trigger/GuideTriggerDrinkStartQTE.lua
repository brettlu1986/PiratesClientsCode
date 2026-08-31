-----------------------------------------------------
--File Name    : GuideTriggerDrinkStartQTE.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerDrinkStartQTE = luaclass("GuideTriggerDrinkStartQTE",GuideTrigger)

local ClientEventDef = require("ClientEventDef")


--override
function GuideTriggerDrinkStartQTE:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_DRINKING_STARTQTE, self, self.OnStartQTE)
end

function GuideTriggerDrinkStartQTE:OnStartQTE()
    self:Trigger()
end

return GuideTriggerDrinkStartQTE
