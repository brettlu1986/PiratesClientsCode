local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataHumanWeapons = luaclass("SyncDataHumanWeapons", SyncDataBase)
local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponHelper     = require("HumanWeaponHelper")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponSlotDef    = require("HumanWeaponSlotDef")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local HumanWeaponType = HumanWeaponMisc.Type

SyncDataHumanWeapons.tbWeapons = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SyncDataHumanWeapons:", ...)
end

-- luacheck: pop

local function GetWeaponAttachments(nCharacterInstanceId, tbAttachments, tbWeaponItem)
    local tbWeaponTemplate = tbWeaponItem:GetTemplate()
    for i,v in ipairs(tbWeaponTemplate.tbAttachmentSlots) do
        if #v > 0 then
            local nSlotId = i
            local tbAttachmentItem = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId,
                BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, tbWeaponItem:GetInstanceId(), nSlotId)
            local nAttachmentItemId = 0
            if tbAttachmentItem then
                nAttachmentItemId = tbAttachmentItem:GetInstanceId()
            end
            local tbAttachmentData = { }
            tbAttachmentData.slot = nSlotId
            tbAttachmentData.required_template_ids = v
            tbAttachmentData.equipped_item_id = nAttachmentItemId
            table.insert(tbAttachments, tbAttachmentData)
        end
    end
end

function SyncDataHumanWeapons:OnWeaponEquipped(nOwnerCharacterInstanceId, nWeaponInstanceId)
    if self.tbOwner:GetServerInstanceId() == nOwnerCharacterInstanceId then
        local HumanWeaponComponent = self.tbOwner.HumanWeaponComponent
        local tbWeapon = HumanWeaponComponent:FindWeaponById(nWeaponInstanceId)
        if tbWeapon and not tbWeapon:IsType(HumanWeaponType.THROW) then
            local tbWeaponState = nil
            for i,v in ipairs(self.tbWeapons) do
                if v.slotid == tbWeapon.nSlot then
                    tbWeaponState = v
                    break
                end
            end
            if not tbWeaponState then
                tbWeaponState = {}
                table.insert(self.tbWeapons, tbWeaponState)
            end
            tbWeaponState.slotid    = tbWeapon.nSlot
            tbWeaponState.category  = HumanWeaponHelper.GetWeaponCategory(tbWeapon.nTemplateId)
            tbWeaponState.id = nWeaponInstanceId
            tbWeaponState.templateid = tbWeapon:GetTemplateId()
            tbWeaponState.attachments = {}
            local tbWeaponItem = BattleItemSystemServer:GetItem(nWeaponInstanceId)
            GetWeaponAttachments(nOwnerCharacterInstanceId, tbWeaponState.attachments, tbWeaponItem)
            LOG("add human weapon at ", tbWeapon.nSlot, tbWeaponState.id, tbWeaponState.templateid)
        end
    end
end



function SyncDataHumanWeapons:OnWeaponUnEquipped(nOwnerCharacterInstanceId, tbWeaponItem)
    if nOwnerCharacterInstanceId == self.tbOwner.nServerInstanceId then
        local nSlotIndex  = tbWeaponItem:GetStorageLocation().nSlotIndex
        for i,v in ipairs(self.tbWeapons) do
            if v.slotid == nSlotIndex then
                table.remove(self.tbWeapons, i)
                LOG("remove human weapon at ", nSlotIndex)
                break
            end
        end
    end
end

function SyncDataHumanWeapons:OnWeaponAttachmentEquipped(nOwnerCharacterInstanceId, tbAttachmentItem)
    if nOwnerCharacterInstanceId == self.tbOwner.nServerInstanceId then
        local _, nWeaponId, nSlotIndex = tbAttachmentItem:SplitAndGetStorageLocation()
        for i,v in ipairs(self.tbWeapons) do
            if v.id == nWeaponId then
                for _, tbAttachmentData in ipairs(v.attachments) do
                    if tbAttachmentData.slot == nSlotIndex then
                        tbAttachmentData.equipped_item_id = tbAttachmentItem:GetInstanceId()
                        LOG("equiped attachment:", tbAttachmentData.equipped_item_id)
                        break
                    end
                end
                break
            end
        end
    end
end

function SyncDataHumanWeapons:OnWeaponAttachmentUnEquipped(nOwnerCharacterInstanceId, tbAttachmentItem)
    if nOwnerCharacterInstanceId == self.tbOwner.nServerInstanceId then
        local _, nWeaponId, nSlotIndex = tbAttachmentItem:SplitAndGetStorageLocation()
        for i,v in ipairs(self.tbWeapons) do
            if v.id == nWeaponId then
                for _, tbAttachmentData in ipairs(v.attachments) do
                    if tbAttachmentData.slot == nSlotIndex then
                        tbAttachmentData.equipped_item_id = 0
                        LOG("unequiped attachment")
                        break
                    end
                end
                break
            end
        end
    end
end

function SyncDataHumanWeapons:BindEvent(SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_POST, self, self.OnWeaponEquipped)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_UNEQUIPED_SERVER   , self, self.OnWeaponUnEquipped)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ATTACHMENT_ON_EQUIPED_SERVER, self, self.OnWeaponAttachmentEquipped)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ATTACHMENT_ON_UNEQUIPED_SERVER, self, self.OnWeaponAttachmentUnEquipped)
end

function SyncDataHumanWeapons:UnbindEvent(SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

function SyncDataHumanWeapons:OnSync(tbPack)
    local tbGameObject = self.tbOwner
    if tbGameObject:IsHuman() then
        local HumanWeaponComponent = tbGameObject.HumanWeaponComponent
        tbPack.active_weapon_slot = HumanWeaponComponent:GetCurrentSlot()
        for i,v in ipairs(self.tbWeapons) do
            local tbWeapon = HumanWeaponComponent:FindWeaponById(v.id)
            local tbProperty = tbWeapon:GetProperty()
            v.damage    = math.floor(tbProperty.nDamagePerBullet)
            v.attack_range = tbProperty.nEffectiveRange * 100
            if tbWeapon:IsType(HumanWeaponType.GUN) then
                v.bullet = tbWeapon:GetCurrentAmmo()
                v.remain_reloading = tbWeapon:GetRemainReloadingTime()
            elseif tbWeapon:IsType(HumanWeaponType.MELEE) then
                v.bullet = 1
                v.remain_reloading = tbWeapon:GetCheatCDTime()
            end
        end
        tbPack.weapons = self.tbWeapons
    else
        tbPack.human_stat_cache = tbPack.human_stat_cache or {}
        local tbWeapons = tbPack.human_stat_cache.weapons or {}
        local SAIEntityComponent = tbGameObject.SAIEntityComponent
        for i=1,HumanWeaponSlotDef:SlotCount() do
            local tbWeapon = SAIEntityComponent:GetHumanWeapon(i)
            if tbWeapon then
                tbWeapons[i] = tbWeapon:GetTemplateId()
            else
                tbWeapons[i] = 0
            end
        end
        tbPack.human_stat_cache.weapons = tbWeapons
    end

end


function SyncDataHumanWeapons:OnStart()
    self.tbWeapons = {}
    local tbGameObject = self.tbOwner
    if tbGameObject:IsHuman() then
        for i=1,HumanWeaponSlotDef:SlotCount() do
            local tbWeapon = BattleItemSystemServer:GetEquippedItem(tbGameObject:GetServerInstanceId(), BattleItemCategoryDef.HUMAN_WEAPON,
            tbGameObject:GetServerInstanceId(), i)
            if tbWeapon then
                self:OnWeaponEquipped(tbGameObject:GetServerInstanceId(), tbWeapon:GetInstanceId())
            end
        end
    end
end


function SyncDataHumanWeapons:OnStop()

end

return SyncDataHumanWeapons