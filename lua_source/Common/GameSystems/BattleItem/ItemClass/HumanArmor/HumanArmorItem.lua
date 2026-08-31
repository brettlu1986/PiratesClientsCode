-----------------------------------------------------
--File Name    : HumanArmorItem.lua
--Author       : WuJizhou
--Create Time  : 9/11/2018, 6:13:16 PM
--Description  : HumanArmorItem
-----------------------------------------------------
local luaclass = require("luaclass")
local EquipmentItemBase = require("EquipmentItemBase")
local HumanArmorItem = luaclass("HumanArmorItem", EquipmentItemBase)
local HumanArmorItemPropertyHelper = require("HumanArmorItemPropertyHelper")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local PropName = require("PropName")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

HumanArmorItem.tbProperty = nil
HumanArmorItem.nDurability = nil

local function InitProperty(self)
    local nTemplateId = self:GetTemplateId()
    self.tbProperty = HumanArmorItemPropertyHelper.CreateProperty(nTemplateId)
end


local function RefreshAvatarRes(tbPlayer, tbItem, bEquiped)
    if tbPlayer and tbPlayer:IsAlive() then
        local humanAvatarComponent = tbPlayer.HumanAvatarComponent
        if not humanAvatarComponent then
            return
        end
        if bEquiped then
            humanAvatarComponent:ApplyArmorTypeAndLevel(tbItem:GetArmorType(), tbItem:GetGrade())
        else
            humanAvatarComponent:ApplyArmorTypeAndLevel()
        end
    end
end

local function AddBuff(self)
    local Owner = self:GetOwnerCharacter()
    local tbBuffIds = self.tbProperty.tbBuffIds
    for _, nBuffId in ipairs(tbBuffIds) do
        Owner.BuffComponentServer:AddBuffById(nBuffId)
    end
end

local function RemoveBuff(self)
    local Owner = self:GetOwnerCharacter()
    local tbBuffIds = self.tbProperty.tbBuffIds
    for _, nBuffId in ipairs(tbBuffIds) do
        Owner.BuffComponentServer:RemoveBuffById(nBuffId)
    end
end

----public:
function HumanArmorItem:GetDurability()
    return self.nDurability
end

function HumanArmorItem:SetDurability(nDurability)
    self.nDurability = nDurability
end

-- 策划需求：显示百分比
function HumanArmorItem:GetDurabilityPercentageString()
    local nMaxDurability = self.tbTemplate.nDurability
    local nCurrentDurability = self.nDurability
    return (nCurrentDurability * 100 // nMaxDurability) .. "%"
end

---------------call back for Item system--------
function HumanArmorItem:OnCreate()
    self.nDurability = self.tbTemplate.nDurability
    InitProperty(self)
end


function HumanArmorItem:OnEquipOnServer()
    local tbPlayer = self:GetOwnerCharacter()
    RefreshAvatarRes(tbPlayer, self, true)
    tbPlayer.HumanBattlePropertyComponent:SetPropOriginValue(PropName.nCurrentArmorTemplateId, self:GetTemplateId())
    local nOwnerCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local nItemId = self:GetInstanceId()
    if GlobalVariableSystem.bUseNewBattleItem then
        AddBuff(self)
    end

    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_ARMOR_ON_EQUIPED_SERVER, nOwnerCharacterInstanceId, nItemId)
end

function HumanArmorItem:OnEquipOnClient()
    local nOwnerCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local nItemId = self:GetInstanceId()
    local ClientEventDef = require("ClientEventDef")
    EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_ARMOR_ON_EQUIPED_CLIENT, nOwnerCharacterInstanceId, nItemId)
end

function HumanArmorItem:OnUnequipOnServer()
    RefreshAvatarRes(self:GetOwnerCharacter(), self, false)
    local nOwnerCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local nItemId = self:GetInstanceId()
    if GlobalVariableSystem.bUseNewBattleItem then
        RemoveBuff(self)
    end
    local tbPlayer = self:GetOwnerCharacter()
    tbPlayer.HumanBattlePropertyComponent:SetPropOriginValue(PropName.nCurrentArmorTemplateId, -1)
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_ARMOR_ON_UNEQUIPED_SERVER, nOwnerCharacterInstanceId, nItemId)
end

function HumanArmorItem:OnUnequipOnClient()
    local nOwnerCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local nItemId = self:GetInstanceId()
    local ClientEventDef = require("ClientEventDef")
    EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_ARMOR_ON_UNEQUIPED_CLIENT, nOwnerCharacterInstanceId, nItemId)
end

function HumanArmorItem:OnDurabilityChangedOnClient()
end

function HumanArmorItem:GetProtoData()
    local tbData = HumanArmorItem.super.GetProtoData(self)
    tbData.durability = self.nDurability
    return tbData
end

function HumanArmorItem:InitWithProtoData(tbPlayer, tbItemProtoData)
    HumanArmorItem.super.InitWithProtoData(self, tbPlayer, tbItemProtoData)
    self.nDurability = tbItemProtoData.durability
end

function HumanArmorItem:GetArmorType()
    local tbTemplate = self:GetTemplate()
    return tbTemplate.nArmorType
end

return HumanArmorItem