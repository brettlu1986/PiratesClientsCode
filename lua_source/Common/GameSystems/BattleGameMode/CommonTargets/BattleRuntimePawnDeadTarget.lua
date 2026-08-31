-- 任意时刻满足以下所有条件 Target 结束
-- 1. bCanComplete == true (通过SetCanComplete设置)
-- 2. (nMaxDeadCount == nil and bAllDead) or nMaxDeadCount == 0

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleRuntimePawnDeadTarget = luaclass("BattleRuntimePawnDeadTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")

BattleRuntimePawnDeadTarget.bAllDead = nil
BattleRuntimePawnDeadTarget.nMaxDeadCount = nil

BattleRuntimePawnDeadTarget.bCanComplete = nil
BattleRuntimePawnDeadTarget.tbPawns = nil

function BattleRuntimePawnDeadTarget:Init()
    BattleRuntimePawnDeadTarget.super.Init(self)
    self.szName = "BattleRuntimePawnDeadTarget"

    self.bAllDead = true
    self.bCanComplete = false
    self.tbPawns = {}
end

function BattleRuntimePawnDeadTarget:Reset()
    self.bAllDead = true
    self.tbPawns = {}
    self.bCanComplete = false
    self.nMaxDeadCount = nil
end

function BattleRuntimePawnDeadTarget:SetParams(nMaxDeadCount)
    self.nMaxDeadCount = nMaxDeadCount
end

local function LocalCheckComplete(self)
    if self.bCanComplete ~= true then
        return
    end

    if self.nMaxDeadCount ~= nil and self.nMaxDeadCount > 0 then
        return
    end

    if self.nMaxDeadCount == nil and self.bAllDead == false then
        return
    end
    self:Complete()
end

function BattleRuntimePawnDeadTarget:SetCanComplete(bCanComplete)
    self.bCanComplete = bCanComplete;
    LocalCheckComplete(self)
end

function BattleRuntimePawnDeadTarget:AddTargetPawn(tbPawn)
    table.insert(self.tbPawns, tbPawn)
    self.bAllDead = false
end

-- 从数组中删除所有等于tbElement的对象，返回删除个数
local function RemoveFromTable(tbTable, tbElement)
    local nCount = 0
    for i=#tbTable,1,-1 do
        if tbTable[i] == tbElement then
            table.remove(tbTable, i)
            nCount = nCount + 1
        end
    end
    return nCount
end

function BattleRuntimePawnDeadTarget:OnPawnDead(tbDeadActor)
    local nCount = RemoveFromTable(self.tbPawns, tbDeadActor)
    if nCount > 1 then
        logerror("BattleRuntimePawnDeadTarget:OnPawnDead pawn die remove pawn more than one!!", nCount)
    end
    if self.nMaxDeadCount ~= nil then
        self.nMaxDeadCount = self.nMaxDeadCount - nCount
    end
    self.bAllDead = (#self.tbPawns == 0)
    LocalCheckComplete(self)
end

function BattleRuntimePawnDeadTarget:OnLogout(tbGamePlayer)
    if(not tbGamePlayer:IsDead()) then
        self:OnPawnDead(tbGamePlayer)
    end
end

function BattleRuntimePawnDeadTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

function BattleRuntimePawnDeadTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)  
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

return BattleRuntimePawnDeadTarget
