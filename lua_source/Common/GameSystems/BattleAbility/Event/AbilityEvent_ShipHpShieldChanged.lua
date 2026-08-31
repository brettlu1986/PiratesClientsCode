-----------------------------------------------------
--File Name    : AbilityEvent_ShipHpShieldChanged.lua
--Author       : Song Fuhao
--Create Time  : 2018-11-01
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_ShipHpShieldChanged = luaclass("AbilityEvent_ShipHpShieldChanged", AbilityEventBaseClass)

local PropName = require("PropName")
local MathUtil = require("MathUtil")

local function OnShipHpShieldChanged(self, nNewValue)
    local nMethod = self.tbParams.Method
    local nValue = self.tbParams.Value
    if MathUtil.CompareValue(nMethod, nNewValue, nValue) then
        self:TriggerDo()
    end
end

function AbilityEvent_ShipHpShieldChanged:OnActivate()
    local ShipBattlePropertyComponent = self.OwnerPawn.ShipBattlePropertyComponent
    if ShipBattlePropertyComponent then
        ShipBattlePropertyComponent:BindPropChanged(PropName.nShipHpShield, OnShipHpShieldChanged, self)
    end
end

function AbilityEvent_ShipHpShieldChanged:OnDeactivate()
    local ShipBattlePropertyComponent = self.OwnerPawn.ShipBattlePropertyComponent
    if ShipBattlePropertyComponent then
        ShipBattlePropertyComponent:UnbindPropChanged(PropName.nShipHpShield, OnShipHpShieldChanged, self)
    end
end

return AbilityEvent_ShipHpShieldChanged