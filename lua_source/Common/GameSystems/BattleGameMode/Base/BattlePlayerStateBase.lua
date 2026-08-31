local luaclass = require("luaclass")
local BattlePlayerStateBase = luaclass("BattlePlayerStateBase")

local ReplicatedPropertyContainerClass = require("ReplicatedPropertyContainer")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

BattlePlayerStateBase.pPlayerState = nil
BattlePlayerStateBase.PropertyContainer = nil -- 纯服务器用


function BattlePlayerStateBase:Init( pPlayerState )
    self.pPlayerState = pPlayerState
    self.PropertyContainer = ReplicatedPropertyContainerClass()
    self.PropertyContainer:Init(pPlayerState, false, self)

    if(GlobalVariableSystem:IsServerLogic()) then
        self:DefineProperties()
    end
end


function BattlePlayerStateBase:DefineProperties()
   
end

function BattlePlayerStateBase:Uninit()
    self.PropertyContainer:Uninit()
    self.PropertyContainer = nil
    self.pPlayerState = nil
end

function BattlePlayerStateBase:DefineProtoProperty(szProtoName)
    local rProperty = self.PropertyContainer:DefineProtoProperty(szProtoName)
    self[szProtoName] = rProperty
    return rProperty
end

return BattlePlayerStateBase