local luaclass = require("luaclass")
local MessageProcessorReigsterClass = require("MessageProcessorRegister")
local MessageProcessorRegister_S = luaclass("MessageProcessorRegister_S", MessageProcessorReigsterClass)

local Binder = require("ManagerGroupChangeBinder")
local ManagerGroupDef = require("ManagerGroupDef")

function MessageProcessorRegister_S:RegisterAllProcessors(ProcessorMgr)
    MessageProcessorRegister_S.super.RegisterAllProcessors(self, ProcessorMgr)

    local nBattleGroupID = ManagerGroupDef.nBattleGroupID
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("DungeonPacketProcessor_S")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("DungeonCppDelegateProcessor")))
end

return MessageProcessorRegister_S;
