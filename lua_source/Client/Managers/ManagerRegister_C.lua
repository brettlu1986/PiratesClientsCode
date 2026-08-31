-- Register Managers those used for Common module

local luaclass = require("luaclass")
local ManagerRegister = require("ManagerRegister")
local ManagerRegister_C = luaclass("ManagerRegister_C", ManagerRegister)

local ManagerGroupDef = require("ManagerGroupDef")

function ManagerRegister_C:RegisterManagers(ManagerRoot)
    ManagerRegister_C.super.RegisterManagers(self, ManagerRoot)

    local nImmortalGroupID = ManagerGroupDef.nImmortalGroupID
    ManagerRoot:RegisterByGroup(nImmortalGroupID, require("ProcedureManager"))    
    ManagerRoot:RegisterByGroup(nImmortalGroupID, require("SoundManager"))
    ManagerRoot:RegisterByGroup(nImmortalGroupID, require("EffectManager"))

    local nDefaultGroupID = ManagerGroupDef.nDefaultGroupID
    ManagerRoot:RegisterByGroup(nDefaultGroupID, require("UIManager"))
    ManagerRoot:RegisterByGroup(nDefaultGroupID, require("RenderTargetManager"))

    --local nHubGroupID = ManagerGroupDef.nHubGroupID
end


return ManagerRegister_C;
