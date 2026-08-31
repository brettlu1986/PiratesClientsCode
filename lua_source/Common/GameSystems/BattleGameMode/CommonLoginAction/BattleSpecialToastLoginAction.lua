local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSpecialToastLoginAction = luaclass("BattleSpecialToastLoginAction", BattleActionBase)

local L10N = require("L10N")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local Proto = require("DungeonRepProtoNames")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local GamePlayerTypeDef = require("GamePlayerTypeDef")

BattleSpecialToastLoginAction.nId = nil
BattleSpecialToastLoginAction.szParamKey0 = nil
BattleSpecialToastLoginAction.szParamKey1 = nil
BattleSpecialToastLoginAction.szParamKey2 = nil
BattleSpecialToastLoginAction.nToastType = nil
BattleSpecialToastLoginAction.nContinueTime = nil
BattleSpecialToastLoginAction.nCampType = nil

function BattleSpecialToastLoginAction:Parse(tbJsonData)
    self.nId = tbJsonData.Id
    self.szParamKey0 = tbJsonData.ParamKey0
    self.szParamKey1 = tbJsonData.ParamKey1
    self.szParamKey2 = tbJsonData.ParamKey2
    self.nToastType = tbJsonData.ToastType
    self.nContinueTime = tbJsonData.ContinueTime
    self.nCampType = tbJsonData.CampType or 0
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

local function ShowSpecialToast(rObjective,
    nServerInstanceId, nId, szParam0, szParam1, szParam2,
    eToastType, nCampType, nWaitTime)

    rObjective.nId = nId
    rObjective.szParam0 = szParam0
    rObjective.szParam1 = szParam1
    rObjective.szParam2 = szParam2
    rObjective.nToastType = eToastType
    rObjective.nWaitTime = nWaitTime
    rObjective.nServerInstanceId = nServerInstanceId
    rObjective.nCampType = nCampType
    rObjective.RepNowMulticast()
end

function BattleSpecialToastLoginAction:Execute()
    local szParam0 = GetStringValue(self.szParamKey0)
    local szParam1 = GetStringValue(self.szParamKey1)
    local szParam2 = GetStringValue(self.szParamKey2)
    local szLog = string.format("Toast id: %d, param0: %s, param1: %s, param2: %s , ToastType: %d  , CampType: %d , WaitTime: %d ",
        self.nId,
        szParam0 ~= nil and szParam0 or "nil",
        szParam1 ~= nil and szParam1 or "nil",
        szParam2 ~= nil and szParam2 or "nil",
        self.nToastType,
        self.nCampType,
        self.nContinueTime ~= nil and self.nContinueTime or 0)
   --
    BattleOperationHelper:PrintLog(self, szLog)

    local tbPlayer = BattleBlackboard:GetTable(BattleOperationDef.CurrentObject)
    local tbGamePlayerState = tbPlayer.BattlePlayerStateComponent:GetGamePlayerState()
    if tbPlayer ~= nil and tbGamePlayerState ~= nil then
        local szFaction = L10N:ToString(GamePlayerTypeDef:GetFactionText(tbPlayer.tbPrepareInfo.nFaction))
        ShowSpecialToast(tbGamePlayerState.rBattleSpecialToast,
            tbPlayer.nServerInstanceId,
            self.nId,
            szFaction,
            tbPlayer.szName,
            szParam2,
            Proto.rBattleSpecialToast.SPECIAL,
            self.nCampType,
            self.nContinueTime)
    end

    return true
end

return BattleSpecialToastLoginAction