-----------------------------------------------------
--File Name    : GuideActionJoinTeam.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionBase               = require("GuideActionBase")
local GuideActionJoinTeam           = luaclass("GuideActionJoinTeam", GuideActionBase)

local ClientEventDef                = require("ClientEventDef")
local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local TeamSystem                    = require("TeamSystem")
--import

local function OnTeamSync(self)
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    local bInTeam = TeamSystem:IsInTeam()
    local bTeamLeader = TeamSystem:IsTeamLeader(nSelfPlayerId)
    self:DebugLog("OnTeamSync is in team = " .. tostring(bInTeam) .. " is team leader = " .. tostring(bTeamLeader))
    if bInTeam and not bTeamLeader then
        self:ForceEndCurrentGroup()
    end
end

function GuideActionJoinTeam:DoAction(tbTemplate)
    GuideActionJoinTeam.super.DoAction(self, tbTemplate)
    OnTeamSync(self)
end

function GuideActionJoinTeam:BindEvent()
    self:DebugLog("BindEvent")
    GuideActionJoinTeam.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_SYNC, self, OnTeamSync)
end

return GuideActionJoinTeam