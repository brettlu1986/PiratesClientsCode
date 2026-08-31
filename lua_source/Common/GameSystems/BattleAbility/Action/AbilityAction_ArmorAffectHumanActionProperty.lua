-----------------------------------------------------
--File Name    : AbilityAction_ArmorAffectHumanActionProperty.lua
--Author       : WuJizhou
--Create Time  : 3/25/2020, 7:41:30 PM
--Description  : AbilityAction_ArmorAffectHumanActionProperty
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ArmorAffectHumanActionProperty = luaclass("AbilityAction_ArmorAffectHumanActionProperty", AbilityActionBase)

local PropName                                = require("PropName")
local HumanArmorAffectActionPropertyDataTable = require("HumanArmorAffectActionPropertyDataTable")

AbilityAction_ArmorAffectHumanActionProperty.nAffectPropertyConfigId = nil
AbilityAction_ArmorAffectHumanActionProperty.tbOverlapIds = nil

local function ApplyAffect(self, tbTargetPlayer)
log("AbilityAction_ArmorAffectHumanActionProperty", "ApplyAffect", self.nAffectPropertyConfigId)
    local tbProperties = HumanArmorAffectActionPropertyDataTable:GetAffectProperties(self.nAffectPropertyConfigId)
    local HumanBattlePropertyComponent = tbTargetPlayer.HumanBattlePropertyComponent
    for _, v in ipairs(tbProperties) do

        local nPropId = PropName[v[1]]
        local nOverlapType = v[2]
        local nValue = v[3]
        log("AbilityAction_ArmorAffectHumanActionProperty do apply", v[1], nPropId, nOverlapType,nValue)
        local nOverlapId = HumanBattlePropertyComponent:PropOverlap(nOverlapType, nPropId, nValue)
        table.insert(self.tbOverlapIds, {nPropId, nOverlapId})
    end
end

local function RemoveAffect(self, tbTargetPlayer)
    log("AbilityAction_ArmorAffectHumanActionProperty", "RemoveAffect")
    local HumanBattlePropertyComponent = tbTargetPlayer.HumanBattlePropertyComponent
    for _, v in ipairs(self.tbOverlapIds) do
        log("AbilityAction_ArmorAffectHumanActionProperty do remove", v[1], v[2])
        HumanBattlePropertyComponent:RemovePropOverlap(v[1], v[2])
    end
    self.tbOverlapIds = {}
end


function AbilityAction_ArmorAffectHumanActionProperty:OnCreate(Owner, tbInitParams)
    self.nAffectPropertyConfigId = tbInitParams.PropertyConfig
    self.tbOverlapIds = {}
end


function AbilityAction_ArmorAffectHumanActionProperty:OnDo()
    ApplyAffect(self, self.OwnerPawn)
end

function AbilityAction_ArmorAffectHumanActionProperty:OnUndo()
    RemoveAffect(self, self.OwnerPawn)
end


return AbilityAction_ArmorAffectHumanActionProperty