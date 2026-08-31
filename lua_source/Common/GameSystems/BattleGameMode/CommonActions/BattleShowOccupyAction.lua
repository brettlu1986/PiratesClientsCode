local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleShowOccupyAction = luaclass("BattleShowOccupyAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")

BattleShowOccupyAction.bVisible = false

function BattleShowOccupyAction:Parse(tbJsonData)
    self.bVisible = tbJsonData.Visible
    return true
end

function BattleShowOccupyAction:Execute()
    BattleOperationHelper:PrintLog(self, "Visible: "..(self.bVisible and "true" or "false"))

    local tbPacket = {}
    tbPacket.visible = self.bVisible 
    NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_ShowOccupy, tbPacket)

    return true
end

return BattleShowOccupyAction