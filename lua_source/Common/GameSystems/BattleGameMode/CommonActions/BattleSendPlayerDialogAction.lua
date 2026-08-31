local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSendPlayerDialogAction = luaclass("BattleSendPlayerDialogAction", BattleActionBase)
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleTeamSystem = require("BattleTeamSystem")

BattleSendPlayerDialogAction.nDialogId    = nil
BattleSendPlayerDialogAction.szParam1     = nil
BattleSendPlayerDialogAction.szParam2     = nil
BattleSendPlayerDialogAction.szGetObjKey = nil
BattleSendPlayerDialogAction.bAffectTeam = nil

function BattleSendPlayerDialogAction:Parse(tbJsonData)
    self.nDialogId    = tbJsonData.DialogId
    self.szParam1     = tbJsonData.ParamKey1 or ""
    self.szParam2     = tbJsonData.ParamKey2 or ""
    self.szGetObjKey  = tbJsonData.GetObjKey
    self.bAffectTeam  = tbJsonData.AffectTeam or false

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

function BattleSendPlayerDialogAction:Execute()
    BattleOperationHelper:PrintLog(self, "DialogId: "..self.nDialogId)

    local szParam1 = GetStringValue(self.szParam1)
    local szParam2 = GetStringValue(self.szParam2)

    local tbPacket = {}
    tbPacket.dialog_id = self.nDialogId 
    tbPacket.param1    = szParam1
    tbPacket.param2    = szParam2

    if self.szGetObjKey and string.len(self.szGetObjKey) > 0 then 
        local tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
        if tbPlayer then
            if self.bAffectTeam then
                local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
                for _, curIterPlayer in ipairs(tbTeamMembers) do
                    if not curIterPlayer:IsDead() then
                        NetworkManager:GetRPCNetworkProxy():SendToClient(curIterPlayer:GetUEControllerUniqueId(),ProtoDC.d2c_FFAShowDialog, tbPacket)
                    end
                end
            else
                NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(),ProtoDC.d2c_FFAShowDialog, tbPacket)
            end
        end
    end

    return true
end

return BattleSendPlayerDialogAction