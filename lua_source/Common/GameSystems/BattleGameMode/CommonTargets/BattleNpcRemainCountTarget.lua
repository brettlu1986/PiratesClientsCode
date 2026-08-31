-- 指定类型Npc剩余数量

local luaclass = require("luaclass")
local BattleTargetBase = require("BattleTargetBase")
local BattleNpcRemainCountTarget = luaclass("BattleNpcRemainCountTarget", BattleTargetBase)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleNpcHelper = require("BattleNpcHelper")


function BattleNpcRemainCountTarget:Init()
    BattleNpcRemainCountTarget.super.Init(self)
    self.szName = "BattleNpcRemainCountTarget"
end

function BattleNpcRemainCountTarget:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nCount = tbJsonData.Count
    return true
end

function BattleNpcRemainCountTarget:CheckAll()    
    local nCurrentCount = 0
    local tbGameObjects = GameObjectSystem:GetAllGameObjects()
    for _, GameObject in pairs(tbGameObjects) do
        if(BattleNpcHelper:CheckIdentifier(self, GameObject) and (not GameObject:IsDead())) then
            nCurrentCount = nCurrentCount + 1
        end
    end

    if(nCurrentCount <= self.nCount) then
        return true
    end

    return false
end

function BattleNpcRemainCountTarget:OnPawnDead(DeadGameNpc)
    if(self:CheckAll()) then
        self:Complete()
    end
end

function BattleNpcRemainCountTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
end

function BattleNpcRemainCountTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
end

function BattleNpcRemainCountTarget:Start()
    BattleNpcRemainCountTarget.super.Start(self)

    if(self:CheckAll()) then
        self:Complete()
    end
end

return BattleNpcRemainCountTarget
