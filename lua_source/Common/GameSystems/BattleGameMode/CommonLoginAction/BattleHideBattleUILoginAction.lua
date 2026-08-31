local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleHideBattleUILoginAction = luaclass("BattleHideBattleUILoginAction", BattleActionBase)

local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local BattleBlackboard = require("BattleBlackboard")
local BattleOperationDef = dynamic_require("BattleOperationDef")

BattleHideBattleUILoginAction.bHide = false
BattleHideBattleUILoginAction.bPlayAnim = false

function BattleHideBattleUILoginAction:Parse(tbJsonData)
    self.bHide = tbJsonData.HideBattleUI
    self.bPlayAnim = tbJsonData.playAnim
    return self.bHide ~= nil and  self.bPlayAnim ~= nil
end

function BattleHideBattleUILoginAction:Execute()
    local tbPlayer = BattleBlackboard:GetTable(BattleOperationDef.CurrentObject)
    if tbPlayer ~= nil then
        local tbPacket = {}
        tbPacket.hide = self.bHide 
        tbPacket.play_anim = self.bPlayAnim 
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_HideBattleUI, tbPacket)
    end
    return true
end


return BattleHideBattleUILoginAction
