-----------------------------------------------------
--File Name    : GuideActionStopHumanMove.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionStopHumanMove  = luaclass("GuideActionStopHumanMove",GuideActionFunctional)

--import
local ClientEventDef        = require("ClientEventDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")

GuideActionStopHumanMove.bExecPoint = false

local function StopHumanMove(self)
    self:DebugLog("StopHumanMove")
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local bisHuman = tbPlayerSelf:IsHuman()
    if not bisHuman then
        return
    end
    local pUEActor = tbPlayerSelf.pUEActor
    if pUEActor ~= nil then
        local tbInputComponent = pUEActor.PlayerInputComponent
        if tbInputComponent ~= nil then
            tbInputComponent:StopMoveImmediately()
            self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_FORCE_END_MOVE)
        end
    end
end

function GuideActionStopHumanMove:PreEnd()
    GuideActionStopHumanMove.super.PreEnd(self)
    if not self.bExecPoint then
        self:DebugLog("PreEnd")
        StopHumanMove(self)
    end
end

function GuideActionStopHumanMove:DoAction(tbTemplate)
    GuideActionStopHumanMove.super.DoAction(self, tbTemplate)
    local tbParam = tbTemplate.tbParam
    self.bExecPoint = tbParam[1] == "begin"
    if tbParam and tbParam[1] == "begin" then
        StopHumanMove(self) 
    end
end


return GuideActionStopHumanMove
