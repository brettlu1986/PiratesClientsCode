-----------------------------------------------------
--File Name    : GuideActionSelectResIcon.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                         = require("luaclass")
local GuideActionFunctional            = require("GuideActionFunctional")
local GuideActionDisenableSelectBorn   = luaclass("GuideActionDisenableSelectBorn", GuideActionFunctional)

local ClientEventDef    = require("ClientEventDef")
----------------------------------------------------------

----------------------------------------------------------

function GuideActionDisenableSelectBorn:DoAction(tbTemplate)
    GuideActionDisenableSelectBorn.super.DoAction(self, tbTemplate)
    local EventHelper = self.EventHelper
    local bDisenabel = tbTemplate.bEnable
    self:DebugLog("GuideActionDisenableSelectBorn:OnDelayTimerFunc bDisenabel = " .. tostring(bDisenabel))
    EventHelper:FireEvent(ClientEventDef.EV_FFA_SELECT_TRANSPORTER_SET_NOOB_DUNGEON, bDisenabel)
    EventHelper:FireEvent(ClientEventDef.EV_FFA_ENABLE_SELECTPOINT_MAP_PINCH, (not bDisenabel))
end

return GuideActionDisenableSelectBorn
