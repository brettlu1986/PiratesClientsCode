-----------------------------------------------------
--File Name    : AbilityEvent_Hit.lua
--Author       : Song Fuhao
--Create Time  : 2020-05-27
--Description  : 角色攻击他人时触发
--Param        : CauserType         number      攻击角色类型限定，只有当攻击角色是改类型改触发
--               TakerType          number      受击角色类型限定，只有当受击角色是该类型才出发
--               WeaponAttachmentId number      武器配件限定，当造成伤害的武器上装有该id的配件才能触发
--               ExcludedDamgeTypes number_list 对应DamageTypeEx中枚举值，当匹配时会跳过触发
--               ValidedDamageTypes number_list 对应DamageTypeEx中枚举值，当匹配时才会触发
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBase = require("AbilityEventBase")
local AbilityEvent_Hit = luaclass("AbilityEvent_Hit", AbilityEventBase)

local BaseUtil                  = require("BaseUtil")
local EventManager              = require("EventManager")
local CommonEventDef            = require("CommonEventDef")
local BattleAbilityDefine       = require("BattleAbilityDefine")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local BattleItemSystemServer    = require("BattleItemSystemServer")
local GameObjectSystem          = dynamic_require("GameObjectSystem")
local BattleShipWeaponSystem    = dynamic_require("BattleShipWeaponSystem")

local CHARACTER_TYPE = BattleAbilityDefine.CHARACTER_TYPE

AbilityEvent_Hit.nCauserType = nil
AbilityEvent_Hit.nTakerType = nil
AbilityEvent_Hit.nWeaponAttachmentId = nil
AbilityEvent_Hit.tbExcludedDamgeTypes = nil
AbilityEvent_Hit.tbValidedDamageTypes = nil

-- 检查配件条件
local function CheckAttachment(self, tbCauser, nItemTemplateId)
    if self.nWeaponAttachmentId then
        if not GameObjectSystem:IsCharacter(tbCauser) then
            return false
        end
        local nItemCategory = nil
        local nWeaponInstanceId = nil
        if tbCauser:IsHuman() then
            local HumanWeaponComponent = tbCauser.HumanWeaponComponent
            local nWeaponTemplateId = HumanWeaponComponent:GetCurrentWeaponTemplateId()
            if nWeaponTemplateId ~= nItemTemplateId then
                return false
            end
            nItemCategory = BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT
            nWeaponInstanceId = HumanWeaponComponent:GetCurrentWeaponInstanceId()
        else
            local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbCauser)
            if (not ActiveWeaponItem) or (ActiveWeaponItem:GetTemplateId() ~= nItemTemplateId) then
                return false
            end
            nItemCategory = BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT
            nWeaponInstanceId = ActiveWeaponItem:GetInstanceId()
        end
        local nCharacterInstanceId = tbCauser:GetServerInstanceId()
        local tbWeaponAttachments = BattleItemSystemServer:GetEquippedItems(nCharacterInstanceId, nItemCategory, nWeaponInstanceId)
        if tbWeaponAttachments then
            for _,tbWeaponAttachment in pairs(tbWeaponAttachments) do
                if tbWeaponAttachment:GetTemplateId() == self.nWeaponAttachmentId then
                    return true
                end
            end
            return false
        end
    end
    return true
end

-- 检查伤害类型条件
local function CheckDamageType(self, nDamageType)
    if self.tbExcludedDamgeTypes then
        for _,nExcludedDamageType in ipairs(self.tbExcludedDamgeTypes) do
            if nDamageType == nExcludedDamageType then
                return false
            end
        end
    end
    if self.tbValidedDamageTypes then
        for _,nValidedDamageType in ipairs(self.tbValidedDamageTypes) do
            if nDamageType == nValidedDamageType then
                return true
            end
        end
    end
    return true
end

-- 检查角色类型
local function CheckCharacterType(tbCharacter, nTargetType)
    if not GameObjectSystem:IsCharacter(tbCharacter) then
        return false
    end
    if nTargetType then
        if nTargetType == CHARACTER_TYPE.HUMAN then
            return tbCharacter:IsHuman()
        elseif nTargetType == CHARACTER_TYPE.SHIP then
            return tbCharacter:IsShip()
        end
    end
    return true
end

local function OnTakeDamage(self, tbTaker, tbCauser, _nDamage, nDamageType, _nHp, nItemTemplateId, _tbDamageExtraData)
    if tbCauser ~= self.OwnerPawn then
        return
    end
    -- 判断Owner状态是人还是船
    if not CheckCharacterType(tbCauser, self.nCauserType) then
        return
    end
    -- 判断Taker状态是人还是船
    if not CheckCharacterType(tbTaker, self.nTakerType) then
        return
    end
    -- 检查伤害类型条件
    if not CheckDamageType(self, nDamageType) then
        return
    end
    -- 检查配件条件
    if not CheckAttachment(self, tbCauser, nItemTemplateId) then
        return
    end

    self:TriggerDo({tbTargetPawns={ tbTaker }})
end

function AbilityEvent_Hit:OnCreate(_Owner, tbInitParams)
    self.nWeaponAttachmentId = tbInitParams.WeaponAttachmentId
    self.nCauserType = tbInitParams.CauserType
    self.nTakerType = tbInitParams.TakerType
    if BaseUtil:IsNumber(tbInitParams.ExcludedDamgeTypes) then
        self.tbExcludedDamgeTypes = {tbInitParams.ExcludedDamgeTypes}
    else
        self.tbExcludedDamgeTypes = tbInitParams.ExcludedDamgeTypes
    end
    if BaseUtil:IsNumber(tbInitParams.ValidedDamageTypes) then
        self.tbValidedDamageTypes = {tbInitParams.ValidedDamageTypes}
    else
        self.tbValidedDamageTypes = tbInitParams.ValidedDamageTypes
    end
end

function AbilityEvent_Hit:OnActivate()
    EventManager:BindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
end

function AbilityEvent_Hit:OnDeactivate()
    EventManager:UnBindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
end

return AbilityEvent_Hit