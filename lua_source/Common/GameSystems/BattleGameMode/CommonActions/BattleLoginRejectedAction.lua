local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleLoginRejectedAction = luaclass("BattleLoginRejectedAction", BattleActionBase)
local BattleOperationHelper = require("BattleOperationHelper")
local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")

BattleLoginRejectedAction.nReason = nil

function BattleLoginRejectedAction:Parse(tbJsonData)
    self.nReason = tbJsonData.Reason
    return true
end

function BattleLoginRejectedAction:Execute()
    BattleOperationHelper:PrintLog(self, "Reason: "..self.nReason)

    local tbPacket = {}
    HubSenderManager:Multicast(HubProto.d2s_StopAcceptingNewPlayers, tbPacket)

    return true
end

return BattleLoginRejectedAction