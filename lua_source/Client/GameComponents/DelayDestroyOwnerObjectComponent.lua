-- 现在在客户端actor被删除其实是区别不出来原因的（出同步范围、人船变换等），
-- 所以这会GameObject是不会被删除的，当一个人进入同步范围，gameobject就会被创建，但没法删，
-- 因为不知道这哥们到底该不该被删，这种情况就是gameobject越来越多。
-- 这个Component的作用就是当actor被删了，如果过了一段时间还没有新actor创建，那么则吧gameobject删掉

local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local DelayDestroyOwnerObjectComponent = luaclass("DelayDestroyOwnerObjectComponent", GameComponentBase)

local GlobalVariableSystem = require("GlobalVariableSystem_C")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local Timer = require("Timer")

DelayDestroyOwnerObjectComponent.DelayTimer = nil

local function OnDestroyOwnerObject(self)
    log("Delay destroy object", self.Owner.szName)
    GameObjectSystem:DestroyByInstanceId(self.Owner:GetServerInstanceId())
end

local function TryDestroyTimer(self)
    if(self.DelayTimer) then
        self.DelayTimer:Clear()
        self.DelayTimer = nil
    end
end

local function TryCreateTimer(self)
    local nTime = GlobalVariableSystem.nDelayDestroyGameObjectTime
    if(nTime >= 0) then
        log("Delay destroy object timer start", self.Owner.szName)
        self.DelayTimer = Timer.NewTimerMethod(self,
            OnDestroyOwnerObject,
            nTime,
            false,
            "Deley destroy owner "..self.Owner.szName)
    end
end

function DelayDestroyOwnerObjectComponent:OnActorCreated(pUEActor)
    DelayDestroyOwnerObjectComponent.super.OnActorCreated(self, pUEActor)

    TryDestroyTimer(self)
end

function DelayDestroyOwnerObjectComponent:OnActorDestroyed(pUEActor)
    DelayDestroyOwnerObjectComponent.super.OnActorDestroyed(self, pUEActor)

    TryDestroyTimer(self)
    TryCreateTimer(self)
end

function DelayDestroyOwnerObjectComponent:OnDestroy()
    DelayDestroyOwnerObjectComponent.super.OnDestroy(self)

    TryDestroyTimer(self)
end

return DelayDestroyOwnerObjectComponent