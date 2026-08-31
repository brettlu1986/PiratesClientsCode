-----------------------------------------------------
--File Name    : GuideActionOpenAim.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideActionFunctional = require("GuideActionFunctional")
local GuideActionOpenAim    = luaclass("GuideActionOpenAim",GuideActionFunctional)

local ClientEventDef        = require("ClientEventDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")

GuideActionOpenAim.szFireType = ""

function GuideActionOpenAim:DoAction(tbTemplate)
    GuideActionOpenAim.super.DoAction(self, tbTemplate)
    self.szFireType = tostring(tbTemplate.tbParam[1])
    if self.szFireType == "begin" then
        self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)  
        local PlayerSelf = GamePlayerSelfHelper:Get()
        PlayerSelf.HumanMovementStateComponent.bLastCrawlAim = false
    end
end

return GuideActionOpenAim
