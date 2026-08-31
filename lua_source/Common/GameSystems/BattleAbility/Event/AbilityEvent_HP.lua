-----------------------------------------------------
--File Name    : AbilityEvent_HP.lua
--Author       : Song Fuhao
--Create Time  : 2018-02-22
--Description  : 血量事件
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_HP = luaclass("AbilityEvent_HP", AbilityEventBaseClass)

local StringUtil = require("StringUtil")
local BattleAbilityDefine = require("BattleAbilityDefine")
local ValueType = BattleAbilityDefine.ValueType

local function OnHPChanged(self, nValue)
    self:TriggerDo()
end

function AbilityEvent_HP:OnActivate()
    local tbParams = self.tbParams
    local bLessThan = tbParams.LessThan and StringUtil.ToBool(tbParams.LessThan) or true
    if tbParams.Type == ValueType.FIXED then -- 固定值
        self.OwnerPawn.BattleShipPropertyComponent:BindHPReachValueEvent(tbParams.Value, bLessThan, OnHPChanged, self)
    else -- 百分比
        self.OwnerPawn.BattleShipPropertyComponent:BindHPReachRatioEvent(tbParams.Value, bLessThan, OnHPChanged, self)
    end
end

function AbilityEvent_HP:OnDeactivate()
    if self.tbParams.Type == ValueType.FIXED then -- 固定值
        self.OwnerPawn.BattleShipPropertyComponent:UnBindHPReachValueEvent(OnHPChanged, self)
    else -- 百分比
        self.OwnerPawn.BattleShipPropertyComponent:UnBindHPReachRatioEvent(OnHPChanged, self)
    end
end

return AbilityEvent_HP
