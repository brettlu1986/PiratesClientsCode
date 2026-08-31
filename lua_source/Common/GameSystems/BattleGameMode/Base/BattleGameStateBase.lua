local luaclass = require("luaclass")
local BattleGameStateBase = luaclass("BattleGameStateBase")

local ReplicatedPropertyContainerClass = require("ReplicatedPropertyContainer")
local Proto = require("DungeonRepProtoNames")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

BattleGameStateBase.pGameState = nil
BattleGameStateBase.PropertyContainer = nil -- 纯服务器用
BattleGameStateBase.nStepIndex = 1
BattleGameStateBase.fnGetServerTime = nil

function BattleGameStateBase:Init(pGameState)
    self.pGameState = pGameState
    self.fnGetServerTime = pGameState.GetServerWorldTimeSeconds
    self.PropertyContainer = ReplicatedPropertyContainerClass()
    self.PropertyContainer:Init(pGameState, true, self)

    self:DefineStepIds()

    if(GlobalVariableSystem:IsServerLogic()) then
        self:DefineProperties()
    end
end

function BattleGameStateBase:DefineProperties()
    self:DefineProtoProperty(Proto.rGameStateBaseInfo)
    self:DefineProtoProperty(Proto.rCurrentStepInfo)
end

function BattleGameStateBase:GetServerTimeUtc()
    return self.fnGetServerTime(self.pGameState)
end

function BattleGameStateBase:DefineStepIds()
end

function BattleGameStateBase:Uninit()
    self.PropertyContainer:Uninit()
    self.PropertyContainer = nil
    self.pGameState = nil
end

function BattleGameStateBase:DefineProtoProperty(szProtoName)
    local rProperty = self.PropertyContainer:DefineProtoProperty(szProtoName)
    self[szProtoName] = rProperty
    return rProperty
end

function BattleGameStateBase:BindProperty(nNameIndex, DefaultValue, tbObject, fnOnChanged, bNotifyOnServer)
    return self.PropertyContainer:BindMethod(nNameIndex, DefaultValue, tbObject, fnOnChanged, bNotifyOnServer)
end

function BattleGameStateBase:DefineStepId(szIdName)
    local nRet = self.nStepIndex
    self.nStepIndex = nRet + 1
    self[szIdName] = nRet
    log("BattleGameStateBase:DefineStepId", szIdName, nRet)    
end

function BattleGameStateBase:ReplicateNow()
    self.PropertyContainer:ReplicateNow()
end

function BattleGameStateBase:ReplicateAll(bRepNow)
    self.PropertyContainer:ReplicateAll(bRepNow)
end

function BattleGameStateBase:ReplicateAllToPlayer(tbGamePlayer)
    self.PropertyContainer:ReplicateAllToActor(tbGamePlayer.pUEController)
end

return BattleGameStateBase
