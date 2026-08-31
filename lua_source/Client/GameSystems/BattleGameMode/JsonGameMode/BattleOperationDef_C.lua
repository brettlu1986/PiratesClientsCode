local luaclass = require("luaclass")
local BattleOperationDef = require("BattleOperationDef")
local BattleOperationDef_C = luaclass("BattleOperationDef_C", BattleOperationDef)

function BattleOperationDef_C:RegisterActions()
    BattleOperationDef_C.super.RegisterActions(self)

    local Register = self.Register
    Register("Action_Guide_C", "BattleGuideAction")
    Register("Action_LocalResult", "BattleLocalResultAction")
    Register("Action_HideBattleUI", "BattleHideBattleUIAction")
    Register("Action_LocalEscapeResult", "BattleLocalEscapeResultAction")
    Register("Action_LocalEscortResult", "BattleLocalEscortResultAction")
end

function BattleOperationDef_C:RegisterTargets()
    BattleOperationDef_C.super.RegisterTargets(self)

    local Register = self.Register
    Register("Target_PlayerSelfShipStatus_C", "BattlePlayerSelfShipStatusTarget")
    Register("Target_ClientGuideFinished", "BattleGuideFinishedTarget")
end

function BattleOperationDef_C:RegisterSettings()
    BattleOperationDef_C.super.RegisterSettings(self)

    local Register = self.Register
    Register("Setting_Local", "JGMLocalSetting")
end

return BattleOperationDef_C()