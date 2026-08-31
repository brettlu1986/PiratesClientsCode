local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleToastAction = luaclass("BattleToastAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local D2CHelper = require("D2CHelper")
local BattleBlackboard = require("BattleBlackboard")
local Proto = require("DungeonCommonProtoNames")
local BattleSpecialToastHelper = require("BattleSpecialToastHelper")

BattleToastAction.nId = nil
BattleToastAction.szParamKey0 = nil
BattleToastAction.szParamKey1 = nil
BattleToastAction.szParamKey2 = nil
BattleToastAction.ToastType = nil
BattleToastAction.nContinueTime = 0
BattleToastAction.nCampType = nil


function BattleToastAction:Parse(tbJsonData)
    self.nId = tbJsonData.Id
    self.szParamKey0 = tbJsonData.ParamKey0
    self.szParamKey1 = tbJsonData.ParamKey1
    self.szParamKey2 = tbJsonData.ParamKey2
    self.ToastType = tbJsonData.ToastType
    self.nContinueTime = tbJsonData.ContinueTime
    self.nCampType = tbJsonData.CampType or 0
    -- if self.nContinueTime <= 0 then
    --     self.nContinueTime = 3
    -- end

    return self.nId > 0
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

function BattleToastAction:Execute()

    local szParam0 = GetStringValue(self.szParamKey0)
    local szParam1 = GetStringValue(self.szParamKey1)
    local szParam2 = GetStringValue(self.szParamKey2)
    local szLog = string.format("Toast id: %d, param0: %s, param1: %s, param2: %s , ToastType: %d , WaitTime: %d ",
        self.nId,
        szParam0 ~= nil and szParam0 or "nil",
        szParam1 ~= nil and szParam1 or "nil",
        szParam2 ~= nil and szParam2 or "nil",
        self.ToastType,
        self.nContinueTime ~= nil and self.nContinueTime or 0)
   --
    BattleOperationHelper:PrintLog(self, szLog)

    if  self.ToastType == Proto.BattleToastInfo_EToastType.COMMON then
        D2CHelper:MulticastBattleToast(self.nId,
            szParam0, szParam1, szParam2, Proto.BattleToastInfo_EToastType.COMMON, self.nContinueTime)
    else
        BattleSpecialToastHelper:ShowSpecialToast(nil, self.nId,
            szParam0, szParam1, szParam2,Proto.BattleToastInfo_EToastType.SPECIAL, self.nCampType, self.nContinueTime, 0, 0)
    end
    return true
end

return BattleToastAction