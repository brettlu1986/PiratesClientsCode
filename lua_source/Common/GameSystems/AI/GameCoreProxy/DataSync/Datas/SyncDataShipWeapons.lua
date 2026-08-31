local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataShipWeapons = luaclass("SyncDataShipWeapons", SyncDataBase)
local PropName = require("PropName")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local CommonEventDef = require("CommonEventDef")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local GameCoreAgentLuaPoolManager = require("GameCoreAgentLuaPoolManager")
local SyncDataUtils = require("SyncDataUtils")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipWeaponAttachmentTypeDef = require("ShipWeaponAttachmentTypeDef")
local ShipWeaponAttachmentHelper = require("ShipWeaponAttachmentHelper")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

SyncDataShipWeapons.tbWeapons = nil
SyncDataShipWeapons.tbEquippedWeapons = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SyncDataShipWeapons:", ...)
end

-- luacheck: pop

local function GetWeaponAttachments(nCharacterInstanceId, tbAttachments, tbWeaponItem)
    for i=1,ShipWeaponAttachmentTypeDef.Max do
        local nSlotId = i
        if ShipWeaponAttachmentHelper.IsWeaponAttachmentOpen(tbWeaponItem, nSlotId) then
            local tbAttachmentItem = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId,
                BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT, tbWeaponItem:GetInstanceId(), nSlotId)
            local nAttachmentItemId = 0
            if tbAttachmentItem then
                nAttachmentItemId = tbAttachmentItem:GetInstanceId()
            end
            local tbValidAttachmentTemplateIds = ShipWeaponAttachmentHelper.GetWeaponCompatibleAttachments(tbWeaponItem, nSlotId)
            local tbAttachmentData = { }
            tbAttachmentData.slot = nSlotId
            tbAttachmentData.required_template_ids = tbValidAttachmentTemplateIds
            tbAttachmentData.equipped_item_id = nAttachmentItemId
            table.insert(tbAttachments, tbAttachmentData)
        end
    end
end

local function GetShipWeaponRotationRanges(tbWeaponItem, tbRangeTables, nInstanceId)
    SyncDataUtils:EmptyTable(tbRangeTables)
    local tbTemplate = tbWeaponItem:GetTemplate()
    if tbTemplate.nRotationRange > 0 then
        local tbWeaponOwner = tbWeaponItem:GetOwnerCharacter()
        local OwnerShipPropertyComponent = tbWeaponOwner.ShipBattlePropertyComponent
        local nFiringRotationRangeDelta = OwnerShipPropertyComponent:GetProp(PropName.nFiringRotationRangeDelta)
        local nFiringRotationRangeRatio = OwnerShipPropertyComponent:GetProp(PropName.nFiringRotationRangeRatio)
        local nHalfRotationRange = (tbTemplate.nRotationRange * nFiringRotationRangeRatio + nFiringRotationRangeDelta) / 2
        local tbShipWeaponRangeLuaTable = GameCoreAgentLuaPoolManager:Get(nInstanceId, "ShipWeaponRange")
        local bPairedWeapon = ShipWeaponCategoryDataTable:GetIsPairedWeapon(tbTemplate.nSubCategory)
        if bPairedWeapon then -- 成对的武器一定是左右放置，所以取-90、90为中心Yaw计算范围
            local  tbRange1 = tbShipWeaponRangeLuaTable:Get()
            tbRange1.range_start = -90 - nHalfRotationRange
            tbRange1.range_end = -90 + nHalfRotationRange
            table.insert(tbRangeTables, tbRange1)

            local  tbRange2 = tbShipWeaponRangeLuaTable:Get()
            tbRange2.range_start = 90 - nHalfRotationRange
            tbRange2.range_end = 90 + nHalfRotationRange
            table.insert(tbRangeTables, tbRange2)
        else
            local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(tbTemplate.nSubCategory)
            if nWeaponSlot == ShipWeaponSlotDef.HEAD then -- 船头武器取0为中心Yaw计算范围
                local  tbRange = tbShipWeaponRangeLuaTable:Get()
                tbRange.range_start = -nHalfRotationRange
                tbRange.range_end = nHalfRotationRange
                table.insert(tbRangeTables, tbRange)
            elseif nWeaponSlot == ShipWeaponSlotDef.DECK then -- 船尾武器由于会面临-180、180的临界点，所以两侧各自计算
                local  tbRange1 = tbShipWeaponRangeLuaTable:Get()
                tbRange1.range_start = 180 - nHalfRotationRange
                tbRange1.range_end = 180
                table.insert(tbRangeTables, tbRange1)

                local  tbRange2 = tbShipWeaponRangeLuaTable:Get()
                tbRange2.range_start = -180
                tbRange2.range_end = -180 + nHalfRotationRange
                table.insert(tbRangeTables, tbRange2)
            end
        end
    end
end

function SyncDataShipWeapons:OnWeaponEquipped(OwnerCharacter, nWeaponSlot, tbWeaponItem)
    if self.tbOwner == OwnerCharacter and (tbWeaponItem:GetCategory() == BattleItemCategoryDef.SHIP_WEAPON) then
        local tbWeaponState = nil
        for i,v in ipairs(self.tbWeapons) do
            if v.slotid == nWeaponSlot then
                tbWeaponState = v
                break
            end
        end
        if not tbWeaponState then
            tbWeaponState = {}
            table.insert(self.tbWeapons, tbWeaponState)
        end
        local tbTemplate = tbWeaponItem:GetTemplate()
        tbWeaponState.id = tbWeaponItem:GetInstanceId()
        tbWeaponState.templateid = tbWeaponItem:GetTemplateId()
        tbWeaponState.category = tbWeaponItem:GetSubCategory()
        tbWeaponState.slotid   = nWeaponSlot
        tbWeaponState.attack_range = math.floor(tbTemplate.nFiringRange)
        tbWeaponState.attachments = {}
        GetWeaponAttachments(OwnerCharacter:GetServerInstanceId(), tbWeaponState.attachments, tbWeaponItem)
        self.tbEquippedWeapons[nWeaponSlot] = tbWeaponItem
        LOG("add ship weapon at:", nWeaponSlot)
    end
end

function SyncDataShipWeapons:OnWeaponUnEquipped(OwnerCharacter, nWeaponSlot, tbWeaponItem)
    if self.tbOwner == OwnerCharacter and (tbWeaponItem:GetCategory() == BattleItemCategoryDef.SHIP_WEAPON) then
        for i,v in ipairs(self.tbWeapons) do
            if v.slotid == nWeaponSlot then
                table.remove(self.tbWeapons, i)
                break
            end
        end
        self.tbEquippedWeapons[nWeaponSlot] = nil
        LOG("remove ship weapon at:", nWeaponSlot)
    end
end


function SyncDataShipWeapons:OnWeaponAttachmentEquipped(nOwnerCharacterInstanceId, tbAttachmentItem)
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

function SyncDataShipWeapons:OnWeaponAttachmentUnEquipped(nOwnerCharacterInstanceId, tbAttachmentItem)
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


function SyncDataShipWeapons:BindEvent(SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_EQUIPPED_SERVER , self, self.OnWeaponEquipped)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_UNEQUIPPED_SERVER   , self, self.OnWeaponUnEquipped)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_SHIP_WEAPON_ATTACHMENT_ON_EQUIPED_SERVER, self, self.OnWeaponAttachmentEquipped)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_SHIP_WEAPON_ATTACHMENT_ON_UNEQUIPED_SERVER, self, self.OnWeaponAttachmentUnEquipped)
end

function SyncDataShipWeapons:UnbindEvent(SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

function SyncDataShipWeapons:OnSync(tbPack)
    local tbGameObject = self.tbOwner
    if tbGameObject:IsShip() then
        local nServerInstanceId = tbGameObject:GetServerInstanceId()
        tbPack.active_weapon_slot = BattleShipWeaponSystem:GetActiveWeaponSlot(tbGameObject)
        for i,v in ipairs(self.tbWeapons) do
            local tbWeaponItem = self.tbEquippedWeapons[v.slotid]
            v.damage = BattleShipWeaponSystem:GetWeaponAttack(tbGameObject, tbWeaponItem:GetSubCategory(), tbWeaponItem:GetTemplate().nBaseDamage)
            v.bullet = tbWeaponItem:GetBulletLoadedCount(false)
            v.remain_reloading = math.max(tbWeaponItem:GetRemainingFiringCD(), tbWeaponItem:GetRemainingBulletLoadingTime())
            v.rotation_ranges = v.rotation_ranges or {}
            GetShipWeaponRotationRanges(tbWeaponItem, v.rotation_ranges, nServerInstanceId)
        end
        tbPack.weapons = self.tbWeapons
    else
        tbPack.ship_stat_cache = tbPack.ship_stat_cache or {}
        local tbWeapons = tbPack.ship_stat_cache.weapons or {}
        local SAIEntityComponent = tbGameObject.SAIEntityComponent
        for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
            local tbWeapon = SAIEntityComponent:GetShipWeapon(i)
            if tbWeapon then
                tbWeapons[i] = tbWeapon:GetTemplateId()
            else
                tbWeapons[i] = 0
            end
        end
        tbPack.ship_stat_cache.weapons = tbWeapons
    end
end


function SyncDataShipWeapons:OnStart()
    self.tbWeapons = {}
    self.tbEquippedWeapons = {}
    local nCharacterInstanceId = self.tbOwner.nServerInstanceId
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbWeaponItem = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON,
        nCharacterInstanceId, i)
        if tbWeaponItem then
            self:OnWeaponEquipped(self.tbOwner, i, tbWeaponItem)
        end
    end
end


function SyncDataShipWeapons:OnStop()

end

return SyncDataShipWeapons