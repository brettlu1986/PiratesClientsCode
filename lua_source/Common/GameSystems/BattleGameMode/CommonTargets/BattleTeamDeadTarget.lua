-- 队伍死亡时达到目标

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleTeamDeadTarget = luaclass("BattleTeamDeadTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleTeamSystem = require("BattleTeamSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

BattleTeamDeadTarget.nDeadTeamId = -1
BattleTeamDeadTarget.bAllDead = false

function BattleTeamDeadTarget:Init()
    BattleTeamDeadTarget.super.Init(self)
    self.szName = "BattleTeamDeadTarget"
end

function BattleTeamDeadTarget:Parse(tbJsonData)
    return true
end

function BattleTeamDeadTarget:OnPawnDead(tbDeadActor)
    self:CheckDeadTeam(tbDeadActor)
    if(self.nDeadTeamId >= 0 or self.bAllDead) then
        log("BattleTeamDeadTarget:OnPawnDead team all die", self.nDeadTeamId, self.bAllDead)
        self:Complete()
    end
end

function BattleTeamDeadTarget:CheckDeadTeam(tbDeadObject)
    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    local nMemberCount, tbGamePlayer, nDeadCount, tbGameObjects
    self.bAllDead = true

    for nTeamId, tbTeam in pairs(tbTeams) do
        tbGameObjects = tbTeam.tbGameObjects
        nMemberCount = #tbGameObjects
        nDeadCount = 0
        for i=1, nMemberCount do
            tbGamePlayer = tbGameObjects[i]
            if(tbGamePlayer:IsDead() or tbGamePlayer == tbDeadObject) then
                nDeadCount = nDeadCount + 1
            end
        end

        if(nDeadCount >= nMemberCount) then
            self.nDeadTeamId = nTeamId
        else
            self.bAllDead = false
        end
    end
end

function BattleTeamDeadTarget:OnLogout(tbGamePlayer)
    if tbGamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        if(not tbGamePlayer:IsDead()) then
            self:OnPawnDead(tbGamePlayer)
        end
    end
end

function BattleTeamDeadTarget:RegisterEvent()
    -- 如果有复活，那么这里得加上复活消息    
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, self.OnLogout)
    -- 不使用EV_BATTLE_PLAYER_LOGOUT, 因为之前会销毁component，后面阶段得不到CampComponent信息, 
    -- 这里用EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY 替代OnLogout, 
    -- 如果先死亡后退出会走两遍,判断 if(not tbGamePlayer:IsDead()) then
    -- EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

function BattleTeamDeadTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)  
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, self.OnLogout)
end

return BattleTeamDeadTarget
