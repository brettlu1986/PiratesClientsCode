-- 只剩一个阵营时时达到目标

local luaclass = require("luaclass")
local BattleTargetBase = require("BattleTargetBase")
local BattleTeamRemainCountTarget = luaclass("BattleTeamRemainCountTarget", BattleTargetBase)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleTeamSystem = require("BattleTeamSystem")

BattleTeamRemainCountTarget.nTeamRemainCount = nil

function BattleTeamRemainCountTarget:Init()
    BattleTeamRemainCountTarget.super.Init(self)
    self.szName = "BattleTeamRemainCountTarget"
end

function BattleTeamRemainCountTarget:Parse(tbJsonData)
    self.nTeamRemainCount = tbJsonData.TeamRemainCount
    return true
end

function BattleTeamRemainCountTarget:CheckTeamRemainCount(LogoutPlayer)    
    local bTeamAlive = false
    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    local nTeamRemain = #tbTeams
    for _, tbTeam in pairs(tbTeams) do
        bTeamAlive = false
        for _, tbObject in pairs(tbTeam.tbGameObjects) do
            if not tbObject:IsDead() then
                if not (LogoutPlayer ~= nil and tbObject.nPlayerId == LogoutPlayer.nPlayerId) then
                    bTeamAlive = true
                    break
                end
            end
        end
        if not bTeamAlive then
            nTeamRemain = nTeamRemain - 1
        end
    end
    log("op- BattleTeamRemainCountTarget:CheckTeamRemainCount nTeamRemain:", nTeamRemain, " nTeamRemainCount: ", self.nTeamRemainCount)
    if nTeamRemain <= self.nTeamRemainCount then
        return true
    end
    return false
end

function BattleTeamRemainCountTarget:OnPawnDead(DeadActor)
    if(self:CheckTeamRemainCount()) then
        self:Complete()
    end
end

function BattleTeamRemainCountTarget:OnLogout(tbGamePlayer)
    if(self:CheckTeamRemainCount(tbGamePlayer)) then
        self:Complete()
    end
end

function BattleTeamRemainCountTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

function BattleTeamRemainCountTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)   
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

function BattleTeamRemainCountTarget:Start()
    BattleTeamRemainCountTarget.super.Start(self)

    if(self:CheckTeamRemainCount()) then
        self:Complete()
    end
end

return BattleTeamRemainCountTarget
