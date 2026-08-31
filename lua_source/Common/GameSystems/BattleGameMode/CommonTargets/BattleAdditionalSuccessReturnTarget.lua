local luaclass = require("luaclass")
local BattleTargetBase = require("BattleTargetBase")
local BattleAdditionalSuccessReturnTarget = luaclass("BattleAdditionalSuccessReturnTarget", BattleTargetBase)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleBlackboard = require("BattleBlackboard")

BattleAdditionalSuccessReturnTarget.szSetObjKey  = nil
BattleAdditionalSuccessReturnTarget.szSetReturnCode = nil

function BattleAdditionalSuccessReturnTarget:Init()
    BattleAdditionalSuccessReturnTarget.super.Init(self)
    self.szName = "BattleAdditionalSuccessReturnTarget"
end

function BattleAdditionalSuccessReturnTarget:Parse(tbJsonData)
    self.szSetObjKey = tbJsonData.SetObjKey or ""
    self.szSetReturnCode = tbJsonData.SetReturnCode or ""

    return true
end

function BattleAdditionalSuccessReturnTarget:OnASResult(nReturnCode,tbPlayer)
    if self.szSetObjKey and string.len(self.szSetObjKey) > 0 then
        BattleBlackboard:SetTable(self.szSetObjKey, tbPlayer)
    end

    if self.szSetReturnCode and string.len(self.szSetReturnCode) > 0 then
        BattleBlackboard:SetNumber(self.szSetReturnCode, nReturnCode)
    end

    self:Complete()
end

function BattleAdditionalSuccessReturnTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_ADDITIONALSUCCESS_RESULT, self, self.OnASResult)
end

function BattleAdditionalSuccessReturnTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_ADDITIONALSUCCESS_RESULT, self, self.OnASResult)   
end

function BattleAdditionalSuccessReturnTarget:Start()
    BattleAdditionalSuccessReturnTarget.super.Start(self)
end

return BattleAdditionalSuccessReturnTarget
