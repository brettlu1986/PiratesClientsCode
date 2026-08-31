-----------------------------------------------------
--File Name    : GuideTriggerTeammateDying.lua
--Description  : 距离重伤队友一定距离触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerTeammateDying  = luaclass("GuideTriggerTeammateDying", GuideTrigger)

local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local TeamWatchClientHelper     = require("TeamWatchClientHelper")
local GameObjectSystem          = dynamic_require("GameObjectSystem")
local ActorTriggerGroupHelper   = require("ActorTriggerGroupHelper")
local CommonEventDef            = require("CommonEventDef")
local ClientEventDef            = require("ClientEventDef")
local Proto                     = require("DungeonCommonProtoNames")



-----------------------------------------------------
GuideTriggerTeammateDying.tbParam         = nil
GuideTriggerTeammateDying.nTriggerRadius  = nil

GuideTriggerTeammateDying.nTriggerGroup   = -1
GuideTriggerTeammateDying.tbDyingMark     = nil

local EState = Proto.TeamInfo_EState

local UPDATE_INTERVAL = 1
local TRIGGER_HEIGHT = 200
local RESET_GROUP = -1

-----------------------------------------------------
local function DestroyTriggers(self)
    if self.nTriggerGroup ~= RESET_GROUP then
        ActorTriggerGroupHelper.DestroyTriggerGroup(self.nTriggerGroup)
        self.nTriggerGroup = RESET_GROUP
    end
end

local function OnEnterInteractionalTrigger(self, nGroupId, tbOwnerObject, tbTargetObject)
    if nGroupId == self.nTriggerGroup then  
        local nPlayerSelfInsId = GamePlayerSelfHelper:GetServerInstanceId()
        if tbOwnerObject.nServerInstanceId == nPlayerSelfInsId then   
            self:Trigger()
            DestroyTriggers(self)
        end
    end
end

local function AddDyingTrigger(self, pDyingUEActor)
    if self.nTriggerGroup == RESET_GROUP then 
        local PlayerSelf = GamePlayerSelfHelper:Get()
        self.nTriggerGroup = ActorTriggerGroupHelper.CreateTriggerGroup(PlayerSelf.pUEActor, self.nTriggerRadius, UPDATE_INTERVAL, TRIGGER_HEIGHT)
    end

    if self.nTriggerGroup ~= RESET_GROUP then
        ActorTriggerGroupHelper.AddTriggerInGroup(self.nTriggerGroup, pDyingUEActor)
    end
end

local function TeamInfoChanged(self, tbBattleTeamInfo)
    local nPlayerSelfInsId = GamePlayerSelfHelper:GetServerInstanceId()
    local tbOriginalTeam = TeamWatchClientHelper.GetOriginalTeamInfo()
    
    for k, v in ipairs(tbOriginalTeam) do
        if v.nState == EState.DYING and nPlayerSelfInsId ~= v.nInstanceId and not self.tbDyingMark[v.nInstanceId]then  
            local pDyingPlayer = GameObjectSystem:FindByInstanceId(v.nInstanceId)
            if pDyingPlayer and pDyingPlayer.pUEActor then
                AddDyingTrigger(self, pDyingPlayer.pUEActor)
                self.tbDyingMark[v.nInstanceId] = true
            end
        end
    end
end


local function OnActorDestroy(self, tbGameObject)
    if tbGameObject == GamePlayerSelfHelper:Get() then
        DestroyTriggers(self, tbGameObject)
    end
end


function GuideTriggerTeammateDying:End()
    self.tbDyingMark = nil
    GuideTriggerTeammateDying.super.End(self)
    DestroyTriggers(self)
end

--override
function GuideTriggerTeammateDying:Begin()
    GuideTriggerTeammateDying.super.Begin(self)
    self.tbDyingMark = {}
    local tbParam = self.tbTemplate.tbParam 
    if tbParam and tbParam[1] then
        self.tbParam = tbParam
        self.nTriggerRadius = tonumber(tbParam[1]) --半径
    end
end

function GuideTriggerTeammateDying:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, TeamInfoChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_ENTER_TRIGER_GROUP, self, OnEnterInteractionalTrigger)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnActorDestroy)
end

return GuideTriggerTeammateDying
