-----------------------------------------------------
--File Name    : AbilityAction_ArmorAffectHumanWeaponProperty.lua
--Author       : WuJizhou
--Create Time  : 3/25/2020, 7:41:30 PM
--Description  : AbilityAction_ArmorAffectHumanWeaponProperty
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ArmorAffectHumanWeaponProperty = luaclass("AbilityAction_ArmorAffectHumanWeaponProperty", AbilityActionBase)

local PropName                                = require("PropName")
local BattleItemDataTable                     = require("BattleItemDataTable")
local HumanArmorAffectWeaponPropertyDataTable = require("HumanArmorAffectWeaponPropertyDataTable")

AbilityAction_ArmorAffectHumanWeaponProperty.nAffectWeaponGroupId = nil
AbilityAction_ArmorAffectHumanWeaponProperty.nAffectPropertyConfigId = nil
AbilityAction_ArmorAffectHumanWeaponProperty.tbOverlapIds = nil
AbilityAction_ArmorAffectHumanWeaponProperty.bApply = false

local function ApplyAffect(self, tbTargetPlayer)
    if self.bApply then
        log("AbilityAction_ArmorAffectHumanWeaponProperty RemoveAffect", "bApply true")
        return
    end
    log("AbilityAction_ArmorAffectHumanWeaponProperty", "ApplyAffect")
    local tbProperties = HumanArmorAffectWeaponPropertyDataTable:GetAffectProperties(self.nAffectPropertyConfigId)
    local HumanBattlePropertyComponent = tbTargetPlayer.HumanBattlePropertyComponent
    for _, v in ipairs(tbProperties) do
        local nPropId = PropName[v[1]]
        local nOverlapType = v[2]
        local nValue = v[3]
        log("AbilityAction_ArmorAffectHumanWeaponProperty do apply",v[1], nPropId, nOverlapType, nValue)
        local nOverlapId = HumanBattlePropertyComponent:PropOverlap(nOverlapType, nPropId, nValue)
        table.insert(self.tbOverlapIds, {nPropId, nOverlapId})
    end
    self.bApply = true
end

local function RemoveAffect(self, tbTargetPlayer)
    if not self.bApply then
        log("AbilityAction_ArmorAffectHumanWeaponProperty RemoveAffect", "bApply false")
        return
    end
    log("AbilityAction_ArmorAffectHumanWeaponProperty", "RemoveAffect")
    local HumanBattlePropertyComponent = tbTargetPlayer.HumanBattlePropertyComponent
    for _, v in ipairs(self.tbOverlapIds) do
        log("AbilityAction_ArmorAffectHumanWeaponProperty do remove", v[1], v[2])
        HumanBattlePropertyComponent:RemovePropOverlap(v[1], v[2])
    end
    self.tbOverlapIds = {}
    self.bApply = false
end


function AbilityAction_ArmorAffectHumanWeaponProperty:OnCreate(Owner, tbInitParams)
    self.nAffectWeaponGroupId = tbInitParams.WeaponGroup
    self.nAffectPropertyConfigId = tbInitParams.PropertyConfig
    self.tbOverlapIds = {}
    self.bApply = false
end


function AbilityAction_ArmorAffectHumanWeaponProperty:OnDo(tbParams)
    local tbPlayer = self.OwnerPawn
    if tbPlayer:IsHuman() then
        local HumanWeaponComponent = tbPlayer.HumanWeaponComponent
        local nTemplateId = HumanWeaponComponent:GetCurrentWeaponTemplateId()
        if nTemplateId ~= 0 then
            local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
            local nGroup = tbTemplate.nArmorAffectGroup
            if nGroup == self.nAffectWeaponGroupId then
                if not self.bApply then
                    ApplyAffect(self, tbPlayer)
                end
            else
                if self.bApply then
                    RemoveAffect(self, tbPlayer)
                end

            end
        else -- 空手
            if self.bApply then
                RemoveAffect(self, tbPlayer)
            end
        end
    else
        log("AbilityAction_ArmorAffectHumanWeaponProperty DoOnEventHumanCurrentWeaponChanged", "not human")
    end

end

function AbilityAction_ArmorAffectHumanWeaponProperty:OnUndo()
    if self.bApply then
        RemoveAffect(self, self.OwnerPawn)
    end
end


return AbilityAction_ArmorAffectHumanWeaponProperty