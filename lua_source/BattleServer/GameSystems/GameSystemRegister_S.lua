-- Register Managers those used for Common module

local luaclass = require("luaclass")
local GameSystemRegister = require("GameSystemRegister")
local GameSystemRegister_S = luaclass("GameSystemRegister_S", GameSystemRegister)

local ManagerGroupDef = require("ManagerGroupDef")

function GameSystemRegister_S:RegisterSubSystems(GameSystemManager)
    GameSystemRegister_S.super.RegisterSubSystems(self, GameSystemManager)

    local nDefaultGroupID = ManagerGroupDef.nDefaultGroupID
    local nBattleGroupID = ManagerGroupDef.nBattleGroupID
    if ServerShell.GetServer(GWorld):IsDungeonWithHub() then
        GameSystemManager:Register(nDefaultGroupID, dynamic_require("PingSystem"))
    else
        GameSystemManager:Register(nBattleGroupID, require("BattlePrepareMockSystem_S"))
    end
    GameSystemManager:Register(nBattleGroupID, require("GameTestAutomationSystemServer"))
    GameSystemManager:Register(nBattleGroupID, require("GPerfSystemServer"))
end

return GameSystemRegister_S
