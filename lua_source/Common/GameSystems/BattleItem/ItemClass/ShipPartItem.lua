-----------------------------------------------------
--File Name    : ShipPartItem.lua
--Author       : chenjing6
--Create Time  : 2018-08-03
--Description  : 船零件插槽物件
-----------------------------------------------------

local luaclass = require("luaclass")
local EquipmentItemBase = require("EquipmentItemBase")
local ShipPartItem = luaclass("ShipPartItem", EquipmentItemBase)

local PropName = require("PropName")
local ShipPartTypeDef   = require("ShipPartTypeDef")
local BattleItemSystemHelper  = require("BattleItemSystemHelper")
local GameObjectSystem  = dynamic_require("GameObjectSystem")
local ShipPartBrokenStatus   = require("ShipPartBrokenStatus")
local EventManager      = require("EventManager")
local CommonEventDef    = require("CommonEventDef")
local AIHelper = require("AIHelper")
local PropertyWrapperType = require("PropertyWrapperType")

ShipPartItem.nDurability = 0
ShipPartItem.nLastBrokenStatus = 0
ShipPartItem.tbCacheOverlapIds = { }
ShipPartItem.nAppearResId = 0
-- ShipPartItem.pHoldResource = nil
-- ShipPartItem.nLoadHandler = nil

local tbDurabilityToBrokenStatus = {
    { nLimit = 50,  nStatus = ShipPartBrokenStatus.BROKEN  },
    { nLimit = 75,  nStatus = ShipPartBrokenStatus.DAMANGED  },
    { nLimit = 101, nStatus = ShipPartBrokenStatus.UNBROKEN  },
}

local MAX_HP_PERCENT_KEY = "nMaxHpPercent"

local tbAddWrapperPropertys = {
    ["nFireDamageResistance"] = PropName.nBurningProofProb,
    ["nLeakDamageResistance"] = PropName.nLeakingProofProb,
    ["nSlowSpeedResistance"] = PropName.nSlowSpeedResistance,
    ["nStunResistance"] = PropName.nStunResistance,
    ["nSpeedAddition"] = PropName.nLinearMaxSpeedAddition,
    ["nAngleSpeedAddition"] = PropName.nAngularMaxSpeedAddition
}

local tbMultiplyWrapperPropertys = {
    ["nSpeedAdditionPercent"] = PropName.nLinearMaxSpeedAddition,
    ["nAngleSpeedAdditionPercent"] = PropName.nAngularMaxSpeedAddition
}

local tbSlotTypeToResPart   =
{
    --[ShipPartTypeDef.SAIL]  = "sail",
    [ShipPartTypeDef.ARMOR]  = "armor",
    [ShipPartTypeDef.CAPTAIN_ROOM]  = "captain_cabin",
}

local function LOG(szFormat, ...)
    log("ShipPartItem:" .. szFormat, ...)
end

local function NotifyShipPartDestroyed(self)
    local nInstanceId = self:GetInstanceId()
    LOG("NotifyShipPartDestroyed ", nInstanceId)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    BattleItemSystemServer:DestroyPlayerItem(self:GetOwnerCharacterInstanceId(), nInstanceId)
end

local function ConvertDamageToArmorReduce(nDamage)
    return math.floor(nDamage)
end
--------------------------------------------------server--------------------------------------------
-- 百分比添加当前血量
local function AddMaxHpEffect(PropertyComponent, nPropValue)
    local nCurrentMultiplyValue = PropertyComponent:GetPropMultiplyValue(PropName.nShipMaxHp)
    local nHp = PropertyComponent:GetHp()
    nHp = nHp / nCurrentMultiplyValue * (nCurrentMultiplyValue + nPropValue)
    PropertyComponent:SetPropOriginValue(PropertyComponent.nHpId, nHp)
end

-- 百分比扣除当前血量
local function RemoveMaxHpEffect(PropertyComponent, nPropValue)
    local nCurrentMultiplyValue = PropertyComponent:GetPropMultiplyValue(PropName.nShipMaxHp)
    local nHp = PropertyComponent:GetHp()
    nHp = nHp / nCurrentMultiplyValue * (nCurrentMultiplyValue - nPropValue)
    PropertyComponent:SetPropOriginValue(PropertyComponent.nHpId, nHp)
end

local function ApplyEffect(self)
    local tbStorageLocation = self:GetStorageLocation()
    local tbPlayerObject = GameObjectSystem:FindByInstanceId(tbStorageLocation.nOwnerInstanceId)
    local tbTemplateConfig = self.tbTemplate
    if tbPlayerObject and tbPlayerObject.nPlayerId and tbPlayerObject.pUEActor and tbTemplateConfig then
        LOG("apply ship part effect")
        self.tbCacheOverlapIds = { }
        local ShipBattlePropertyComponent = tbPlayerObject.ShipBattlePropertyComponent
        for szPropName,nPropId in pairs(tbAddWrapperPropertys) do
            local nPropertyValue = tbTemplateConfig[szPropName]
            if nPropertyValue then
                local nOverlapId = ShipBattlePropertyComponent:PropOverlap(PropertyWrapperType.TYPE_ADD, nPropId, nPropertyValue)
                table.insert(self.tbCacheOverlapIds, { PropId = nPropId, Id = nOverlapId, PropName = szPropName, PropValue = nPropertyValue })
                LOG("apply ship part property [", szPropName, "] with add operation, value=", nPropertyValue, " ok")
            end
        end
        for szPropName,nPropId in pairs(tbMultiplyWrapperPropertys) do
            local nPropertyValue = tbTemplateConfig[szPropName]
            if nPropertyValue then
                local nOverlapId = ShipBattlePropertyComponent:PropOverlap(PropertyWrapperType.TYPE_MULTIPLY, nPropId, nPropertyValue)
                table.insert(self.tbCacheOverlapIds, { PropId = nPropId, Id = nOverlapId, PropName = szPropName, PropValue = nPropertyValue })
                LOG("apply ship part property [", szPropName, "] with multiply operation, value=", nPropertyValue, " ok")
            end
        end
        local nPropertyValue = tbTemplateConfig[MAX_HP_PERCENT_KEY]
        if nPropertyValue then
            AddMaxHpEffect(ShipBattlePropertyComponent, nPropertyValue)
            local nPropId = PropName.nShipMaxHp
            local szPropName = MAX_HP_PERCENT_KEY
            local nOverlapId = ShipBattlePropertyComponent:PropOverlap(PropertyWrapperType.TYPE_MULTIPLY, nPropId, nPropertyValue)
            table.insert(self.tbCacheOverlapIds, { PropId = nPropId, Id = nOverlapId, PropName = szPropName, PropValue = nPropertyValue })
            LOG("apply ship part property [", szPropName, "] with multiply operation, value=", nPropertyValue, " ok")
        end
    end
end

local function RemoveEffect(self)
    local tbStorageLocation = self:GetStorageLocation()
    local tbPlayerObject = GameObjectSystem:FindByInstanceId(tbStorageLocation.nOwnerInstanceId)
    local tbTemplateConfig = self.tbTemplate
    if tbPlayerObject and tbPlayerObject.nPlayerId and tbPlayerObject.pUEActor and tbTemplateConfig then
        LOG("remove ship part effect", #self.tbCacheOverlapIds)
        for _,v in ipairs(self.tbCacheOverlapIds) do
            local ShipBattlePropertyComponent = tbPlayerObject.ShipBattlePropertyComponent
            if v.PropName == MAX_HP_PERCENT_KEY then
                RemoveMaxHpEffect(ShipBattlePropertyComponent, v.PropValue)
            end
            ShipBattlePropertyComponent:RemovePropOverlap(v.PropId, v.Id)
            LOG("remove ship part property [", v.PropName, "]")
        end
        self.tbCacheOverlapIds = { }
    end
end

local function ApplyAppearanceChange(self)
    local tbStorageLocation = self:GetStorageLocation()
    local nSlotIndex = tbStorageLocation.nSlotIndex
    local tbPlayerSelf = self.tbOwnerCharacter
    if tbPlayerSelf and tbPlayerSelf:IsShip() and tbPlayerSelf.ShipAvatarComponent then
        local tbTemplateConfig = self.tbTemplate
        if tbTemplateConfig and tbTemplateConfig.nAppearanceResId > 0 then
            if tbSlotTypeToResPart[nSlotIndex] then
                local szSlotKey = tbSlotTypeToResPart[nSlotIndex]
                -- 原始外观目前支持为0，后续如果有叠加情况需要处理 ShipAvartarComponent里面InitAvartar提前加载的影响
                self.nAppearResId = 0 --tbPlayerSelf.ShipAvatarComponent:GetResId(szSlotKey)
                local tbChangedRes = { }
                tbChangedRes[szSlotKey] = tbTemplateConfig.nAppearanceResId
                LOG("apply ship appearance of ", szSlotKey, self.nAppearResId, " to ", tbTemplateConfig.nAppearanceResId)
                tbPlayerSelf.ShipAvatarComponent:SetAvatarResData(tbChangedRes)

                if nSlotIndex == ShipPartTypeDef.ARMOR then
                    tbPlayerSelf.ShipAvatarComponent:SetShipArmorGrade(
                        tbTemplateConfig.nGrade)
                end
            end
        end
    end
end

local function RemoveAppearanceChange(self)
    local tbStorageLocation = self:GetStorageLocation()
    local nSlotIndex = tbStorageLocation.nSlotIndex
    local tbPlayerSelf = self.tbOwnerCharacter
    if tbPlayerSelf and tbPlayerSelf:IsShip() and tbPlayerSelf.ShipAvatarComponent then
        local tbTemplateConfig = self.tbTemplate
        if tbTemplateConfig and tbTemplateConfig.nAppearanceResId > 0 then
            if tbSlotTypeToResPart[nSlotIndex] then
                local szSlotKey = tbSlotTypeToResPart[nSlotIndex]
                local tbChangedRes = { }
                tbChangedRes[szSlotKey] = self.nAppearResId
                LOG("remove ship appearance of ",tbTemplateConfig.nAppearanceResId, " to ", self.nAppearResId)
                tbPlayerSelf.ShipAvatarComponent:SetAvatarResData(tbChangedRes)
            end
        end
    end
end

local function OnRefreshShipBrokenStatus(self)
    local nCurBrokenStatus = self:GetBrokenStatus()
    if nCurBrokenStatus ~= self.nLastBrokenStatus then
        self.nLastBrokenStatus = nCurBrokenStatus
        if self.tbOwnerCharacter and self.tbOwnerCharacter.ShipAvatarComponent then
            local tbStorageLocation = self:GetStorageLocation()
            local tbBrokenStatus = { }
            local szBrokenKey = tbSlotTypeToResPart[tbStorageLocation.nSlotIndex]
            tbBrokenStatus[szBrokenKey] = nCurBrokenStatus
            self.tbOwnerCharacter.ShipAvatarComponent:SetBrokenStatusData(tbBrokenStatus)
        end
    end
end


function ShipPartItem:OnCreate()
    local tbTemplate = self:GetTemplate()
    self.nDurability = tbTemplate.nDurability
    self.nLastBrokenStatus = 0
end

function ShipPartItem:OnEquipOnServer()
    if self.tbOwnerCharacter then
        self.nLastBrokenStatus = 0
        ApplyEffect(self)
        if self.tbOwnerCharacter:IsShip() then
            ApplyAppearanceChange(self)
            OnRefreshShipBrokenStatus(self)
        end
        EventManager:OnFireEvent(CommonEventDef.EV_SHIP_ARMOR_ON_EQUIPED_SERVER, self.tbOwnerCharacter, self:GetInstanceId())
    end
end


function ShipPartItem:OnUnequipOnServer()
    if self.tbOwnerCharacter then
        EventManager:OnFireEvent(CommonEventDef.EV_SHIP_ARMOR_ON_UNEQUIPED_SERVER, self.tbOwnerCharacter, self:GetInstanceId())
        RemoveEffect(self)
        if self.tbOwnerCharacter:IsShip() then
            RemoveAppearanceChange(self)
        end
    end
end


function ShipPartItem:ApplyDamage(nDamage)
    local tbOwnerCharacter = self.tbOwnerCharacter
    -- 机器人和npc 的护甲不扣耐久
    if tbOwnerCharacter and AIHelper.IngoreShipPartItemDamage(tbOwnerCharacter) then
        return
    end
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    if self.nDurability > 0 then
        local nDurabilityReduce = ConvertDamageToArmorReduce(nDamage)
        if nDurabilityReduce > 0 then
            self:SetDurability(self.nDurability - nDurabilityReduce)
            EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_CHANGE_DURABILITY_SERVER, self:GetInstanceId(), self:GetDurability())
            LOG("change ship durability form ", self.nDurability + nDurabilityReduce, " to ", self.nDurability)
            OnRefreshShipBrokenStatus(self)
            if self.nDurability <= 0 then
                if self.tbTemplate.bCanDestroy then
                    NotifyShipPartDestroyed(self)
                else
                    BattleItemSystemServer:SyncDurability(self:GetInstanceId())
                    RemoveEffect(self)
                end
            else
                BattleItemSystemServer:SyncDurability(self:GetInstanceId())
            end
        end
    end
end

function ShipPartItem:RecoverDurability(nDurability)
    if nDurability > 0 then
        if self.nDurability <= 0 then
            ApplyEffect(self)
        end
        self.nDurability = self.nDurability + nDurability
        local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
        BattleItemSystemServer:SyncDurability(self:GetInstanceId())
    end

end


function ShipPartItem:GetBrokenStatus()
    local nDurabilityPercent = self.nDurability * 100 // self.tbTemplate.nDurability
    for _,v in ipairs(tbDurabilityToBrokenStatus) do
        if nDurabilityPercent < v.nLimit then
            return v.nStatus
        end
    end
    return ShipPartBrokenStatus.UNBROKEN
end

function ShipPartItem:GetAvatarRes()
    local tbStorageLocation = self:GetStorageLocation()
    local nSlotIndex = tbStorageLocation.nSlotIndex
    local tbTemplateConfig = self.tbTemplate
    if tbTemplateConfig and tbTemplateConfig.nAppearanceResId > 0 then
        if tbSlotTypeToResPart[nSlotIndex] then
            local szSlotKey = tbSlotTypeToResPart[nSlotIndex]
            local tbChangedRes = { }
            tbChangedRes[szSlotKey] = tbTemplateConfig.nAppearanceResId
            return tbChangedRes
        end
    end
end

--------------------------------------------------client--------------------------------------------

-- local function ClearCacheObject(self)
--     self.nLoadHandler = nil
--     if self.pHoldResource then
--         LOG("unhold resource ", self.nInstanceId)
--         local ResourceManager = require("ResourceManager")
--         ResourceManager:Unhold(self.pHoldResource)
--         self.pHoldResource = nil
--     end
-- end



function ShipPartItem:OnEquipOnClient()
    -- -- preload ship part resource in human style
    -- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
    -- local PlayerSelf = GamePlayerSelfHelper:Get()
    -- if self.tbOwnerCharacter == PlayerSelf then
    --     ClearCacheObject(self)
    --     local ResourceManager = require("ResourceManager")
    --     local function fnLoadEnd(szAssetName, pObject, nHandler)
    --         if nHandler == self.nLoadHandler then
    --             if not pObject then
    --                 logdebug("Error ShipPartItem:OnEquipOnClient " .. szAssetName)
    --                 return
    --             end
    --             self.pHoldResource = pObject
    --             ResourceManager:Hold(pObject)
    --             LOG("hold resource", szAssetName, self.nInstanceId)
    --         end
	-- 	end
    --     local tbTemplateConfig = self.tbTemplate
    --     if tbTemplateConfig and tbTemplateConfig.nAppearanceResId > 0 then
    --         local szResourcePath = ExtendBlueprintFunctions.GetAvatarPartResourceData(tbTemplateConfig.nAppearanceResId, "")
    --         self.nLoadHandler = ResourceManager:LoadAsync(szResourcePath, fnLoadEnd)
    --     end
    -- end
end


function ShipPartItem:OnUnequipOnClient()
    -- ClearCacheObject(self)
    -- luacheck: push ignore

    -- luacheck: pop
end

function ShipPartItem:OnDurabilityChangedOnClient()

end

function ShipPartItem:GetDurability()
    return self.nDurability
end

-- 策划需求：显示的时候把耐久除以100
function ShipPartItem:GetDurabilityPercentageString()
    local nMaxDurability = self.tbTemplate.nDurability
    local nCurrentDurability = self.nDurability
    return (nCurrentDurability * 100 // nMaxDurability) .. "%"
end

function ShipPartItem:SetDurability(nDurability)
    self.nDurability = nDurability
    if self.nDurability < 0 then
        self.nDurability = 0
    end
end

function ShipPartItem:GetProtoData()
    local tbData = ShipPartItem.super.GetProtoData(self)
    tbData.durability = self.nDurability
    return tbData
end

function ShipPartItem:InitWithProtoData(tbPlayer, tbItemProtoData)
    ShipPartItem.super.InitWithProtoData(self, tbPlayer, tbItemProtoData)
    self.nDurability = tbItemProtoData.durability
end


function ShipPartItem:OnDestroy(...)
    --logdebug("ShipPartItem:OnDestroy")
end

return ShipPartItem