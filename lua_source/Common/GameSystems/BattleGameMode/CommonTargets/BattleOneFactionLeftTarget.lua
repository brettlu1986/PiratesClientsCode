-- 只剩一个阵营时时达到目标

local luaclass = require("luaclass")
local BattleTargetBase = require("BattleTargetBase")
local BattleOneFactionLeftTarget = luaclass("BattleOneFactionLeftTarget", BattleTargetBase)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleTeamSystem = require("BattleTeamSystem")


function BattleOneFactionLeftTarget:Init()
    BattleOneFactionLeftTarget.super.Init(self)
    self.szName = "BattleOneFactionLeftTarget"
end

function BattleOneFactionLeftTarget:Parse(tbJsonData)
    return true
end

function BattleOneFactionLeftTarget:CheckOneFactionLeft(LogoutPlayer)    
    local nFaction = nil

    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    for _, tbTeam in pairs(tbTeams) do
        for _, tbObject in pairs(tbTeam.tbGameObjects) do
            if not tbObject:IsDead() then
                if not (LogoutPlayer ~= nil and tbObject.nPlayerId == LogoutPlayer.nPlayerId) then
                    if nFaction == nil then 
                        nFaction =  tbObject.tbPrepareInfo.nFaction                      
                    end
                    if nFaction ~= nil and nFaction ~= tbObject.tbPrepareInfo.nFaction then
                        return false
                    end
                end
            end
        end
    end
    if nFaction ~= nil then 
        return true
    end 

    return false
end

function BattleOneFactionLeftTarget:OnPawnDead(DeadActor)
    if(self:CheckOneFactionLeft()) then
        self:Complete()
    end
end

function BattleOneFactionLeftTarget:OnLogout(tbGamePlayer)
    if(self:CheckOneFactionLeft(tbGamePlayer)) then
        self:Complete()
    end
end

function BattleOneFactionLeftTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

function BattleOneFactionLeftTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)   
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

function BattleOneFactionLeftTarget:Start()
    BattleOneFactionLeftTarget.super.Start(self)

    if(self:CheckOneFactionLeft()) then
        self:Complete()
    end
end

return BattleOneFactionLeftTarget
