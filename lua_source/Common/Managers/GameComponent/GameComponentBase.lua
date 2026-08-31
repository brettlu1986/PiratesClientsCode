-- 各种逻辑载体处理业务逻辑的基类，挂在GameObject中

local luaclass = require("luaclass")
local GameComponentBase = luaclass("GameComponentBase")

GameComponentBase.Owner = nil

-- 创建
function GameComponentBase:OnCreate(Owner, tbParams)
    self.Owner = Owner
    return true
end

-- 销毁
function GameComponentBase:OnDestroy()
end

function GameComponentBase:GetOwner()
    return self.Owner
end

function GameComponentBase:OnActorPreCreated(pUEActor)
end

function GameComponentBase:OnActorCreated(pUEActor)
end

function GameComponentBase:OnActorDestroyed(pUEActor)
end


return GameComponentBase
