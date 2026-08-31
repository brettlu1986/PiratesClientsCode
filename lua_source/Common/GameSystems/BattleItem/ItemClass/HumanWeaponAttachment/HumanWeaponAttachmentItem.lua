-----------------------------------------------------
--File Name    : HumanWeaponAttachmentItem.lua
--Author       : WuJizhou
--Create Time  : 8/29/2018, 11:23:50 AM
--Description  : HumanWeaponAttachmentItem
-----------------------------------------------------
local luaclass = require("luaclass")
local EquipmentItemBase = require("EquipmentItemBase")
local HumanWeaponAttachmentItem = luaclass("HumanWeaponAttachmentItem", EquipmentItemBase)
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
-- local BattleItemCategoryDef = require("BattleItemCategoryDef")

local function RefreshAvatarResData(tbPlayer, nWeaponInstanceId, tbItem, nSlotIdx, nPrimaryCategory, nWeaponCategory, bEquiped)
    -- local avatarComponent = tbPlayer.HumanWeaponAvatarComponent
    -- if not avatarComponent then
    --     return
    -- end

    -- local tbTemplate = tbItem:GetTemplate()
    -- local nAttachmentCategory = tbTemplate.nAttachmentCategory
    -- local szKey = avatarComponent:ParseToHumanWeaponAvatarResPart(nAttachmentCategory)
    -- local nAvatarId
    -- if bEquiped then
    --     nAvatarId = tbTemplate.nAvatarId
    -- else
    --     nAvatarId = -1
    -- end
    -- if szKey ~= nil then
    --     local tbResData = {}
    --     tbResData[szKey] = nAvatarId
    --     avatarComponent:SetAvatarResData(tbResData, nSlotIdx, nPrimaryCategory, nWeaponCategory)
    -- end
end

local function AddBuff(self, tbBuffIds)
    local Owner = self:GetOwnerCharacter()
    -- local tbBuffIds = self.tbProperty.tbBuffIds
    for _, nBuffId in ipairs(tbBuffIds) do
        -- logdebug("AddBuff nBuffId", nBuffId)
        Owner.BuffComponentServer:AddBuffById(nBuffId)
    end
end

local function RemoveBuff(self, tbBuffIds)
    local Owner = self:GetOwnerCharacter()
    -- local tbBuffIds = self.tbProperty.tbBuffIds
    for _, nBuffId in ipairs(tbBuffIds) do
        -- logdebug("RemoveBuff nBuffId", nBuffId)
        Owner.BuffComponentServer:RemoveBuffById(nBuffId)
    end
end

function HumanWeaponAttachmentItem:Activate()
    if GlobalVariableSystem:IsServerLogic() then
        local tbItemTemplate = self:GetTemplate()
        AddBuff(self, tbItemTemplate.tbBuffIds)
    end
end

function HumanWeaponAttachmentItem:Deactivate()
    if GlobalVariableSystem:IsServerLogic() then
        local tbItemTemplate = self:GetTemplate()
        RemoveBuff(self, tbItemTemplate.tbBuffIds)
    end
end

function HumanWeaponAttachmentItem:OnEquipOnServer()
    local nWeaponInstanceId = self.tbStorageLocation.nOwnerInstanceId
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local tbHumanWeaponItem = BattleItemSystemServer:GetItem(nWeaponInstanceId)
    -- local nPlayerId = self:GetOwnerCharacterInstanceId()
    -- local tbAttachments = BattleItemSystemServer:GetEquippedItems(nPlayerId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nWeaponInstanceId)
-- local tbEfficientAttachments = {}
    -- for k, v in pairs(tbAttachments) do
    --     table.insert(tbEfficientAttachments, v)
    -- end

    -- tbHumanWeaponItem:OnAttachmentChanged(tbEfficientAttachments)
        -- local tbItemTemplate = self:GetTemplate()
        -- AddBuff(self, tbItemTemplate.tbBuffIds)

    local tbWeaponTemplate = tbHumanWeaponItem:GetTemplate()
    local nSlotIdx = tbHumanWeaponItem.tbStorageLocation.nSlotIndex
    local nWeaponCategory = tbWeaponTemplate.nWeaponCategory
    local nPrimaryCategory = tbWeaponTemplate.nPrimaryCategory
    RefreshAvatarResData(self:GetOwnerCharacter(), nWeaponInstanceId, self, nSlotIdx, nPrimaryCategory, nWeaponCategory, true)
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_ATTACHMENT_ON_EQUIPED_SERVER, self:GetOwnerCharacterInstanceId(), self)

end

function HumanWeaponAttachmentItem:OnEquipOnClient()
    -- local BattleItemSystemClient = BattleItemSystemHelper:GetBattleItemSystemClient()
    -- local nWeaponInstanceId = self.tbStorageLocation.nOwnerInstanceId
    -- local tbHumanWeaponItem = BattleItemSystemClient:GetItem(nWeaponInstanceId)
    -- local tbAttachments = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nWeaponInstanceId)
    -- local tbEfficientAttachments = {}
    -- for k, v in pairs(tbAttachments) do
    --     table.insert(tbEfficientAttachments, v)
    -- end
    -- tbHumanWeaponItem:OnAttachmentChanged(tbEfficientAttachments)
end

function HumanWeaponAttachmentItem:OnUnequipOnServer()
    local nWeaponInstanceId = self.tbStorageLocation.nOwnerInstanceId
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local tbHumanWeaponItem = BattleItemSystemServer:GetItem(nWeaponInstanceId)
    -- local nPlayerId = self:GetOwnerCharacterInstanceId()
    -- local tbAttachments = BattleItemSystemServer:GetEquippedItems(nPlayerId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nWeaponInstanceId)
    -- local tbEfficientAttachments = {}
    -- for k, v in pairs(tbAttachments) do
    --     if v:GetInstanceId() ~= self:GetInstanceId() then
    --         table.insert(tbEfficientAttachments, v)
    --     end
    -- end
    -- tbHumanWeaponItem:OnAttachmentChanged(tbEfficientAttachments)
    -- local tbItemTemplate = self:GetTemplate()
    -- RemoveBuff(self, tbItemTemplate.tbBuffIds)

    local tbWeaponTemplate = tbHumanWeaponItem:GetTemplate()
    local nSlotIdx = tbHumanWeaponItem.tbStorageLocation.nSlotIndex
    local nWeaponCategory = tbWeaponTemplate.nWeaponCategory
    local nPrimaryCategory =  tbWeaponTemplate.nPrimaryCategory
    RefreshAvatarResData(self:GetOwnerCharacter(), nWeaponInstanceId, self, nSlotIdx, nPrimaryCategory, nWeaponCategory, false)
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_ATTACHMENT_ON_UNEQUIPED_SERVER, self:GetOwnerCharacterInstanceId(), self)
end

function HumanWeaponAttachmentItem:OnUnequipOnClient()
    -- local BattleItemSystemClient = BattleItemSystemHelper:GetBattleItemSystemClient()
    -- local nWeaponInstanceId = self.tbStorageLocation.nOwnerInstanceId
    -- local tbHumanWeaponItem = BattleItemSystemClient:GetItem(nWeaponInstanceId)
    -- local tbAttachments = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nWeaponInstanceId)
    -- local tbEfficientAttachments = {}
    -- for k, v in pairs(tbAttachments) do
    --     if v:GetInstanceId() ~= self:GetInstanceId() then
    --         table.insert(tbEfficientAttachments, v)
    --     end
    -- end
    -- tbHumanWeaponItem:OnAttachmentChanged(tbEfficientAttachments)

end

function HumanWeaponAttachmentItem:GetAttachmentCategory()
    local tbTemplate = self:GetTemplate()
    return tbTemplate.nAttachmentCategory
end

return HumanWeaponAttachmentItem