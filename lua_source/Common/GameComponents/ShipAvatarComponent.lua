local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ShipAvatarComponent = luaclass("ShipAvatarComponent", GameComponentBase)

local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local PropName = require("PropName")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ShipDataTable = require("ShipDataTable")
local CommonEventDef = require("CommonEventDef")
local SelfEventHelper = require("SelfEventHelper")
-- local BattleItemSystemServer = require("BattleItemSystemServer")
-- local BattleItemCategoryDef = require("BattleItemCategoryDef")
-- local ShipPartTypeDef = require("ShipPartTypeDef")

ShipAvatarComponent.tbWeaponRes     = nil
ShipAvatarComponent.tbAvatarRes     = nil
ShipAvatarComponent.tbBrokenStatus  = nil
ShipAvatarComponent.nShipTemplateId = -1
ShipAvatarComponent.EventHelper     = nil

local EMPTY_WEAPON_EQUIP_ID = -1

local SAIL_RES_KEY = "sail"

local SHIP_PART_RES_KEY_TO_TEMPLATE_KEY = {
    sail            = "nSailAppearanceUnique",
    armor           = "nArmorAppearanceUnique",
    captain_cabin   = "nCaptainAppearanceUnique",
}

local SHIP_WEAPON_ENUM_TO_RES_KEY = {
    [ShipWeaponSlotDef.HEAD] = "head_id",
    [ShipWeaponSlotDef.SIDE] = "side_id",
    [ShipWeaponSlotDef.DECK] = "deck_id",
}

local function IsApperanceUnique(self, szKey)
    local nTemplateId = self.Owner:GetShipTemplateId()
    local nTemplateKey = SHIP_PART_RES_KEY_TO_TEMPLATE_KEY[szKey]
    if nTemplateKey then
        local ShipTemplate = ShipDataTable:GetTemplate(nTemplateId)
        if ShipTemplate and ShipTemplate[nTemplateKey] > 0 then
            log("can not change appearrance ship of ",szKey, nTemplateId)
            return true
        end
    end
    return false
end

local function GetShipResTemplateId(self)
    local nShipResId = -1
    local BattleShipSkinComponent = self.Owner.BattleShipSkinComponent
    if BattleShipSkinComponent then -- 先看有没有皮肤
        nShipResId = BattleShipSkinComponent:GetShipResId(self.nShipTemplateId)
    end
    if nShipResId == -1 then -- 没有皮肤，则用船的TemplateId取默认皮肤
        local tbTemplate = ShipDataTable:GetResTemplate(self.nShipTemplateId)
        if tbTemplate then
            nShipResId = tbTemplate.nResId
        end
    end
    return nShipResId
end

-- -- 因为ItemEquipped比较滞后，提前加载可能印象视觉的部件
-- local function InitAvatarRes(self)
--     local nCharacterInstanceId = self.Owner.nServerInstanceId
--     local tbItemSail = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_PART, nCharacterInstanceId, ShipPartTypeDef.SAIL)
--     if tbItemSail then
--         local tbAvatarRes = tbItemSail:GetAvatarRes()
--         if tbAvatarRes then
--             self:SetAvatarResData(tbAvatarRes)
--         end
--     end
-- end

local function ResetData(self)
    self.tbAvatarRes = {}
    self.tbBrokenStatus = {}
    self.tbWeaponRes = {}
    for _, szResKey in pairs(SHIP_WEAPON_ENUM_TO_RES_KEY) do
        self.tbWeaponRes[szResKey] = EMPTY_WEAPON_EQUIP_ID
    end
end

function ShipAvatarComponent:OnActorCreated(...)
    ShipAvatarComponent.super.OnActorCreated(self, ...)

    self.EventHelper = SelfEventHelper()
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ENTER_TRANSPORT_STEP, self, ResetData)

    self.nShipTemplateId = self.Owner:GetTemplateId() -- 不能用GetShipTemplateId

    if GlobalVariableSystem:IsServerLogic() then
        ResetData(self)
        -- InitAvatarRes(self)
        local PropertyComponent = self.Owner.ShipBattlePropertyComponent
        PropertyComponent:SetPropOriginValue(PropName.nShipResTemplateId, GetShipResTemplateId(self))
        PropertyComponent:SetPropOriginValue(PropName.rShipAvatarResData, self.tbAvatarRes)
        PropertyComponent:SetPropOriginValue(PropName.rShipWeaponResData, self.tbWeaponRes)
    end
end

function ShipAvatarComponent:OnActorDestroyed(...)
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end

    ShipAvatarComponent.super.OnActorDestroyed(self, ...)
end

function ShipAvatarComponent:SetAvatarResData(tbAvatarResData)
    -- local bChanged = false
    -- for k,v in pairs(tbAvatarResData) do
    --     local nCacheKey = self.tbAvatarRes[k]
    --     if (nCacheKey == nil or nCacheKey ~= v) and not IsApperanceUnique(self, k) then
    --         self.tbAvatarRes[k] = v
    --         bChanged = true
    --     end
    -- end
    -- if bChanged then
    --     self.Owner.ShipBattlePropertyComponent:SetPropOriginValue(PropName.rShipAvatarResData, self.tbAvatarRes)
    -- end
end

function ShipAvatarComponent:SetBrokenStatusData(tbBrokenStatusData)
    local bChanged = false
    for k,v in pairs(tbBrokenStatusData) do
        local nCacheKey = self.tbBrokenStatus[k]
        if (nCacheKey == nil or nCacheKey ~= v) and not IsApperanceUnique(self, k) then
            self.tbBrokenStatus[k] = v
            bChanged = true
        end
    end
    if bChanged then
        self.Owner.ShipBattlePropertyComponent:SetPropOriginValue(PropName.rShipPartBrokenStatus, self.tbBrokenStatus)
    end
end

function ShipAvatarComponent:SetShipArmorGrade(nShipArmorGrade)
    if not IsApperanceUnique(self, SAIL_RES_KEY) then
        self.Owner.ShipBattlePropertyComponent:SetPropOriginValue(PropName.nShipArmorGrade, nShipArmorGrade)
    end
end

function ShipAvatarComponent:SetWeaponResData(nWeaponSlot, nWeaponTemplateId)
    if nWeaponSlot ~= ShipWeaponSlotDef.UNKNOWN then
        local nWeaponResKey = SHIP_WEAPON_ENUM_TO_RES_KEY[nWeaponSlot]
        self.tbWeaponRes[nWeaponResKey] = nWeaponTemplateId
        self.Owner.ShipBattlePropertyComponent:SetPropOriginValue(PropName.rShipWeaponResData, self.tbWeaponRes)
        return
    end
end

function ShipAvatarComponent:GetResId(szKey)
    return self.tbAvatarRes[szKey]
end

return ShipAvatarComponent
