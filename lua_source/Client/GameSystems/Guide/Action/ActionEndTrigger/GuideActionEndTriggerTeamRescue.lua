-----------------------------------------------------
--File Name    : GuideActionEndTriggerTeamRescue.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerTeamRescue           = luaclass("GuideActionEndTriggerTeamRescue", GuideActionEndTriggerBase)

local CommonEventDef            = require("CommonEventDef")
local TeamWatchClientHelper     = require("TeamWatchClientHelper")
-----------------------------------------------------

local nCurrentRescueId = -1
-----------------------------------------------------

local function OnDyingChanged(self, tbDyingOwner, bIsDying)
    local tbOriginalTeam = TeamWatchClientHelper.GetOriginalTeamInfo()
    for _,v in pairs(tbOriginalTeam) do  
        if nCurrentRescueId > 0 and v.nInstanceId == tbDyingOwner.nServerInstanceId 
            and not bIsDying then
            nCurrentRescueId = -1  
            self:Triggered()
            return
        end
    end
end

--当前队伍中有人在救人
local function OnRescuing(self, tbTaker, bIsRescuing)
    local tbOriginalTeam = TeamWatchClientHelper.GetOriginalTeamInfo()
    for _,v in pairs(tbOriginalTeam) do  
        if bIsRescuing and tbTaker.nServerInstanceId == v.nInstanceId then   
            nCurrentRescueId = v.nInstanceId
            break
        end
    end
end

function GuideActionEndTriggerTeamRescue:BindEvent(tbParam)
    GuideActionEndTriggerTeamRescue.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED, self, OnDyingChanged)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_RESCUING_CHANGED, self, OnRescuing)
end

return GuideActionEndTriggerTeamRescue
