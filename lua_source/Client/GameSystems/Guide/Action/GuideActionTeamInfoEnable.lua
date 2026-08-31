-----------------------------------------------------
--File Name    : GuideActionTeamInfoEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionFunctional             = require("GuideActionFunctional")
local GuideActionTeamInfoEnable         = luaclass("GuideActionTeamInfoEnable", GuideActionFunctional)

--import
local ClientEventDef        = require("ClientEventDef")
--local 

function GuideActionTeamInfoEnable:DoAction(tbTemplate)
    GuideActionTeamInfoEnable.super.DoAction(self, tbTemplate)
    local bEnable = tbTemplate.bEnable
    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_TEAM_INFO_ENABLE, bEnable)
end

return GuideActionTeamInfoEnable
