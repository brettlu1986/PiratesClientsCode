-- Pawn死亡时达到目标

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePawnDeadTarget = luaclass("BattlePawnDeadTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")

BattlePawnDeadTarget.nMaxDeadCount = 0
BattlePawnDeadTarget.nCurrentDeadCount = 0
BattlePawnDeadTarget.DeadGameObjectType = nil
BattlePawnDeadTarget.KillGameObjectType = nil

function BattlePawnDeadTarget:Init()
    BattlePawnDeadTarget.super.Init(self)
    self.szName = "BattlePawnDeadTarget"
end

--指定KillGameObjectType被谁杀，也可以不指定，DeadType不指定就是所有都认
function BattlePawnDeadTarget:SetParams(DeadGameObjectType, nMaxDeadCount, KillGameObjectType)
    self.DeadGameObjectType = DeadGameObjectType
    self.nMaxDeadCount = nMaxDeadCount
    self.KillGameObjectType = KillGameObjectType
    self.nCurrentDeadCount = 0
end

function BattlePawnDeadTarget:OnPawnDead(tbDeadActor)
    local DeadGameObjectType = self.DeadGameObjectType
    local KillGameObjectType = self.KillGameObjectType

    local tbKillerActor = nil--tbDeadActor.BattleStatusComponent:GetLastDamageCauser()
    if(DeadGameObjectType == nil or tbDeadActor.ObjectType == DeadGameObjectType) then
        if(KillGameObjectType == nil or tbKillerActor == nil or KillGameObjectType == tbKillerActor.ObjectType) then
            self.nCurrentDeadCount = self.nCurrentDeadCount + 1
            if(self.nCurrentDeadCount == self.nMaxDeadCount) then
                self:Complete()
            end
        end
    end
end

function BattlePawnDeadTarget:OnLogout(tbGamePlayer)
    if(not tbGamePlayer:IsDead()) then
        self:OnPawnDead(tbGamePlayer)
    end
end

function BattlePawnDeadTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

function BattlePawnDeadTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)   
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end


return BattlePawnDeadTarget
