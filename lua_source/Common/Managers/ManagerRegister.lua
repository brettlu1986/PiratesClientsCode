-- Register Managers those used for Common module

local luaclass = require("luaclass")
local ManagerRegister = luaclass("ManagerRegister")

local ManagerGroupDef = require("ManagerGroupDef")

function ManagerRegister:RegisterManagers(ManagerRoot)
    local nImmortalGroupID = ManagerGroupDef.nImmortalGroupID
    ManagerRoot:RegisterByGroup(nImmortalGroupID, require("EventManager"))
    ManagerRoot:RegisterByGroup(nImmortalGroupID, require("ResourceManager"))
    ManagerRoot:RegisterByGroup(nImmortalGroupID, dynamic_require("NetworkManager"))
    ManagerRoot:RegisterByGroup(nImmortalGroupID, require("MessageProcessorManager"))    
    ManagerRoot:RegisterByGroup(nImmortalGroupID, require("GameSystemManager"))

    --local nBattleGroupID = ManagerRoot.nBattleGroupID
end

return ManagerRegister
