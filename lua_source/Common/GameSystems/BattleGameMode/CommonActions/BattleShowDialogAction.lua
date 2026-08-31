local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleShowDialogAction = luaclass("BattleShowDialogAction", BattleActionBase)
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")

BattleShowDialogAction.nDialogId    = nil
BattleShowDialogAction.szParam1     = nil
BattleShowDialogAction.szParam2     = nil

function BattleShowDialogAction:Parse(tbJsonData)
    self.nDialogId    = tbJsonData.DialogId
    self.szParam1     = tbJsonData.ParamKey1 or ""
    self.szParam2     = tbJsonData.ParamKey2 or ""

    return true
end

local function GetStringValue(szKey)
    if(szKey == nil or string.len(szKey) == 0) then
        return nil
    end
    local Value = BattleBlackboard:GetRaw(szKey)
    if(Value) then
        Value = tostring(Value)
    end
    return Value
end

function BattleShowDialogAction:Execute()
    BattleOperationHelper:PrintLog(self, "DialogId: "..self.nDialogId)

    local szParam1 = GetStringValue(self.szParam1)
    local szParam2 = GetStringValue(self.szParam2)

    local tbPacket = {}
    tbPacket.dialog_id = self.nDialogId 
    tbPacket.param1    = szParam1
    tbPacket.param2    = szParam2

    NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_FFAShowDialog, tbPacket, false)
    
    return true
end

return BattleShowDialogAction