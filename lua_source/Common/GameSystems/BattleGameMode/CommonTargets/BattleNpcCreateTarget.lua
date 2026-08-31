-- 当NPC创建时触发
local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleNpcCreateTarget = luaclass("BattleNpcCreateTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleNpcHelper = require("BattleNpcHelper")


function BattleNpcCreateTarget:Init()
    BattleNpcCreateTarget.super.Init(self)
    self.szName = "BattleNpcCreateTarget"    
end

function BattleNpcCreateTarget:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    return true
end

function BattleNpcCreateTarget:CheckAll()
    local tbGameObjects = GameObjectSystem:GetAllGameObjects()
    for _, GameObject in pairs(tbGameObjects) do
        if (BattleNpcHelper:CheckIdentifier(self, GameObject) and (not GameObject:IsDead())) then
            -- 还剩下满足要求的，跳出
            return true
        end
    end
    return false
end

function BattleNpcCreateTarget:OnActorCreate(tbGameObject)
    if(BattleNpcHelper:CheckIdentifier(self, tbGameObject)) then
        self:Complete()
    end
end

function BattleNpcCreateTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.OnActorCreate)
end

function BattleNpcCreateTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.OnActorCreate)
end

function BattleNpcCreateTarget:Start()
    BattleNpcCreateTarget.super.Start(self)

    if(self:CheckAll()) then
        self:Complete()
    end
end

return BattleNpcCreateTarget
