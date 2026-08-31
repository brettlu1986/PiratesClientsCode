local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleCountDownAction = luaclass("BattleCountDownAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")

BattleCountDownAction.nTime = 0

function BattleCountDownAction:Parse(tbJsonData)
    self.nTime = tbJsonData.Time
    
    return true
end

function BattleCountDownAction:Execute()
    BattleOperationHelper:PrintLog(self, "Time: "..self.nTime)

    if self.nTime > 0 then
        local tbPacket = {}
        tbPacket.countdown = self.nTime 
        NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_Countdown, tbPacket)
    end
    
    return true
end

return BattleCountDownAction