-- Npc死亡

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleNpcDeadTarget = luaclass("BattleNpcDeadTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleNpcHelper = require("BattleNpcHelper")
local BattleBlackboard = require("BattleBlackboard")

BattleNpcDeadTarget.nCurrentCount = nil
BattleNpcDeadTarget.szSetDeadKey = nil
BattleNpcDeadTarget.szSetKillerKey = nil

function BattleNpcDeadTarget:Init()
    BattleNpcDeadTarget.super.Init(self)
    self.szName = "BattleNpcDeadTarget"    
end

function BattleNpcDeadTarget:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nCount = tbJsonData.Count
    self.szSetDeadKey = tbJsonData.SetDeadKey
    self.szSetKillerKey = tbJsonData.SetKillerKey

    return true
end

function BattleNpcDeadTarget:CheckAll()
    local tbGameObjects = GameObjectSystem:GetAllGameObjects()
    for _, GameObject in pairs(tbGameObjects) do
        if (BattleNpcHelper:CheckIdentifier(self, GameObject) and (not GameObject:IsDead())) then
            -- 还剩下满足要求的，跳出
            return false
        end
    end
    return true
end

function BattleNpcDeadTarget:OnPawnPostDie(DeadGameNpc)
    local tbDeadActorComponent = DeadGameNpc:GetCurrentPropertyComponent()
    local tbKillerActor = nil

    if tbDeadActorComponent then
        tbKillerActor = tbDeadActorComponent:GetLastDamageCauser()
    end
    
    local bComplete = false
    if(self.nCount == nil or self.nCount <= 0) then
        bComplete = self:CheckAll()
    else
        if(BattleNpcHelper:CheckIdentifier(self, DeadGameNpc)) then
            self.nCurrentCount = self.nCurrentCount + 1
            bComplete = self.nCurrentCount >= self.nCount
        end
    end

    if(bComplete) then
        if self.szSetDeadKey and string.len(self.szSetDeadKey) > 0 then
            BattleBlackboard:SetTable(self.szSetDeadKey, DeadGameNpc)
        end
        if self.szSetKillerKey and string.len(self.szSetKillerKey) > 0 then
            BattleBlackboard:SetTable(self.szSetKillerKey, tbKillerActor)
        end

        self:Complete()
    end
end

function BattleNpcDeadTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnPostDie)
end

function BattleNpcDeadTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnPostDie)
end

function BattleNpcDeadTarget:Start()
    self.nCurrentCount = 0

    BattleNpcDeadTarget.super.Start(self)    
end


return BattleNpcDeadTarget
