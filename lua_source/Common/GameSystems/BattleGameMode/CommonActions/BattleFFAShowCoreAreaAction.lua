local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleFFAShowCoreAreaAction = luaclass("BattleFFAShowCoreAreaAction", BattleActionBase)
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
-- local BattleOperationHelper = require("BattleOperationHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

function BattleFFAShowCoreAreaAction:Parse(tbJsonData)
    return true
end

function BattleFFAShowCoreAreaAction:Execute()
    -- BattleOperationHelper:PrintLog(self, "DialogId: "..self.nDialogId)

    local tbPacket = {}
    tbPacket.bShowDialog = true
    NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_FFAShowCoreArea, tbPacket, false)
    
    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    if tbSetting and tbSetting.SetCoreAreaOpen then
        tbSetting:SetCoreAreaOpen()
    end

    return true
end

return BattleFFAShowCoreAreaAction