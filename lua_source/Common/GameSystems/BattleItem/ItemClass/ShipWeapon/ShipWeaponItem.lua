-----------------------------------------------------
--File Name    : ShipWeaponItem.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-13
--Description  : 武器Item基类
-----------------------------------------------------
local luaclass = require("luaclass")
local ShipWeaponItemBase = require("ShipWeaponItemBase")
local Timer = require("Timer")
local PropName = require("PropName")
local TeamWatchServerHelper = require("TeamWatchServerHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleShipWeaponProtoHelper = require("BattleShipWeaponProtoHelper")
local BattleItemSourceDef = require("BattleItemSourceDef")
local ShipUtilityExHelper = require("ShipUtilityExHelper")
local BattleShipWeaponEventHelper = require("BattleShipWeaponEventHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local ShipDataTable = require("ShipDataTable")
local ShipItemHelper = require("ShipItemHelper")
local ShipWeaponFiringFailedDef = require("ShipWeaponFiringFailedDef")
local ShipBulletLoadingFailedDef = require("ShipBulletLoadingFailedDef")
local BattleItemSystemServer = require("BattleItemSystemServer")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local DungeonIni = require("DungeonIni")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

--- @class ShipWeaponItem : ShipWeaponItemBase
local ShipWeaponItem = luaclass("ShipWeaponItem", ShipWeaponItemBase)

local SHIP_WEAPON_LOADING_AFTER_BUILT = DungeonIni.tbShipWeapon.bShipWeaponLoadingAfterBuilt

ShipWeaponItem.bInRemoving = false
ShipWeaponItem.bInBulletLoading = false
ShipWeaponItem.tbBulletLoadingTimerHandle = nil
ShipWeaponItem.nBulletLoadingStartTime = 0
ShipWeaponItem.nBulletLoadingTime = 0
ShipWeaponItem.nBulletMaxFiringCount = 0
ShipWeaponItem.nBulletMaxLoadingCount = 0

local function LOG(self, ...)
    local OwnerCharacter = self:GetOwnerCharacter()
    local szOwnerName = OwnerCharacter and OwnerCharacter.szName
    log("[BattleShipWeapon][Item]", szOwnerName, self:GetInstanceId(), ...)
end

-- 通知观战的人炮弹数量变化
local function NotifyViewersWeaponAmmoChanged(self)
    TeamWatchServerHelper.SendShipAmmoInfoToViewers(self:GetOwnerCharacter(), self, true, false, self:GetWeaponSlot())
end

-- 获取当前玩家控制船的BPClass
local function GetOwnerShipClassPath(self)
    local nShipTemplateId = self:GetOwnerCharacter():GetShipTemplateId()
    log("[SHIP_TEMPLATE_DEBUG] character template id", nShipTemplateId)
    local nCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local tbShipItem = ShipItemHelper.GetCurrentShipItem(nCharacterInstanceId, not self:IsServerInstance())
    log("[SHIP_TEMPLATE_DEBUG] tbShipItem", tbShipItem, nCharacterInstanceId, self:IsServerInstance())
    if tbShipItem then
        nShipTemplateId = tbShipItem:GetTemplate().nShipId
        log("[SHIP_TEMPLATE_DEBUG] tbShipItem nShipTemplateId", nShipTemplateId)
    end
    local tbShipResTemplate = ShipDataTable:GetResTemplate(nShipTemplateId)
    return tbShipResTemplate.szPawnClassName
end

-- 获取炮弹装填时间
local function GetBulletLoadingTime(self)
    local PropertyComponent = self:GetOwnerCharacter().ShipBattlePropertyComponent
    local nReloadSpeedDelta = PropertyComponent:GetProp(PropName.nReloadSpeedDelta)
    local nReloadSpeedRatio = PropertyComponent:GetProp(PropName.nReloadSpeedRatio)
    return self:GetTemplate().nLoadingTime * nReloadSpeedRatio + nReloadSpeedDelta
end

-- 获取武器开火轮数
local function GetFiringRoundCount(self)
    local nFiringRoundCount = self:GetTemplate().nFiringRoundCount
    local nCategory = self:GetSubCategory()
    local PropertyComponent = self:GetOwnerCharacter().ShipBattlePropertyComponent
    if nCategory == ShipWeaponTemplateDef.POWDER_KEG then
        nFiringRoundCount = math.max(0, nFiringRoundCount + PropertyComponent:GetProp(PropName.nPowderKegFiringRoundCountDelta))
    elseif nCategory == ShipWeaponTemplateDef.CARRONADE then
        nFiringRoundCount = math.max(0, nFiringRoundCount + PropertyComponent:GetProp(PropName.nCarronadeFiringRoundCountDelta))
    end
    return nFiringRoundCount
end

------------------------------------------------------------------------------------
--- 炮弹逻辑
------------------------------------------------------------------------------------
-- 清理服务器炮弹装填Timer
local function ClearBulletLoadingTimer(self)
    if self.tbBulletLoadingTimerHandle then
        self.tbBulletLoadingTimerHandle:Clear()
        self.tbBulletLoadingTimerHandle = nil
    end
end

-- 通知炮弹装填开始
local function NotifyShipWeaponBulletLoadBegan(self)
    local tbCharacter = self:GetOwnerCharacter()
    if (not tbCharacter) or (tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf) then
        return
    end
    local nWeaponInstanceId = self:GetInstanceId()
    BattleShipWeaponProtoHelper.NotifyBulletLoadBegan(self, self.nBulletLoadingTime)

    local rShipWeaponBulletLoadingInfo = tbCharacter.ShipBattlePropertyComponent:GetProp(PropName.rShipWeaponBulletLoadingInfo)
    local tbBulletLoadingInfos = rShipWeaponBulletLoadingInfo.bullet_loading_infos or {}
    -- 删除已存在的装弹信息
    for i, v in pairs(tbBulletLoadingInfos) do
        if v.weapon_instance_id == nWeaponInstanceId then
            table.remove(tbBulletLoadingInfos, i)
            break
        end
    end
    -- 插入新的装弹信息
    local tbBulletLoadingInfo = {
        start_time = self.nBulletLoadingStartTime,
        loading_time = self.nBulletLoadingTime,
        weapon_instance_id = nWeaponInstanceId
    }
    table.insert(tbBulletLoadingInfos, tbBulletLoadingInfo)
    rShipWeaponBulletLoadingInfo.bullet_loading_infos = tbBulletLoadingInfos
    tbCharacter.ShipBattlePropertyComponent:SetPropOriginValue(PropName.rShipWeaponBulletLoadingInfo, rShipWeaponBulletLoadingInfo)
end

-- 通知炮弹装填结束
local function NotifyShipWeaponBulletLoadEnded(self)
    local tbCharacter = self:GetOwnerCharacter()
    if (not tbCharacter) or (tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf) then
        return
    end
    local nWeaponInstanceId = self:GetInstanceId()
    BattleShipWeaponProtoHelper.NotifyBulletLoadEnded(self)

    local rShipWeaponBulletLoadingInfo = tbCharacter.ShipBattlePropertyComponent:GetProp(PropName.rShipWeaponBulletLoadingInfo)
    local tbBulletLoadingInfos = rShipWeaponBulletLoadingInfo.bullet_loading_infos
    if tbBulletLoadingInfos then
        for i, v in pairs(tbBulletLoadingInfos) do
            if v.weapon_instance_id == nWeaponInstanceId then
                table.remove(tbBulletLoadingInfos, i)
                break
            end
        end
        tbCharacter.ShipBattlePropertyComponent:SetPropOriginValue(PropName.rShipWeaponBulletLoadingInfo, rShipWeaponBulletLoadingInfo)
    end
end

-- 处理开始装弹（客户端服务器均会执行）
local function HandleBulletLoadBegan(self, nBulletLoadingTime, nBulletLoadingStartTime)
    if self.bInBulletLoading then
        return
    end
    LOG(self, "HandleBulletLoadBegan", nBulletLoadingTime, nBulletLoadingStartTime)
    self.nBulletLoadingStartTime = nBulletLoadingStartTime
    self.nBulletLoadingTime = nBulletLoadingTime
    self.bInBulletLoading = true
    BattleShipWeaponEventHelper.FireOnShipWeaponBulletLoadBeganEvent(self, nBulletLoadingTime, nBulletLoadingStartTime)
end

-- 处理结束装弹（客户端服务器均会执行）
local function HandleBulletLoadEnded(self)
    if not self.bInBulletLoading then
        return
    end
    LOG(self, "HandleBulletLoadEnd")
    self.nBulletLoadingStartTime = 0
    self.nBulletLoadingTime = 0
    self.bInBulletLoading = false
    BattleShipWeaponEventHelper.FireOnShipWeaponBulletLoadEndedEvent(self)
end

-- 结束炮弹装载(装备卸载、取消激活时强制打断)
local function EndBulletLoading(self, bInterrupted)
    if not self.bInBulletLoading then
        return
    end
    LOG(self, "EndBulletLoading")
    ClearBulletLoadingTimer(self)
    HandleBulletLoadEnded(self)
    NotifyShipWeaponBulletLoadEnded(self)

    if not bInterrupted then
        local bAutoLoading = self:GetTemplate().bAutoLoading
        local nCount = bAutoLoading and self.nBulletMaxFiringCount or self.nBulletMaxLoadingCount
        if not self:IsInfiniteBullet() then
            nCount = math.min(nCount, self:GetBulletUnloadedCount())
        end

        local nCharacterInstanceId = self:GetOwnerCharacterInstanceId()
        local nOwnerInstanceId = self:GetInstanceId()
        local nBulletTemplateId = self:GetBulletItemTemplateId()
        BattleItemSystemServer:EquipStackableItem(nCharacterInstanceId, nOwnerInstanceId, nBulletTemplateId, nCount, self:IsInfiniteBullet())
        NotifyViewersWeaponAmmoChanged(self)

        self:TryToAutoLoadBullet()
    end
end

-- 开始炮弹装载
local function BeginBulletLoading(self)
    if self.bInBulletLoading then
        return
    end
    LOG(self, "BeginBulletLoading")
    local nBulletLoadingTime = GetBulletLoadingTime(self)
    local nBulletLoadingStartTime = GlobalVariableSystem:GetDSTimeSeconds()
    HandleBulletLoadBegan(self, nBulletLoadingTime, nBulletLoadingStartTime)
    NotifyShipWeaponBulletLoadBegan(self)

    if nBulletLoadingTime > 0 then
        self.tbBulletLoadingTimerHandle = Timer.NewTimerMethod(self, EndBulletLoading, nBulletLoadingTime)
    else
        EndBulletLoading(self)
    end
end

-- 扣除炮弹
local function DecreaseBulletCount(self, nCount)
    if self:GetBulletItemTemplateId() <= 0 then
        return
    end
    LOG(self, "DecreaseBulletCount", nCount)
    local nCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local nOwnerInstanceId = self:GetInstanceId()
    local BulletItem = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_BULLET, nOwnerInstanceId)
    BattleItemSystemServer:DecreasePlayerItemCount(nCharacterInstanceId, BulletItem:GetInstanceId(), nCount)
    NotifyViewersWeaponAmmoChanged(self)
end

-- 检查武器内炮弹是否为空
local function IsWeaponEmpty(self)
    if self:GetBulletItemTemplateId() > 0 then
        return self:GetBulletLoadedCount() <= 0
    end
    return false
end

-- 设置武器模型显隐
local function SetWeaponMeshVisible(self, bVisible)
    local ShipAvatarComponent = self:GetOwnerCharacter().ShipAvatarComponent
    if ShipAvatarComponent then
        local nWeaponSlot = self:GetWeaponSlot()
        local nTemplateId = bVisible and self:GetTemplateId() or -1
        ShipAvatarComponent:SetWeaponResData(nWeaponSlot, nTemplateId)
    end
end

-- 上一个开火人不是自己，尝试重置武器开火间隔CD
local function TryToClearFiringCD(self)
    if self.nLastFiringCharacterInstanceId ~= self:GetOwnerCharacterInstanceId() then
        self.nLastFiringTime = 0
        self.nLastFiringCharacterInstanceId = 0
    end
end

-- 获取可装填的弹药数量上限
local function CacheBulletMaxLoadingCount(self)
    local nBulletTemplateId = self:GetBulletItemTemplateId()
    if nBulletTemplateId > 0 then
        local tbTemplate = self:GetTemplate()
        local szShipClassPath = GetOwnerShipClassPath(self)
        local szControlClass = ShipWeaponTemplateDef.GetBPControlClassPath(self:GetTemplateType())
        local nWeaponSlot = self:GetWeaponSlot()
        local tbValidWeaponSlotLevel = tbTemplate.tbValidWeaponSlotLevel
        local nFiringRoundCount = GetFiringRoundCount(self)
        self.nBulletMaxLoadingCount = ShipUtilityExHelper.GetBulletMaxLoadingCount(szShipClassPath, szControlClass, nWeaponSlot, tbValidWeaponSlotLevel) * nFiringRoundCount
    else
        self.nBulletMaxLoadingCount = 0
    end
    -- LOG(self, "CacheBulletMaxLoadingCount", self.nBulletMaxLoadingCount)
end

-- 获取炮弹最大发射数量
local function CacheBulletMaxFiringCount(self)
    local nBulletTemplateId = self:GetBulletItemTemplateId()
    if nBulletTemplateId > 0 then
        local tbTemplate = self:GetTemplate()
        local szShipClassPath = GetOwnerShipClassPath(self)
        local szControlClass = ShipWeaponTemplateDef.GetBPControlClassPath(self:GetTemplateType())
        local nWeaponSlot = self:GetWeaponSlot()
        local tbValidWeaponSlotLevel = tbTemplate.tbValidWeaponSlotLevel
        local nFiringType = tbTemplate.nFiringType
        self.nBulletMaxFiringCount = ShipUtilityExHelper.GetBulletMaxFiringCount(szShipClassPath, szControlClass, nWeaponSlot, tbValidWeaponSlotLevel, nFiringType)
    else
        self.nBulletMaxFiringCount = 0
    end
    -- LOG(self, "CacheBulletMaxFiringCount", self.nBulletMaxFiringCount)
end

local function OnEquip(self)
    CacheBulletMaxLoadingCount(self)
    CacheBulletMaxFiringCount(self)
    BattleShipWeaponEventHelper.FireOnShipWeaponEquippedEvent(self)
end

local function OnUnequip(self)
    BattleShipWeaponEventHelper.FireOnShipWeaponUnequippedEvent(self)
end

------------------------------------------------------------------------------------
--- BattleItem interface
------------------------------------------------------------------------------------
function ShipWeaponItem:OnDestroy(...)
    ClearBulletLoadingTimer(self)
    ShipWeaponItem.super.OnDestroy(self, ...)
end

-- 获得的时候自动装弹
function ShipWeaponItem:AfterAddedToCharacterOnServer(nBattleItemSource, bSyncToClient)
    local nBulletItemTemplateId = self:GetBulletItemTemplateId()
    if self:IsInitialItem() and nBulletItemTemplateId > 0 and self.nBulletMaxLoadingCount > 0 then
        if SHIP_WEAPON_LOADING_AFTER_BUILT and (nBattleItemSource == BattleItemSourceDef.BUILD) then
            self:LoadBullet()
        else
            BattleItemSystemServer:CreateAndEquipItemWithOwner(self:GetOwnerCharacterInstanceId(), self:GetInstanceId(), self:GetBulletItemTemplateId(), self:GetBulletMaxLoadingCount(), BattleItemSourceDef.WEAPON_INIT_BULLETS, bSyncToClient)
        end
    end
end

function ShipWeaponItem:PreRemoveFromPlayer(bRemoveAll)
    if self:IsServerInstance() and (not bRemoveAll) then
        local tbCharacter = self:GetOwnerCharacter()
        local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbCharacter)
        if ActiveWeaponItem == self then
            self.bInRemoving = true
            BattleShipWeaponSystem:ActivateWeaponItem(tbCharacter, nil, true)
            self.bInRemoving = false
        end
    end
end

function ShipWeaponItem:OnEquipOnServer()
    TryToClearFiringCD(self)
    SetWeaponMeshVisible(self, true)
    OnEquip(self)
    -- self:TryToAutoLoadBullet()
end

function ShipWeaponItem:OnUnequipOnServer()
    SetWeaponMeshVisible(self, false)
    OnUnequip(self)
    -- 打断装填，需要再OnUnequip之后执行
    self:InterruptBulletLoading()
end

function ShipWeaponItem:OnEquipOnClient()
    OnEquip(self)
end

function ShipWeaponItem:OnUnequipOnClient()
    OnUnequip(self)
end

------------------------------------------------------------------------------------
--- ShipWeaponItemBase interface
------------------------------------------------------------------------------------
function ShipWeaponItem:ActivateWeapon()
    ShipWeaponItem.super.ActivateWeapon(self)
    local OwnerCharacter = self:GetOwnerCharacter()
    local ShipWeaponAttachmentComponent = OwnerCharacter and OwnerCharacter.ShipWeaponAttachmentComponent
    if ShipWeaponAttachmentComponent then
        if self:IsServerInstance() then
            ShipWeaponAttachmentComponent:OnShipWeaponActiveServer(self)
        else
            ShipWeaponAttachmentComponent:OnShipWeaponActiveClient(self)
        end
    end
end

function ShipWeaponItem:DeactivateWeapon(bDestroy)
    local OwnerCharacter = self:GetOwnerCharacter()
    local ShipWeaponAttachmentComponent = OwnerCharacter and OwnerCharacter.ShipWeaponAttachmentComponent
    if ShipWeaponAttachmentComponent then
        if self:IsServerInstance() then
            ShipWeaponAttachmentComponent:OnShipWeaponDeActiveServer(self)
        else
            ShipWeaponAttachmentComponent:OnShipWeaponDeActiveClient(self)
        end
    end
    ShipWeaponItem.super.DeactivateWeapon(self, bDestroy)

    -- 武器不在激活状态时自动装弹（需要在反激活逻辑最后调用，确保重置了开火状态）
    if self:IsServerInstance() and (not self.bInRemoving) and (not bDestroy) then
        self:TryToAutoLoadBullet(true)
    end
end

function ShipWeaponItem:StartFiring()
    self:InterruptBulletLoading()
    local nFiringCount = math.min(self:GetBulletLoadedCount(), self.nBulletMaxFiringCount)
    DecreaseBulletCount(self, nFiringCount)
    self:OnStartFiring(nFiringCount)
    BattleShipWeaponEventHelper.FireOnShipWeaponFiredEvent(self, nFiringCount)
end

function ShipWeaponItem:EndFiring()
    self:OnEndFiring()
    self:TryToAutoLoadBullet()
    BattleShipWeaponEventHelper.FireOnShipWeaponFiringSuccessEvent(self)
end

function ShipWeaponItem:CancelFiring()
    self:StartFiringCD()
    self:OnCancelFiring()
end

-- 检查开火前置条件
function ShipWeaponItem:IsReadyToFire(nFiringOperation)
    local bResult, nFailedReason = ShipWeaponItem.super.IsReadyToFire(self, nFiringOperation)
    if not bResult then
        return bResult, nFailedReason
    end
    if nFiringOperation == ShipFiringOperationDef.START then
        if IsWeaponEmpty(self) then
            return false, ShipWeaponFiringFailedDef.BULLET_EMPTY
        end
        if self:GetOwnerCharacter():IsDying() then
            return false, ShipWeaponFiringFailedDef.PLAYER_IN_DYING
        end
    end
    return true
end

-- 检查装弹前置条件
function ShipWeaponItem:IsReadyToLoadBullet()
    if self.bInBulletLoading then
        return false, ShipBulletLoadingFailedDef.BULLET_LOADING
    end
    if self:IsInFiring() then
        return false, ShipBulletLoadingFailedDef.IN_FIRING
    end
    local nLoadedCount = self:GetBulletLoadedCount()
    if nLoadedCount >= self.nBulletMaxLoadingCount then
        return false, ShipBulletLoadingFailedDef.CONTAINER_FULL
    end
    if not self:IsInfiniteBullet() then
        local nUnloadedCount = self:GetBulletUnloadedCount()
        if nUnloadedCount <= 0 then
            return false, ShipBulletLoadingFailedDef.BULLET_EMPTY
        end
    end
    if self:GetOwnerCharacter():IsDying() then
        return false, ShipBulletLoadingFailedDef.PLAYER_IN_DYING
    end
    return true
end

------------------------------------------------------------------------------------
--- other public interface
------------------------------------------------------------------------------------

-- 获取该武器所装备的槽位
function ShipWeaponItem:GetWeaponSlot()
    local tbStorageLocation = self:GetStorageLocation()
    return tbStorageLocation and tbStorageLocation.nSlotIndex
end

-- 是否允许连续开火
function ShipWeaponItem:GetIsAllowRepeatFiring()
    return self:GetTemplate().bAllowRepeatFiring
end


-- 获取可装填的弹药类型，返回-1表示不能装弹药
function ShipWeaponItem:GetBulletItemTemplateId()
    return self:GetTemplate().nBulletItemTemplateId
end

-- 获取已安装炮弹数量
function ShipWeaponItem:GetBulletLoadedCount()
    local nBulletTemplateId = self:GetBulletItemTemplateId()
    if nBulletTemplateId > 0 then
        local nCharacterInstanceId = self:GetOwnerCharacterInstanceId()
        local nOwnerInstanceId = self:GetInstanceId()
        return BattleItemSystemHelper:GetEquippedItemCount(nCharacterInstanceId, nOwnerInstanceId, nBulletTemplateId, not self:IsServerInstance())
    else
        return 0
    end
end

-- 获取未安装炮弹数量
function ShipWeaponItem:GetBulletUnloadedCount()
    local nBulletTemplateId = self:GetBulletItemTemplateId()
    if nBulletTemplateId > 0 then
        local nCharacterInstanceId = self:GetOwnerCharacterInstanceId()
        return BattleItemSystemHelper:GetUnequippedItemCount(nCharacterInstanceId, nBulletTemplateId, not self:IsServerInstance())
    else
        return 0
    end
end

-- 获取可装填的弹药数量上限
function ShipWeaponItem:GetBulletMaxLoadingCount(bForceUpdate)
    if bForceUpdate then
        CacheBulletMaxLoadingCount(self)
    end
    return self.nBulletMaxLoadingCount
end

-- 获取炮弹最大发射数量
function ShipWeaponItem:GetBulletMaxFiringCount(bForceUpdate)
    if bForceUpdate then
        CacheBulletMaxFiringCount(self)
    end
    return self.nBulletMaxFiringCount
end

-- 是否在手动装弹中
-- 检查是否正在手动装弹
function ShipWeaponItem:IsInManualBulletLoading()
    return self.bInBulletLoading and (not self:GetTemplate().bAutoLoading)
end

-- 尝试自动装弹，目前有以下几个时机会
-- * 武器取消激活时
-- * 武器装备时
-- * 换船时
-- * 武器开火结束时
-- * 炮弹装填结束
function ShipWeaponItem:TryToAutoLoadBullet(bAllowNonEmpty)
    -- 非服务器不装弹
    if not self:IsServerInstance() then
        LOG(self, "TryToAutoLoadBullet failed, not server logic.")
        return
    end
    -- 初始物品不装弹
    if self:IsInitialItem() then
        -- LOG(self, "TryToAutoLoadBullet failed, it is initial item.")
        return
    end
    -- 武器没有Owner不装弹
    local OwnerCharacter = self:GetOwnerCharacter()
    if not OwnerCharacter then
        LOG(self, "TryToAutoLoadBullet failed, no owner.")
        return
    end
    -- 传值为true时或者是自动装弹武器时允许非空弹匣装弹
    bAllowNonEmpty = bAllowNonEmpty or self:GetTemplate().bAutoLoading
    -- 不是空弹匣不装弹
    if (not bAllowNonEmpty) and (not IsWeaponEmpty(self)) then
        LOG(self, "TryToAutoLoadBullet failed, bullet is not empty.")
        return
    end
    -- 换船期间不允许装弹
    if BattleItemSystemServer:IsChangingShip(self:GetOwnerCharacterInstanceId()) then
        LOG(self, "TryToAutoLoadBullet failed, in changing ship.")
        return
    end
    local bReadyToLoadBullet, nFailedReason = self:LoadBullet()
    if not bReadyToLoadBullet then
        LOG(self, "TryToAutoLoadBullet failed, nFailedReason =", nFailedReason)
        return
    end
end

-- 请求装弹
function ShipWeaponItem:OnLoadBullet()
    BeginBulletLoading(self)
end

-- 打断炮弹装填
function ShipWeaponItem:InterruptBulletLoading()
    EndBulletLoading(self, true)
end

-- 判断武器是否为无限弹药模式
function ShipWeaponItem:IsInfiniteBullet()
    return self:GetTemplate().bInfiniteBullet or BattleItemSystemHelper:IsShipBulletInfinite()
end

-- 同步炮弹装填状态
function ShipWeaponItem:SyncBulletLoadingInfo(nBulletLoadingTime, nBulletLoadingStartTime)
    LOG(self, "SyncBulletLoadingInfo", nBulletLoadingTime, nBulletLoadingStartTime)
    if self.bInBulletLoading and (nBulletLoadingTime <= 0) then
        HandleBulletLoadEnded(self)
    elseif nBulletLoadingTime > 0 then
        --- Cheat test code begin
        if (not self:IsServerInstance()) and GlobalVariableSystem.bFixedShipWeaponParamEnabled then
            nBulletLoadingTime = GlobalVariableSystem.nFixedShipWeaponLoadingInterval
        end
        --- Cheat test code end
        HandleBulletLoadBegan(self, nBulletLoadingTime, nBulletLoadingStartTime)
    end
end

-- 获取子弹装填总时长（秒）
function ShipWeaponItem:GetBulletLoadingTime()
    return self.nBulletLoadingTime
end

-- 获取子弹装填开始时间（秒）
function ShipWeaponItem:GetBulletLoadingStartTime()
    return self.nBulletLoadingStartTime
end

-- 获取炮弹装填剩余时间（秒）
function ShipWeaponItem:GetRemainingBulletLoadingTime()
    if self:IsServerInstance() then
        return self.tbBulletLoadingTimerHandle and self.tbBulletLoadingTimerHandle:GetRemainingTime() or 0
    end
    return GlobalVariableSystem:GetDSTimeSeconds() > (self.nBulletLoadingStartTime + self.nBulletLoadingTime)
end

-- 检查是否正在装弹
function ShipWeaponItem:IsInBulletLoading()
    return self.bInBulletLoading
end

function ShipWeaponItem:RefillBullet()
    local nMaxCount = self:GetBulletLoadedCount()
    if nMaxCount > 0 then
        DecreaseBulletCount(self, nMaxCount)
    end
    BattleItemSystemServer:CreateAndEquipItemWithOwner(self:GetOwnerCharacterInstanceId(), self:GetInstanceId(), self:GetBulletItemTemplateId(), self:GetBulletMaxLoadingCount(), BattleItemSourceDef.WEAPON_INIT_BULLETS, true)
end

return ShipWeaponItem