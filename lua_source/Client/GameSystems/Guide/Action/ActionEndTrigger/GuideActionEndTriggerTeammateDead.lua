-----------------------------------------------------
--File Name    : GuideActionEndTriggerTeammateDead.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerTeammateDead         = luaclass("GuideActionEndTriggerTeammateDead", GuideActionEndTriggerBase)

local ClientEventDef            = require("ClientEventDef")
local TeamWatchClientHelper     = require("TeamWatchClientHelper")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local Proto                     = require("DungeonCommonProtoNames")
-----------------------------------------------------
local EState            = Proto.TeamInfo_EState
local tbCurrentDyingObj = {}
-----------------------------------------------------

local function TeamInfoChanged(self, tbBattleTeamInfo)
    local nPlayerSelfInsId = GamePlayerSelfHelper:GetServerInstanceId()
    local tbOriginalTeam = TeamWatchClientHelper.GetOriginalTeamInfo()
    --当前重伤队员死亡
    for k, v in ipairs(tbOriginalTeam) do
        if v.nState == EState.OFFLINE or v.nState == EState.DEAD then
            if nPlayerSelfInsId ~= v.nInstanceId and tbCurrentDyingObj[v.nInstanceId] == true then  
                tbCurrentDyingObj[v.nInstanceId] = false
                self:Triggered()
                return
            end
        end
    end
end

function GuideActionEndTriggerTeammateDead:BindEvent(tbParam)
    GuideActionEndTriggerTeammateDead.super.BindEvent(self, tbParam)
    local tbOriginalTeam = TeamWatchClientHelper.GetOriginalTeamInfo()
    tbCurrentDyingObj = {}
    local bTeamOtherDead = true
    local nPlayerSelfInsId = GamePlayerSelfHelper:GetServerInstanceId()
    for k, v in ipairs(tbOriginalTeam) do
        tbCurrentDyingObj[v.nInstanceId] = v.nState == EState.DYING
        if nPlayerSelfInsId ~= v.nInstanceId and v.nState ~= EState.DEAD and v.nState ~= EState.OFFLINE and bTeamOtherDead then   
            bTeamOtherDead = false
        end
    end

    if bTeamOtherDead then  
        self:Triggered()
    else 
        self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, TeamInfoChanged)
    end
end

return GuideActionEndTriggerTeammateDead
