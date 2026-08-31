-----------------------------------------------------
--File Name    : HumanWeaponItem.lua
--Author       : WuJizhou
--Create Time  : 8/29/2018, 11:23:50 AM
--Description  : HumanWeaponItem
-----------------------------------------------------
local luaclass = require("luaclass")
local EquipmentItemBase = require("EquipmentItemBase")
local HumanWeaponItem = luaclass("HumanWeaponItem", EquipmentItemBase)
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponDef = require("HumanWeaponDef")
local HumanWeaponItemPropertyHelper = require("HumanWeaponItemPropertyHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanWeaponPositionDef = require("HumanWeaponPositionDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local HumanWeaponScopeResDataTable = require("HumanWeaponScopeResDataTable")
local BattleItemSourceDef = require("BattleItemSourceDef")

local ClientEventDef = nil -- OnCreate时require
local TotalProperty = HumanWeaponDef.TotalProperty
local Property = HumanWeaponDef.Property
local FireType = HumanWeaponDef.FireType

HumanWeaponItem.tbProperty = nil
HumanWeaponItem.tbBaseProperty = nil

local function RefreshAvatar(self)
    local tbPlayer = self:GetOwnerCharacter()
    local nSlotIndex = self:GetStorageLocation().nSlotIndex
    local nWeaponInstanceType = self:GetWeaponInstanceType()
    if tbPlayer.HumanWeaponAvatarComponent then
        tbPlayer.HumanWeaponAvatarComponent:OnWeaponEquip(nSlotIndex, nWeaponInstanceType)
    end
end

local function FireHumanWeaponFireTypeChangedEvent(self, nInstanceId)
    if self:IsServerInstance() then
        EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_FIRE_TYPE_CHANGED_SERVER, nInstanceId)
    else
        EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_FIRE_TYPE_CHANGED_CLIENT, nInstanceId)
    end
end

local function FireHumanWeaponAttachmentChangedEvent(self, tbPlayer, tbEfficientAttachments)
    if self:IsServerInstance() then
        EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_ATTACHMENT_CHANGED_SERVER, tbPlayer, self, tbEfficientAttachments)
    else
        EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_ATTACHMENT_CHANGED_CLIENT, tbPlayer, self, tbEfficientAttachments)
    end
end

local function InitProperty(self)
    local nTemplateId = self:GetTemplateId()
    self.tbProperty,self.tbBaseProperty = HumanWeaponItemPropertyHelper.CreateProperty(nTemplateId)
end

local function UpdateProperty(self, tbEfficientAttachments)
    local tbAttachmentProperties = {}
    for _, v in ipairs(tbEfficientAttachments) do
        local tbTemplate = v:GetTemplate()
        local tbProperties = tbTemplate.tbProperty
        for k, property in pairs(tbProperties) do   --遍历配件的每条属性
            local tbTemp = tbAttachmentProperties[k]
            if tbTemp == nil then
                tbTemp = {0, 1}
                tbAttachmentProperties[k] = tbTemp
            end
            if k ~= Property.FireType and k ~= Property.BulletType then -- todo@ WuJizhou 开火类型和子弹类型需要特殊处理，暂时空缺，待策划有需求时再加
                if property[3] ~= nil then  -- 替代列生效
                    tbTemp[3] = property[3]
                else    --使用加法列和乘法列
                    tbTemp[1] = tbTemp[1] + property[1]
                    tbTemp[2] = tbTemp[2] * property[2]
                end
            end
        end
    end

    -- local tbTemplate = BattleItemDataTable:GetTemplate(self:GetTemplateId())
    for _, v in pairs(TotalProperty) do
        if v ~= Property.FireType and v ~= Property.BulletType then  --todo@ WuJizhou 开火类型和子弹类型需要特殊处理，暂时空缺，待策划有需求时再加
            local nValue
            local tbP = tbAttachmentProperties[v]
            if tbP ~= nil then
                if tbP[3] ~= nil then -- 替代列生效
                    nValue = tbP[3]
                else
                    local nAddValue = tbP[1]
                    local nMultiplyValue = tbP[2]
                    nValue = (self.tbBaseProperty[v] + nAddValue) * nMultiplyValue
                end
            else
                nValue = self.tbBaseProperty[v]
            end
            if v == Property.BulletMax or
                v == Property.DecreaseBulletCount or
                v == Property.MaxSpotCount then
                nValue = math.floor(nValue)
            end
            self.tbProperty[v] = nValue
        end
    end
end

local NONE_INTERVAL = -1
local NONE_TIMES = -1
---------------public function-----------------

function HumanWeaponItem:GetAttackInfo()
    assert(self.tbProperty ~= nil)
    local tbTemplate = self:GetTemplate()
    if tbTemplate.nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
        return NONE_INTERVAL, NONE_TIMES
    else
        local nCurFireType = self.tbProperties.nFireType
        local nAttackTimes
        if nCurFireType == FireType.Single then
            nAttackTimes = 1
        elseif nCurFireType == FireType.Triple then
            nAttackTimes = 3
        else
            nAttackTimes = NONE_TIMES
        end
        return self.tbProperties.nRateOfFire, nAttackTimes
    end
end

function HumanWeaponItem:ChangeFireType()
    assert(self.tbProperty ~= nil)
    local nCurType = self.tbProperty.nFireType
    local tbTemplate = self:GetTemplate()
    local tbFireTypes = tbTemplate.tbFireTypes
    local nIdx = 1
    for idx, v in ipairs(tbFireTypes) do
        if nCurType == v then
            nIdx = idx
            break
        end
    end
    if nIdx == #tbFireTypes then
        nIdx = 1
    else
        nIdx = nIdx + 1
    end
    self.tbProperty.nFireType = tbFireTypes[nIdx]
    FireHumanWeaponFireTypeChangedEvent(self, self:GetInstanceId())
    return
end

function HumanWeaponItem:GetUnequipedMatchingAmmoCount(bIsClient)
    local nBulletTemplateId = self:GetTemplate().nBulletType
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    local nCount = 0
    if bIsClient then
        nCount = BattleItemSystem:GetUnequippedItemCount(nBulletTemplateId)
    else
        local tbCharacter = self:GetOwnerCharacter()
        nCount = BattleItemSystem:GetUnequippedItemCount(tbCharacter:GetServerInstanceId(), nBulletTemplateId)
    end
    return nCount
end

function HumanWeaponItem:SetCurrentWeapon(bCurrentWeapon)
    local OwnerCharacter = self:GetOwnerCharacter()
    if OwnerCharacter then
        local WeaponComponent = OwnerCharacter.HumanWeaponComponent
        if(WeaponComponent) then
            return WeaponComponent:SetCurrentWeapon(bCurrentWeapon and self:GetInstanceId() or 0)
        end
    end
    return false
end

function HumanWeaponItem:IsCurrentWeapon()
    -- call bp function to check
    local tbOwner = self:GetOwnerCharacter()
    if not tbOwner then
        return false
    end
    local WeaponComponent = tbOwner.HumanWeaponComponent
    if(WeaponComponent) then
        return WeaponComponent:GetCurrentWeaponInstanceId() == self:GetInstanceId()
    end
    return false
end

-- 获取可装填的弹药类型
function HumanWeaponItem:GetBulletItemTemplateId()
    local tb
    if self.tbProperty == nil then
        tb = self:GetTemplate()
    else
        tb = self.tbProperty
    end
    return tb[Property.BulletType]
end

-- 获取可装填的弹药数量上限
function HumanWeaponItem:GetBulletMax()
    local tb
    if self.tbProperty == nil then
        tb = self:GetTemplate()
    else
        tb = self.tbProperty
    end
    return tb[Property.BulletMax]
end

-- 获取腰射准星资源
function HumanWeaponItem:GetSightRes()
    return self:GetTemplate().szSightRes
end

-- 获取当前准镜资源
function HumanWeaponItem:GetScopeRes()
    local tb
    if self.tbProperty == nil then
        tb = self:GetTemplate()
    else
        tb =  self.tbProperty
    end
    local nId = tb[Property.ScopeResId]
    return HumanWeaponScopeResDataTable:GetTemplate(nId), nId
end

--获取当前武器准星散布程度的范围（仅作用于UI准星显示），返回值为最小值nMin，最大值nMax
function HumanWeaponItem:GetUISightDispersionRange()
    local tbTemplate = self:GetTemplate()
    return tbTemplate.nMinDispersionForUISight, tbTemplate.nMaxDispersionForUISight
end

--获取当前武器准星ui扩散，最大值nMax
function HumanWeaponItem:GetUISightZoomMax()
    local tbTemplate = self:GetTemplate()
    return tbTemplate.nMaxZoomForUISight
end

function HumanWeaponItem:GetWeaponInstanceType()
    local tbTemplate = self:GetTemplate()
    return tbTemplate.nWeaponInstanceType
end

-- 当第一次加这道具时是否需要装子弹
function HumanWeaponItem:NeedEquipBulletWhenAddedFirstTime()
    if self:IsInitialItem() then
        local nBulletItemTemplateId =  self:GetBulletItemTemplateId()
        if nBulletItemTemplateId and nBulletItemTemplateId > 0 then
            return true
        end
    end
    return false
end

-- 获得的时候自动装弹
function HumanWeaponItem:AfterAddedToCharacterOnServer(nBattleItemSource, bSyncToClient)
    if self:NeedEquipBulletWhenAddedFirstTime() then
        local nBulletItemTemplateId =  self:GetBulletItemTemplateId()
        local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
        BattleItemSystemServer:CreateAndEquipItemWithOwner(self:GetOwnerCharacterInstanceId(), self:GetInstanceId(),
            nBulletItemTemplateId, self:GetBulletMax(), BattleItemSourceDef.WEAPON_INIT_BULLETS, bSyncToClient)

        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_EQUIP_BULLET_WHEN_ADDED_FIRST_TIME_SERVER, self)
    end
end

function HumanWeaponItem:GetCurrentAmmoCount(bIsClient)
    if self:GetTemplate().nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
        return nil
    end
    local nCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local nOwnerInstanceId = self:GetInstanceId()
    local tbTemplate = self:GetTemplate()
    local nCount = BattleItemSystemHelper:GetEquippedItemCount(nCharacterInstanceId, nOwnerInstanceId, tbTemplate.nBulletType, bIsClient)
    local bIsNil = nCount == nil
    if bIsNil then
        logerror("HumanWeaponItem:GetCurrentAmmoCount, count is nil")
    end
    return bIsNil and 0 or nCount
end


--请求bp去reload，主要是播放动画
function HumanWeaponItem:RequestToReload()
    local WeaponComponent = self:GetOwnerCharacter().HumanWeaponComponent
    if(WeaponComponent) then
        WeaponComponent:Reload()
    end
end

--nCount为子弹减少数量，可以为nil，此时默认减1
function HumanWeaponItem:DecreaseAmmoCount(nCount)
    nCount = nCount == nil and 1 or nCount
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local nCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local nOwnerInstanceId = self:GetInstanceId()
    local tbAmmo = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_BULLET, nOwnerInstanceId)
    if tbAmmo ~= nil then
        assert(tbAmmo:GetStackCount() - nCount >= 0)
        BattleItemSystemServer:DecreasePlayerItemCount(nCharacterInstanceId, tbAmmo:GetInstanceId(), nCount)
    else
        logwarning("HumanWeaponItem:DecreaseAmmoCount, ammo item is nil")
    end
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_AMMO_CHANGED_SERVER,
        self)
end

--bp reload后的回调，即播放完之后调用此方法，去进行item系统中的reload
function HumanWeaponItem:OnReload()
    assert(GlobalVariableSystem:IsServerLogic())
    local tbTemplate = self:GetTemplate()
    if tbTemplate.nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
        return
    end
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local nCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local nOwnerInstanceId = self:GetInstanceId()
    local nCount = self:GetBulletMax()
    BattleItemSystemServer:EquipStackableItem(nCharacterInstanceId, nOwnerInstanceId, tbTemplate.nBulletType, nCount)
end


function HumanWeaponItem:OnAttachmentChanged(tbEfficientAttachments)
    UpdateProperty(self, tbEfficientAttachments)
    FireHumanWeaponAttachmentChangedEvent(self, self:GetOwnerCharacter(), tbEfficientAttachments)
end

function HumanWeaponItem:GetProperty(bIsClient)
    if self.tbProperty == nil then
        InitProperty(self)
        local nPlayerId = nil
        if self:GetOwnerCharacter() then
            nPlayerId = self:GetOwnerCharacterInstanceId()
        end
        if nPlayerId then
            local tbAttachments = BattleItemSystemHelper:GetEquippedItems(nPlayerId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, self:GetInstanceId(), bIsClient)
            local tbEfficientAttachments = {}
            for k, v in pairs(tbAttachments) do
                table.insert(tbEfficientAttachments, v)
            end
            UpdateProperty(self, tbEfficientAttachments)
        end
    end
    return self.tbProperty
end

function HumanWeaponItem:GetBaseProperty(bIsClient)
    self:GetProperty(bIsClient)
    return self.tbBaseProperty
end

function HumanWeaponItem:SetBaseProperty(tbProperty)
    for _, v in pairs(Property) do
        if v ~= Property.FireType and v ~= Property.FireType then  --todo@ WuJizhou 开火类型和子弹类型需要特殊处理，暂时空缺，待策划有需求时再加
            local nValue = tbProperty[v]
            if nValue == nil then
                nValue = self.tbBaseProperty[v]
            end
            if not nValue then
                logerror("HumanWeaponItem:SetBaseProperty error, illegal property type : ", v)
            else
                if v == Property.BulletMax or
                v == Property.DecreaseBulletCount or
                v == Property.MaxSpotCount then
                    nValue = math.floor(nValue)
                end
                self.tbBaseProperty[v] = nValue
            end
        end
    end
end

function HumanWeaponItem:ActivateAttachmentProperty(tbEfficientAttachments)
    self:OnAttachmentChanged(tbEfficientAttachments)
end


---------------call back for Item system--------
function HumanWeaponItem:OnCreate(...)
    HumanWeaponItem.super.OnCreate(self, ...)
    if GlobalVariableSystem:IsClient() then
        ClientEventDef = require("ClientEventDef")
    end
end

function HumanWeaponItem:GetWeaponPosition()
    local tbTemplate = self:GetTemplate()
    local nPrimaryCategory = tbTemplate.nPrimaryCategory
    if nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
        return HumanWeaponPositionDef.MELEE
    end

    local nWeaponCategory = tbTemplate.nWeaponCategory
    local nSlotIndex = self:GetStorageLocation().nSlotIndex
    if nWeaponCategory == HumanWeaponDef.WeaponCategory.Pistol then
        if nSlotIndex == 1 then
            return HumanWeaponPositionDef.HAND_GUN_PRIMARY
        else
            return HumanWeaponPositionDef.HAND_GUN_SECONDARY
        end
    else
        if nSlotIndex == 1 then
            return HumanWeaponPositionDef.LONG_GUN_PRIMARY
        else
            return HumanWeaponPositionDef.LONG_GUN_SECONDARY
        end
    end

end

function HumanWeaponItem:OnEquipOnServer()
    InitProperty(self)
    RefreshAvatar(self)

    local nOwnerCharacterInstanceId = self:GetOwnerCharacterInstanceId()

    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_SERVER, nOwnerCharacterInstanceId, self)
end

function HumanWeaponItem:OnEquipOnClient()
    InitProperty(self)

    local nOwnerCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_CLIENT, nOwnerCharacterInstanceId, self)
end

function HumanWeaponItem:OnUnequipOnServer()
    local nOwnerCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    RefreshAvatar(self)
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_UNEQUIPED_SERVER, nOwnerCharacterInstanceId, self)
end

function HumanWeaponItem:OnUnequipOnClient()
    local nOwnerCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_ON_UNEQUIPED_CLIENT, nOwnerCharacterInstanceId, self)
end

function HumanWeaponItem:IsBulletInfinite()
    return BattleItemSystemHelper:IsHumanBulletInfinite()
end

return HumanWeaponItem