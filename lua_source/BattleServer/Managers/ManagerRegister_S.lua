-- Register Managers those used for Common module

local luaclass = require("luaclass")
local ManagerRegister = require("ManagerRegister")
local ManagerRegister_S = luaclass("ManagerRegister_S", ManagerRegister)

local ManagerGroupDef = require("ManagerGroupDef")

function ManagerRegister_S:RegisterManagers(ManagerRoot)
    ManagerRegister_S.super.RegisterManagers(self, ManagerRoot)

    local nDefaultGroupID = ManagerGroupDef.nDefaultGroupID
    ManagerRoot:RegisterByGroup(nDefaultGroupID, require("NetPlayerManager_S"))
    ManagerRoot:RegisterByGroup(nDefaultGroupID, require("HubSenderManager_S"))
    ManagerRoot:RegisterByGroup(nDefaultGroupID, require("GameResultManager_S"))
end


return ManagerRegister_S;
