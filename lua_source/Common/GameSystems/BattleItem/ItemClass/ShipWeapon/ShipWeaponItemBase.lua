-----------------------------------------------------
--File Name    : ShipWeaponItemBase.lua
--Author       : Song Fuhao
--Create Time  : 2020-08-03
--Description  : 武器Item基类
-----------------------------------------------------
local luaclass = require("luaclass")
local EquipmentItemBase = require("EquipmentItemBase")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local PropName = require("PropName")
local ShipWeaponFiringType = require("ShipWeaponFiringType")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local BattleShipWeaponEventHelper = require("BattleShipWeaponEventHelper")
local BattleShipWeaponProtoHelper = require("BattleShipWeaponProtoHelper")
local ShipWeaponFiringFailedDef = require("ShipWeaponFiringFailedDef")
local MathUtil = require("MathUtil")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

--- @class ShipWeaponItemBase
local ShipWeaponItemBase = luaclass("ShipWeaponItemBase", EquipmentItemBase)

ShipWeaponItemBase.bIsInFiring = false
ShipWeaponItemBase.nLastFiringCD = 0
ShipWeaponItemBase.nLastFiringTime = 0
ShipWeaponItemBase.nLastFiringCharacterInstanceId = 0

local FIRING_STATE_WITH_OPERATION = {
    [ShipFiringOperationDef.START] = true,
    [ShipFiringOperationDef.END] = false,
    [ShipFiringOperationDef.CANCEL] = false,
}

local function LOG(self, ...)
    local OwnerCharacter = self:GetOwnerCharacter()
    local szOwnerName = OwnerCharacter and OwnerCharacter.szName
    log("[BattleShipWeapon][ItemBase]", szOwnerName, self:GetInstanceId(), ...)
end

-- 检查是否处于CD中
local function IsInFiringCD(self)
    return self:GetRemainingFiringCD() > 0
end

-- 给蓝图Component设置各属性
local function SetupBPComponentParams(self)
    LOG(self, "SetupBPComponentParams")
    local tbTemplate = self:GetTemplate()
    local nSubCategory = self:GetSubCategory()
    local nWeaponId = self:GetInstanceId()
    local nBaseDamage = tbTemplate.nBaseDamage
    local nDamageRadius = tbTemplate.nDamageRadius
    local nDamageInnerRadius = tbTemplate.nDamageInnerRadius
    local nMinRadiusDamage = tbTemplate.nMinRadiusDamage
    local bAutoBoom = tbTemplate.bAutoBoom
    local pWeaponSlot = ShipWeaponSlotDef.GetBPEnum(self:GetWeaponSlot())
    local bPairedWeapon = ShipWeaponCategoryDataTable:GetIsPairedWeapon(nSubCategory)
    local pBulletClass = nil
    if tbTemplate.szBulletRes then
        if GlobalVariableSystem:IsClient() then
            local ResourceCacheSystem = require("ResourceCacheSystem")
            pBulletClass = ResourceCacheSystem:SyncCacheInDungeon(tbTemplate.szBulletRes)
        else
            pBulletClass = tbTemplate.szBulletRes:load()
        end
    end
    local nHalfRotationRange = tbTemplate.nRotationRange / 2
    local pFiringType = ShipWeaponFiringType.GetBPEnum(tbTemplate.nFiringType)
    local nMinFiringRange = tbTemplate.nMinFiringRange
    local nFiringRange = tbTemplate.nFiringRange
    local nBulletSpeed = tbTemplate.nBulletSpeed
    local tbValidWeaponSlotLevel = tbTemplate.tbValidWeaponSlotLevel
    local nTriggerRange = tbTemplate.nTriggerRange
    self:GetBPComponent():Setup(nWeaponId, nBaseDamage, nDamageRadius, nDamageInnerRadius, nMinRadiusDamage,
    bAutoBoom, nTriggerRange, pWeaponSlot, bPairedWeapon, pBulletClass, nHalfRotationRange,
    pFiringType, nMinFiringRange, nFiringRange, nBulletSpeed, tbValidWeaponSlotLevel)
end

function ShipWeaponItemBase:OnActivateWeapon()
    -- derived class implement it.
end

function ShipWeaponItemBase:OnDeactivateWeapon()
    -- derived class implement it.
end

function ShipWeaponItemBase:IsValidFiringState(nFiringOperation)
    -- derived class implement it.
    return false
end

function ShipWeaponItemBase:StartFiring()
    -- derived class implement it.
    self:OnStartFiring()
end

function ShipWeaponItemBase:EndFiring()
    -- derived class implement it.
    self:OnEndFiring()
end

function ShipWeaponItemBase:CancelFiring()
    -- derived class implement it.
    self:OnCancelFiring()
end

function ShipWeaponItemBase:OnStartFiring()
    -- derived class implement it.
end

function ShipWeaponItemBase:OnEndFiring()
    -- derived class implement it.
end

function ShipWeaponItemBase:OnCancelFiring()
    -- derived class implement it.
end

function ShipWeaponItemBase:IsInFiring()
    return self.bIsInFiring
end

function ShipWeaponItemBase:GetLastFiringTime()
    return self.nLastFiringTime
end

function ShipWeaponItemBase:GetLastFiringCD()
    return self.nLastFiringCD
end

function ShipWeaponItemBase:IsReadyToFire(nFiringOperation)
    if nFiringOperation == ShipFiringOperationDef.START then
        if self.bIsInFiring then
            return false, ShipWeaponFiringFailedDef.IN_FIRING
        end
        if IsInFiringCD(self) then
            return false, ShipWeaponFiringFailedDef.IN_FIRING_CD
        end
    else
        -- 服务器上执行取消、结束操作时，需要验证是否处于开火中，客户端由于协议延迟问题，不做验证
        if self:IsServerInstance() and (not self.bIsInFiring) then
            return false, ShipWeaponFiringFailedDef.NOT_IN_FIRING
        end
    end
    return self:IsValidFiringState(nFiringOperation), ShipWeaponFiringFailedDef.INVALID_OPERATION
end

function ShipWeaponItemBase:IsReadyToLoadBullet()
    -- derived class implement it.
    return false
end

function ShipWeaponItemBase:DecreaseBullet()
    -- derived class implement it.
end

function ShipWeaponItemBase:StartFiringCD()
    LOG(self, "StartFiringCD")
    self.nLastFiringCD = self:GetFiringInterval()
    self.nLastFiringTime = GlobalVariableSystem:GetDSTimeSeconds()
    self.nLastFiringCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    BattleShipWeaponProtoHelper.NotifyFiringCdBegan(self, self.nLastFiringCD)
end

-- 动态更新BpComponent上一些数据炮弹基础数据
function ShipWeaponItemBase:UpdateShotBaseInfo()
    LOG(self, "UpdateShotBaseInfo")
    local PropertyComponent = self:GetOwnerCharacter().ShipBattlePropertyComponent
    local nBulletSpeedRatio = PropertyComponent:GetProp(PropName.nBulletSpeedRatio)
    local nBulletSpeedDelta = PropertyComponent:GetProp(PropName.nBulletSpeedDelta)
    local nBulletMinRadiusDamageRatio = PropertyComponent:GetPropMultiplyValue(PropName.nBulletMinRadiusDamageAddition)
    local nBulletMinRadiusDamageDelta = PropertyComponent:GetPropAddValue(PropName.nBulletMinRadiusDamageAddition)
    local nBulletTriggerRangeRatio = PropertyComponent:GetProp(PropName.nBulletTriggerRangeRatio)
    local nBulletTriggerRangeDelta = PropertyComponent:GetProp(PropName.nBulletTriggerRangeDelta)
    self:GetBPComponent():SetShotAdditionInfo(nBulletSpeedRatio, nBulletSpeedDelta,
    nBulletMinRadiusDamageRatio, nBulletMinRadiusDamageDelta,
    nBulletTriggerRangeRatio, nBulletTriggerRangeDelta)
end

function ShipWeaponItemBase:ActivateWeapon()
    LOG(self, "ActivateWeapon")
    if (self:IsServerInstance() or (not GlobalVariableSystem:IsStandalone())) then
        SetupBPComponentParams(self)
        self:UpdateShotBaseInfo()
        self:GetBPComponent():ActivateWeapon()
        self:OnActivateWeapon()
    end
end

function ShipWeaponItemBase:DeactivateWeapon(bDestroy)
    LOG(self, "DeactivateWeapon")
    if self:IsInFiring() then
        self:Fire(ShipFiringOperationDef.CANCEL)
    end
    if (self:IsServerInstance() or (not GlobalVariableSystem:IsStandalone())) then
        self:OnDeactivateWeapon()
        self:GetBPComponent():DeactivateWeapon()
    end
end

-- 还没想的很清楚，先跑通
function ShipWeaponItemBase:Fire(nFiringOperation)
    local bResult, nFailedReason = self:IsReadyToFire(nFiringOperation)
    if not bResult then
        LOG(self, "Fire failed, nFailedReason =", nFailedReason)
        return false, nFailedReason
    end
    LOG(self, "Fire", nFiringOperation)
    if nFiringOperation == ShipFiringOperationDef.START then
        self.bIsInFiring = true
        BattleShipWeaponProtoHelper.NotifyFiringOperationChanged(self:GetOwnerCharacter(), self:GetInstanceId(), nFiringOperation)
        BattleShipWeaponEventHelper.FireOnShipWeaponFiringOperationChangedEvent(self, nFiringOperation)
        self:StartFiring()
    elseif nFiringOperation == ShipFiringOperationDef.END then
        self.bIsInFiring = false
        self:StartFiringCD()
        self:EndFiring()
        BattleShipWeaponProtoHelper.NotifyFiringOperationChanged(self:GetOwnerCharacter(), self:GetInstanceId(), nFiringOperation)
        BattleShipWeaponEventHelper.FireOnShipWeaponFiringOperationChangedEvent(self, nFiringOperation)
        self:DecreaseBullet()
    elseif nFiringOperation == ShipFiringOperationDef.CANCEL then
        self.bIsInFiring = false
        self:CancelFiring()
        BattleShipWeaponProtoHelper.NotifyFiringOperationChanged(self:GetOwnerCharacter(), self:GetInstanceId(), nFiringOperation)
        BattleShipWeaponEventHelper.FireOnShipWeaponFiringOperationChangedEvent(self, nFiringOperation)
    end
    return true
end

function ShipWeaponItemBase:LoadBullet()
    local bResult, nFailedReason = self:IsReadyToLoadBullet()
    if not bResult then
        return bResult, nFailedReason
    end
    self:OnLoadBullet()
    return true
end

function ShipWeaponItemBase:GetBPComponent()
    error("derived class must to implement it.")
    return nil
end

-- 获取炮弹开火间隔总时间
function ShipWeaponItemBase:GetFiringInterval()
    --- Cheat test code begin
    if (not self:IsServerInstance()) and GlobalVariableSystem.bFixedShipWeaponParamEnabled then
        return GlobalVariableSystem.nFixedShipWeaponFiringInterval
    end
    --- Cheat test code end
    local PropertyComponent = self:GetOwnerCharacter().ShipBattlePropertyComponent
    local nFiringIntervalRatio = PropertyComponent:GetProp(PropName.nFiringIntervalRatio)
    local nFiringIntervalDelta = PropertyComponent:GetProp(PropName.nFiringIntervalDelta)
    return self:GetTemplate().nFiringInterval * nFiringIntervalRatio + nFiringIntervalDelta
end

-- 获取武器对应的模板类型
function ShipWeaponItemBase:GetTemplateType()
    error("derived class must to implement it.")
    return nil
end

function ShipWeaponItemBase:GetWeaponSlot()
    return ShipWeaponSlotDef.UNKNOWN
end

-- 获取投掷物Owner的UEActor
function ShipWeaponItemBase:GetOwnerShipUEActor()
    local OwnerCharacter = self:GetOwnerCharacter()
    if OwnerCharacter and OwnerCharacter:IsShip() then
        return OwnerCharacter.pUEActor
    end
    return nil
end

-- 获取炮弹开火间隔剩余时间
function ShipWeaponItemBase:GetRemainingFiringCD()
    local nRemainingFiringCD = self.nLastFiringTime + self.nLastFiringCD - GlobalVariableSystem:GetDSTimeSeconds()
    return MathUtil.Clamp(nRemainingFiringCD, 0, self.nLastFiringCD)
end

function ShipWeaponItemBase:SyncFiringOperation(nFiringOperation)
    LOG(self, "SyncFiringOperation", nFiringOperation)
    self.bIsInFiring = FIRING_STATE_WITH_OPERATION[nFiringOperation]
    if self:GetOwnerShipUEActor() then
        if nFiringOperation == ShipFiringOperationDef.START then
            self:OnStartFiring()
        elseif nFiringOperation == ShipFiringOperationDef.END then
            self:OnEndFiring()
        elseif nFiringOperation == ShipFiringOperationDef.CANCEL then
            self:OnCancelFiring()
        end
    end
    BattleShipWeaponEventHelper.FireOnShipWeaponFiringOperationChangedEvent(self, nFiringOperation)
end

function ShipWeaponItemBase:SyncFiringCD(nStartTime, nDuration)
    LOG(self, "SyncFiringCD", nStartTime, nDuration)
    self.nLastFiringTime = nStartTime
    self.nFiringInterval = nDuration
end

-- 设置替换开火视角的Actor
function ShipWeaponItemBase:SetReplacedViewerActor(pViewerActor)
    local pComponent = self:GetBPComponent()
    if not pComponent then
        logerror("SetReplacedViewerActor failed, can not get bp component.")
        return
    end
    pComponent:SetReplacedViewerActor(pViewerActor)
end

return ShipWeaponItemBase