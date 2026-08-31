local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local CustomReplicationComponent = luaclass("CustomReplicationComponent", GameComponentBaseClass)

local ReplicateHelper = require("ReplicateHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local ReplicationBinder = require("ReplicationBinder")

CustomReplicationComponent.Helper = nil
CustomReplicationComponent.tbBindInfo = nil

-- local function OnValueChanged(tbProperty, NewValue)
--     logdebug("OnValueChanged, info:", tbProperty:GetDebugInfo())
-- end

-- local function Test(self)
--     if(not self.Owner:IsHuman()) then
--         return
--     end

--     local PropName = require("PropName")
--     local D = self.Bind
--     local b = D(self, PropName.bTestBool, true, OnValueChanged, true)
--     local n = D(self, PropName.nTestInt, 111, OnValueChanged, true)
--     local n1 = D(self, PropName.nTestInt1, 111, OnValueChanged, true)
--     local f = D(self, PropName.nTestFloat, 222.5, OnValueChanged, true)
--     local s = D(self, PropName.szTestString, "This is string", OnValueChanged, true)
--     -- local ab = D(self, "TestABool", T.ArrayBool, {true, false, true}, OnValueChanged, true)
--     -- local an = D(self, "TestAInt", T.ArrayInt, {1, 2}, OnValueChanged, true)
--     -- local af = D(self, "TestAFloat", T.ArrayFloat, {0.6}, OnValueChanged, true)
--     -- local as = D(self, "TestAString", T.ArrayString, {}, OnValueChanged, true)
--     local p = D(self, PropName.rTeamInfos,
--         { Teams = {
--             {nTeamId=1, tbPlayerIds={2,3}, tbInstanceIds={-6,-7}},
--             {nTeamId=2, tbPlayerIds={}, tbInstanceIds={}}
--         }}, OnValueChanged, true)

--     -- for k, v in pairs(self.Helper.tbPropertiesByName) do
--     --     logdebug("init value:", v:GetDebugInfo())
--     -- end

--     -- self:BindRPCRecvFunc(function(szType, nPlayerId, bTest, nTest, szTest, tbTest)
--     --     logdebug("Recv", szType, nPlayerId, bTest, nTest, szTest, require("dkjson").encode(tbTest))
--     -- end)

--     if(GlobalVariableSystem:IsServerLogic()) then
--         n:Set(333)
--         n1:Set(999)
--         --an:Set({3,5,6})

--         local DelayTimer = require("DelayTimer")
--         DelayTimer:DelayRun(function()
--             logdebug("--------------------------------------")
--             b:Set(false)
--             s:Set("asdfasdfasdfsf")
--             --af:Set({999,8})
--             p:Set({ Teams = {
--                 {nTeamId=3, tbPlayerIds={999,8}, tbInstanceIds={1}},
--             }})
--         end, 5)
--         DelayTimer:DelayRun(function()
--             logdebug("======================================")
--             f:Set(666.666)
--             s:Set("bbbbbb")
--             -- ab:Set({false, false, true})
--             -- as:Set({"safdfasdf", "ccccccccc"})
--         end, 10)

--         -- DelayTimer:DelayRun(function()
--         --     logdebug("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
--         --     local BPRPCType = require("BPRPCType")
--         --     local nPlayerId = self.Owner.nPlayerId
--         --     self:SendRPCRequest(BPRPCType.Multicast, "Multicast", nPlayerId, false, 111, "kkkkkkk", {"222", 8, false})
--         --     self:SendRPCRequest(BPRPCType.RunOnServer, "RunOnServer", nPlayerId, true, 222, "mmmm", {false})
--         --     self:SendRPCRequest(BPRPCType.RunOwningClient, "RunOwningClient", nPlayerId, false, 444, "ppp", {555})
--         -- end, 10)
--     end
-- end

function CustomReplicationComponent:OnActorPreCreated(pUEActor)
    CustomReplicationComponent.super.OnActorPreCreated(self, pUEActor)

    -- local nBindType = self.Owner:IsShip() and ReplicationBinder.TYPE_SHIP or ReplicationBinder.TYPE_HUMAN
    self.Helper = ReplicateHelper()
    self.tbBindInfo = ReplicationBinder.Bind(self.Helper, pUEActor, self, ReplicationBinder.TYPE_PAWN)
end

function CustomReplicationComponent:OnActorDestroyed(pUEActor)
    ReplicationBinder.Unbind(self.tbBindInfo, pUEActor)

    CustomReplicationComponent.super.OnActorDestroyed(self, pUEActor)
end

function CustomReplicationComponent:OnDestroy()
    ReplicationBinder.Unbind(self.tbBindInfo, self.Owner.pUEActor)
    CustomReplicationComponent.super.OnDestroy(self)
end


function CustomReplicationComponent:ResetAll()
    self.Helper:ResetAll()
end

function CustomReplicationComponent:OnRecvInvalidData(szInfo)
    BattleGameModeSystem:OnRecvInvalidData(self.Owner, szInfo)
end

function CustomReplicationComponent:Bind(nNameIndex, DefaultValue, fnOnChanged, bNotifyOnServer)
    return self.Helper:Bind(nNameIndex, DefaultValue, nil, fnOnChanged, bNotifyOnServer)
end

function CustomReplicationComponent:BindMethod(nNameIndex, DefaultValue, tbObject, fnOnChanged, bNotifyOnServer)
    return self.Helper:Bind(nNameIndex, DefaultValue, tbObject, fnOnChanged, bNotifyOnServer)
end

function CustomReplicationComponent:AddPostRepNotifyCallback(tbProperties, fnCallback)
    self.Helper:AddPostRepNotifyCallback(tbProperties, fnCallback)
end

function CustomReplicationComponent:IsValid()
    return self.Helper:IsValid()
end

return CustomReplicationComponent