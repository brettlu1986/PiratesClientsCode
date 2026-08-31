-----------------------------------------------------
--File Name    : BattleShipWeaponSystem.lua
--Author       : Song Fuhao
--Create Time  : 2020-07-22
--Description  : 新版舰船武器系统
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local BattleShipWeaponProtoHelper = require("BattleShipWeaponProtoHelper")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local ShipWeaponSubCategoryDef = require("ShipWeaponSubCategoryDef")
local PropName = require("PropName")
local SelfEventHelper = require("SelfEventHelper")
local TeamWatchServerHelper = require("TeamWatchServerHelper")
local EventManager = require("EventManager")
local ShipWeaponAttachmentTypeDef = require("ShipWeaponAttachmentTypeDef")
local BattleItemSourceDef = require("BattleItemSourceDef")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local DungeonIni = require("DungeonIni")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")

--- @class BattleShipWeaponSystem
local BattleShipWeaponSystem = luaclass("BattleShipWeaponSystem")

BattleShipWeaponSystem.EventHelper = nil
BattleShipWeaponSystem.tbFiringBulletInfoMap = nil
BattleShipWeaponSystem.tbDefaultWeaponConfig = nil

local WEAPON_ATTACK_ADDITION_NAME = {
    [ShipWeaponSubCategoryDef.SMALL_CANNON] = PropName.nSmallCannonDamageAddition,
    [ShipWeaponSubCategoryDef.SAKER]        = PropName.nSakersDamageAddition,
    [ShipWeaponSubCategoryDef.DARTLE]       = PropName.nDartleDamageAddition,
    [ShipWeaponSubCategoryDef.ASSAULT_GUN]  = PropName.nAssaultGunDamageAddition,
    [ShipWeaponSubCategoryDef.SNIPE_GUN]    = PropName.nSnipeGunDamageAddition,
    [ShipWeaponSubCategoryDef.STERN_CANNON] = PropName.nSternCannonDamageAddition
}

--- 不带Character输出日志
local function LOG(...)
    log("[BattleShipWeapon][System]", ...)
end

--- 带Character输出日志
local function LOG_WITH_NAME(tbCharacter, ...)
    LOG(tbCharacter and tbCharacter.szName, ...)
end

--- 获取舰船武器数据Component
local function GetComponent(tbCharacter)
    return tbCharacter and tbCharacter.BattleShipWeaponComponent
end

--- 获取一个有效的未装备的投掷物实例
local function GetValidUnequippedThrownItem(tbCharacter, nThrownItemTemplateId)
    if nThrownItemTemplateId then
        local nCharacterInstanceId = tbCharacter:GetServerInstanceId()
        local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
        local tbItems = BattleItemSystemServer:GetUnEquippedItemsByTemplateId(nCharacterInstanceId, nThrownItemTemplateId)
        for _, Item in ipairs(tbItems) do
            if Item:GetOwnerCharacter() and (not Item:IsInRemovingFromPlayer()) then
                return Item
            end
        end
    end
    return nil
end

local function RefillAllWeaponBullet(tbCharacter)
    LOG_WITH_NAME(tbCharacter, "TryToAutoLoadAllWeaponBullet")
    local nCharacterInstanceId = tbCharacter:GetServerInstanceId()
    local tbEquippedWeapons = BattleItemSystemHelper:GetEquippedItems(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, false)
    for _, WeaponItem in pairs(tbEquippedWeapons) do
        WeaponItem:RefillBullet()
    end
end

--- 所有该玩家武器尝试自动装弹
local function TryToAutoLoadAllWeaponBullet(tbCharacter)
    LOG_WITH_NAME(tbCharacter, "TryToAutoLoadAllWeaponBullet")
    local nCharacterInstanceId = tbCharacter:GetServerInstanceId()
    local tbEquippedWeapons = BattleItemSystemHelper:GetEquippedItems(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, false)
    for _, WeaponItem in pairs(tbEquippedWeapons) do
        WeaponItem:TryToAutoLoadBullet(true)
    end
end

--- 打断该玩家所有船武器装弹
local function InterruptAllWeaponBulletLoading(tbCharacter)
    LOG_WITH_NAME(tbCharacter, "InterruptAllWeaponBulletLoading")
    local nCharacterInstanceId = tbCharacter:GetServerInstanceId()
    local tbEquippedWeapons = BattleItemSystemHelper:GetEquippedItems(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, false)
    for _, WeaponItem in pairs(tbEquippedWeapons) do
        WeaponItem:InterruptBulletLoading()
    end
end

--- 打断当前玩家的开火行为
local function InterruptFiring(self, tbCharacter)
    LOG_WITH_NAME(tbCharacter, "InterruptFiring")
    self:Fire(tbCharacter, ShipFiringOperationDef.CANCEL)
end

--- 跳伞时重置当前激活武器为默认武器
local function OnEnterTransportStep(self)
    LOG("Enter transport step, reset ship weapon to default.")
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbObject, _ in pairs(tbObjects) do
        self:ActivateWeaponItem(tbObject)
        self:EquipThrownItem(tbObject)
    end
end

local function CheckActiveWeaponAmmoChange(self, tbCharacter, BulletItem)
    local Component = GetComponent(tbCharacter)
    if Component then
        local ActiveWeaponItem = Component:GetActiveWeaponItem()
        if ActiveWeaponItem then
            local nSlot = ActiveWeaponItem:GetWeaponSlot()
            TeamWatchServerHelper.SendShipAmmoInfoToViewers(tbCharacter, ActiveWeaponItem, true, false, nSlot)
        end
    end

end

-- 检查武器以及Owner是否有效
local function CheckWeaponAndOwner(tbCharacter, WeaponItem)
    if (not tbCharacter) or (not tbCharacter:IsAlive()) then
        return false
    end
    if WeaponItem then
        local WeaponOwner = WeaponItem:GetOwnerCharacter()
        if WeaponOwner ~= tbCharacter then
            return false
        end
        local nItemCategory = WeaponItem:GetCategory()
        return (nItemCategory == BattleItemCategoryDef.SHIP_THROWN_ITEM) or (nItemCategory == BattleItemCategoryDef.SHIP_WEAPON)
    end
    return true
end

--- 新获得一个物品时，如果是投掷物，且当前没有装备任何投掷物，装备它
local function OnBattleItemAdd(self, Item)
    local tbCharacter = Item:GetOwnerCharacter()
    if Item:GetCategory() == BattleItemCategoryDef.SHIP_THROWN_ITEM then
        local EquippedThrownItem = tbCharacter and GetComponent(tbCharacter):GetEquippedThrownItem()
        if not EquippedThrownItem then
            LOG_WITH_NAME(tbCharacter, "Get first thrown item.")
            self:EquipThrownItem(tbCharacter, Item:GetTemplateId())
        end
    elseif Item:GetCategory() == BattleItemCategoryDef.SHIP_WEAPON then
        Item:TryToAutoLoadBullet()
        local nActiveSlotCache = GetComponent(tbCharacter):PopActiveSlotChache()
        if nActiveSlotCache == Item:GetWeaponSlot() then
            LOG_WITH_NAME(tbCharacter, "Replace active weapon item.")
            self:ActivateWeaponItem(tbCharacter, Item)
        end
    elseif Item:GetCategory() == BattleItemCategoryDef.SHIP_BULLET then
       CheckActiveWeaponAmmoChange(self, tbCharacter, Item)
    end
end

--- 丢弃武器时，重新加上默认武器道具
local function OnAfterBattleItemUnequipped(self, nCharacterInstanceId, nItemTemplateId, nSlotIndex, bHasNewItemOnSlot)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if (not tbTemplate)
    or (tbTemplate.nCategory ~= BattleItemCategoryDef.SHIP_WEAPON)
    or bHasNewItemOnSlot then
        return
    end
    LOG("OnAfterBattleItemUnequipped", nCharacterInstanceId, nItemTemplateId, nSlotIndex, bHasNewItemOnSlot)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local nDefaultWeaponTemplateId = self.tbDefaultWeaponConfig[nSlotIndex]
    if not nDefaultWeaponTemplateId then
        return
    end
    BattleItemSystemServer:AddItemByTemplate(nCharacterInstanceId, nDefaultWeaponTemplateId, 1, BattleItemSourceDef.DEFAULT_WEAPON)
end

--- 换船后尝试自动装弹
local function OnPlayerShipChanged(self, tbCharacter)
    if tbCharacter:IsShip() then
        TryToAutoLoadAllWeaponBullet(tbCharacter)
    end
end

--- 人船切换时自动装弹/打断装弹
local function OnEndChangeDisplay(self, tbCharacter, bTemplateTypeChanged)
    if tbCharacter:IsShip() and bTemplateTypeChanged then
        RefillAllWeaponBullet(tbCharacter)
    else
        InterruptAllWeaponBulletLoading(tbCharacter)
    end
end

--- 离开重伤状态时自动装弹
local function OnPawnDyingChanged(self, tbCharacter, bIsDying)
    if not tbCharacter:IsShip() then
        return
    end
    if bIsDying then
        InterruptFiring(self, tbCharacter)
        InterruptAllWeaponBulletLoading(tbCharacter)
        self:ActivateWeaponItem(tbCharacter)
    else
        TryToAutoLoadAllWeaponBullet(tbCharacter)
    end
end

--- 死亡时打断装弹
local function OnPawnPreDead(self, tbCharacter)
    if not tbCharacter:IsShip() then
        return
    end
    InterruptFiring(self, tbCharacter)
    InterruptAllWeaponBulletLoading(tbCharacter)
    self:ActivateWeaponItem(tbCharacter)
end

--- 准镜倍数改变时强制关闭瞄准状态
local function OnShipTelescopeScaleChanged(self, tbCharacter)
    if not tbCharacter:IsShip() then
        return
    end
    self:ChangeAimState(tbCharacter, false)
end

--- TODO: Hao 统计这块目前还有问题
local function FireOnCharacterAttacked(self, nFiringId, tbInfo)
    if (not tbInfo.nBoomCount)
    or (not tbInfo.nFiredCount)
    or (tbInfo.nBoomCount ~= tbInfo.nFiredCount) then
        return
    end
    LOG("[LogFight] FireOnCharacterAttacked", nFiringId, tbInfo.nWeaponTemplateId, tbInfo.nTotalDamage)
    EventManager:OnFireEvent(CommonEventDef.EV_ON_CHARACTER_ATTACKED, tbInfo.tbCharacter, tbInfo.nWeaponTemplateId, tbInfo.nTotalDamage)
    self.tbFiringBulletInfoMap[nFiringId] = nil
end

--- 开火停止的时候，知道对应FiringId一共发射了多少炮弹
local function OnShipCannonFiringEnd(self, WeaponItem, nFiringId, nFiredCount)
    local OwnerCharacter = WeaponItem and WeaponItem:GetOwnerCharacter()
    if (not OwnerCharacter) or (OwnerCharacter:GetObjectType() ~= GameObjectTypeDef.PlayerSelf) then
        return
    end
    LOG("[LogFight] OnShipCannonFiringEnd", nFiringId, nFiredCount)
    local tbInfo = self.tbFiringBulletInfoMap[nFiringId] or {}
    self.tbFiringBulletInfoMap[nFiringId] = tbInfo

    tbInfo.tbCharacter = WeaponItem:GetOwnerCharacter()
    tbInfo.nWeaponTemplateId = WeaponItem:GetTemplateId()
    tbInfo.nFiredCount = nFiredCount
    FireOnCharacterAttacked(self, nFiringId, tbInfo)
end

--- 每一发炮弹爆炸的时候
local function OnShipCannonBulletBoom(self, nFiringId, nDamage)
    LOG("[LogFight] OnShipCannonBulletBoom", nFiringId, nDamage)
    local tbInfo = self.tbFiringBulletInfoMap[nFiringId] or {}
    self.tbFiringBulletInfoMap[nFiringId] = tbInfo

    local nTotalDamage = tbInfo.nTotalDamage or 0
    local nBoomCount = tbInfo.nBoomCount or 0
    tbInfo.nTotalDamage = nTotalDamage + nDamage
    tbInfo.nBoomCount = nBoomCount + 1
    FireOnCharacterAttacked(self, nFiringId, tbInfo)
end

--- 初始化默认武器配置
local function InitDefaultWeaponConfig(self)
    self.tbDefaultWeaponConfig = {}
    local tbTemplates = BattleItemDataTable:GetTemplatesByCategory(BattleItemCategoryDef.SHIP_WEAPON)
    for nTemplateId, tbTemplate in pairs(tbTemplates) do
        if tbTemplate.bDefaultWeapon then
            local nSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(tbTemplate.nSubCategory)
            self.tbDefaultWeaponConfig[nSlot] = nTemplateId
        end
    end
    LOG("InitDefaultWeaponConfig", t2s(self.tbDefaultWeaponConfig))
end

--- 初始化蓝图中全局变量
local function InitBPGlobalVariable(self)
    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    local pGlobalSettings = pGameInstance and pGameInstance.GlobalSettings
    if not pGlobalSettings then
        return
    end
    local tbShipWeapon = DungeonIni.tbShipWeapon
    pGlobalSettings.ShipThrownItemTeammateDamageEnabled = tbShipWeapon.bShipThrownItemTeammateDamageEnabled
    pGlobalSettings.TorpedoTriggerDebugEnabled = tbShipWeapon.bTorpedoTriggerDebugEnabled
    pGlobalSettings.TorpedoTriggerByTorpedo = tbShipWeapon.bTorpedoTriggerByTorpedo
    pGlobalSettings.TorpedoTriggerByGrenade = tbShipWeapon.bTorpedoTriggerByGrenade
    pGlobalSettings.TorpedoTriggerByCarronade = tbShipWeapon.bTorpedoTriggerByCarronade
    pGlobalSettings.TorpedoTriggerByShipShot = tbShipWeapon.bTorpedoTriggerByShipShot
    pGlobalSettings.TorpedoTriggerByHumanShot = tbShipWeapon.bTorpedoTriggerByHumanShot
end

local function InitEvent(self)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ENTER_TRANSPORT_STEP               , self, OnEnterTransportStep)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER             , self, OnBattleItemAdd)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_AFTER_BATTLE_ITEM_UNEQUIPED_SERVER , self, OnAfterBattleItemUnequipped)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_PLAYER_SHIP_CHANGED_SERVER      , self, OnPlayerShipChanged)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_END_CHANGEDISPLAY                  , self, OnEndChangeDisplay)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED  , self, OnPawnDyingChanged)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD       , self, OnPawnPreDead)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_TELESCOPE_SCALE_CHANGED    , self, OnShipTelescopeScaleChanged)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_CANNON_FIRING_END          , self, OnShipCannonFiringEnd)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_CANNON_BULLET_BOOM         , self, OnShipCannonBulletBoom)
end

function BattleShipWeaponSystem:Init()
    LOG("Init")
    self.EventHelper = SelfEventHelper()
    InitBPGlobalVariable(self)

    if GlobalVariableSystem:IsDedicatedClient() then
        return
    end
    self.tbFiringBulletInfoMap = {}
    InitDefaultWeaponConfig(self)
    InitEvent(self)
end

function BattleShipWeaponSystem:Uninit()
    LOG("Uninit")
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    self.tbFiringBulletInfoMap = nil
end

-------------------------------------------------------------------------------------------------
--- 舰船武器功能接口
-------------------------------------------------------------------------------------------------

--- 激活武器
--- @param tbCharacter GameCharacter Character对象实例
--- @param NewActiveWeaponItem number 新激活的武器实例
--- @param bCacheLastSlot boolean 是否缓存之前激活的槽位，默认不用传
--- @return boolean
function BattleShipWeaponSystem:ActivateWeaponItem(tbCharacter, NewActiveWeaponItem, bCacheLastSlot)
    LOG_WITH_NAME(tbCharacter, "ActivateWeaponItem", tbCharacter, NewActiveWeaponItem and NewActiveWeaponItem:GetInstanceId())
    if not CheckWeaponAndOwner(tbCharacter, NewActiveWeaponItem) then
        LOG_WITH_NAME(tbCharacter, "ActivateWeaponItem failed, character or weapon is not valid.")
        return
    end
    local WeaponComponent = GetComponent(tbCharacter)
    if not WeaponComponent:SetActiveWeaponItem(NewActiveWeaponItem, bCacheLastSlot) then
        return false
    end

    BattleShipWeaponProtoHelper.NotifyActiveWeaponItemChanged(tbCharacter, NewActiveWeaponItem)
    return true
end

--- 装备投掷物
--- @param tbCharacter GameCharacter Character对象实例
--- @param nThrownItemTemplateId number 投掷物TemplateId
--- @return boolean
function BattleShipWeaponSystem:EquipThrownItem(tbCharacter, nThrownItemTemplateId)
    LOG_WITH_NAME(tbCharacter, "EquipThrownItem nTemplateId =", nThrownItemTemplateId)
    if (not tbCharacter) or (not tbCharacter:IsAlive()) then
        LOG_WITH_NAME(tbCharacter, "EquipThrownItem failed, character is not alive.")
        return
    end
    local NewEquippedThrownItem = GetValidUnequippedThrownItem(tbCharacter, nThrownItemTemplateId)
    LOG_WITH_NAME(tbCharacter, "EquipThrownItem nInstanceId =", NewEquippedThrownItem and NewEquippedThrownItem:GetInstanceId())
    local WeaponComponent = GetComponent(tbCharacter)
    if not WeaponComponent:SetEquippedThrownItem(NewEquippedThrownItem) then
        return false
    end

    BattleShipWeaponProtoHelper.NotifyEquippedThrownItemChanged(tbCharacter, NewEquippedThrownItem)

    -- 如果装备投掷物时，之前的投掷物是当前激活武器，则激活新装备的投掷物
    local ActiveWeaponItem = WeaponComponent:GetActiveWeaponItem()
    if ActiveWeaponItem and (ActiveWeaponItem:GetCategory() == BattleItemCategoryDef.SHIP_THROWN_ITEM) then
        self:ActivateWeaponItem(tbCharacter, NewEquippedThrownItem)
    end
    return false
end

--- 开火
--- @param tbCharacter GameCharacter Character对象实例
--- @param nFiringOperation ShipFiringOperationDef 开火状态，不传时默认值为ShipFiringStateDef.START
--- @return boolean
function BattleShipWeaponSystem:Fire(tbCharacter, nFiringOperation)
    nFiringOperation = nFiringOperation or ShipFiringOperationDef.START
    LOG_WITH_NAME(tbCharacter, "Fire", nFiringOperation)
    if (not tbCharacter) then
        LOG_WITH_NAME(tbCharacter, "Fire failed, character is nil.")
        return
    end
    if (nFiringOperation == ShipFiringOperationDef.START) and (not tbCharacter:IsAlive()) then
        LOG_WITH_NAME(tbCharacter, "Fire failed, character is not alive.")
        return
    end
    local ActiveWeaponItem = self:GetActiveWeaponItem(tbCharacter)
    if not ActiveWeaponItem then
        return false
    end
    return ActiveWeaponItem:Fire(nFiringOperation)
end

--- 装弹
--- @param tbCharacter GameCharacter Character对象实例
--- @return boolean
function BattleShipWeaponSystem:LoadBullet(tbCharacter)
    LOG_WITH_NAME(tbCharacter, "LoadBullet")
    if (not tbCharacter) or (not tbCharacter:IsAlive()) then
        LOG_WITH_NAME(tbCharacter, "LoadBullet failed, character is not alive.")
        return
    end
    local ActiveWeaponItem = self:GetActiveWeaponItem(tbCharacter)
    if not ActiveWeaponItem then
        return false
    end
    return ActiveWeaponItem:LoadBullet()
end

--- 是否允许改变开镜状态
--- @param tbCharacter GameCharacter Character对象实例
--- @param bIsInAim boolean 是否开镜
--- @return boolean
function BattleShipWeaponSystem:IsReadyToChangeAimState(tbCharacter, bInAim)
    local Component = GetComponent(tbCharacter)
    if Component:GetIsInAim() == bInAim then
        LOG_WITH_NAME(tbCharacter, "ChangeAimState failed, reason : same with last aim state.")
        return false
    end
    if bInAim then
        local ActiveWeaponItem = self:GetActiveWeaponItem(tbCharacter)
        if not ActiveWeaponItem then
            LOG_WITH_NAME(tbCharacter, "ChangeAimState failed, reason : cannot find active weapon.")
            return false
        end
        local nCharacterInstanceId = tbCharacter:GetServerInstanceId()
        local nActiveWeaponInstanceId = ActiveWeaponItem:GetInstanceId()
        local tbSight = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT, nActiveWeaponInstanceId, ShipWeaponAttachmentTypeDef.SIGHT, GlobalVariableSystem:IsDedicatedClient())
        if not tbSight then
            LOG_WITH_NAME(tbCharacter, "ChangeAimState failed, reason : cannot find sight.")
            return false
        end
    end
    return true
end

--- 改变开镜状态
--- @param tbCharacter GameCharacter Character对象实例
--- @param bIsInAim boolean 是否开镜
--- @return boolean
function BattleShipWeaponSystem:ChangeAimState(tbCharacter, bInAim)
    LOG_WITH_NAME(tbCharacter, "ChangeAimState", bInAim)
    if (not tbCharacter) then
        LOG_WITH_NAME(tbCharacter, "ChangeAimState failed, character is nil.")
        return
    end
    if (bInAim == true) and (not tbCharacter:IsAlive()) then
        LOG_WITH_NAME(tbCharacter, "ChangeAimState failed, character is not alive.")
        return
    end
    if not self:IsReadyToChangeAimState(tbCharacter, bInAim) then
        return false
    end
    GetComponent(tbCharacter):SetIsInAim(bInAim)
    BattleShipWeaponProtoHelper.NotifyAimStateChanged(tbCharacter, bInAim)
    TeamWatchServerHelper.NotifyViewersAimState(tbCharacter, true, bInAim)
    return true
end

-------------------------------------------------------------------------------------------------
--- 基础数据Get接口
-------------------------------------------------------------------------------------------------

--- 获取武器加成后的攻击力
--- @param tbCharacter GameCharacter Character对象实例
--- @param nWeaponCategory ShipWeaponCategoryDef
--- @param nBaseDamage number
--- @return number
function BattleShipWeaponSystem:GetWeaponAttack(tbCharacter, nWeaponCategory, nBaseDamage)
    local nWeaponAttackAddition = WEAPON_ATTACK_ADDITION_NAME[nWeaponCategory]
    if nWeaponAttackAddition then
        local PropertyComponent = tbCharacter.ShipBattlePropertyComponent
        local nShipAttackAddValue = PropertyComponent:GetPropAddValue(PropName.nShipAttack)
        local nShipAttackMultiplyValue = PropertyComponent:GetPropMultiplyValue(PropName.nShipAttack)
        local nWeaponAttackAddValue = PropertyComponent:GetPropAddValue(nWeaponAttackAddition)
        local nWeaponAttackMultiplyValue = PropertyComponent:GetPropMultiplyValue(nWeaponAttackAddition)
        local nFinalDamage = nBaseDamage * (nShipAttackMultiplyValue + nWeaponAttackMultiplyValue - 1) + nShipAttackAddValue + nWeaponAttackAddValue
        return nFinalDamage
    end
    return nBaseDamage
end

--- 获取当前激活的武器实例
--- @param tbCharacter GameCharacter Character对象实例
--- @return ShipWeaponItemBase
function BattleShipWeaponSystem:GetActiveWeaponItem(tbCharacter)
    return GetComponent(tbCharacter):GetActiveWeaponItem()
end

--- 获取当前激活的武器实例
--- @param tbCharacter GameCharacter Character对象实例
--- @return ShipWeaponSlotDef
function BattleShipWeaponSystem:GetActiveWeaponSlot(tbCharacter)
    local ActiveWeaponItem = self:GetActiveWeaponItem(tbCharacter)
    return ActiveWeaponItem and ActiveWeaponItem:GetWeaponSlot() or ShipWeaponSlotDef.UNKNOWN
end

--- 获取当前装备的武器实例
--- @param tbCharacter GameCharacter Character对象实例
--- @param nWeaponSlot ShipWeaponSlotDef 武器槽位
--- @return ShipWeaponItemBase
function BattleShipWeaponSystem:GetEquippedWeaponItem(tbCharacter, nWeaponSlot)
    if nWeaponSlot == ShipWeaponSlotDef.THROW then
        return GetComponent(tbCharacter):GetEquippedThrownItem()
    else
        local nCharacterInstanceId = tbCharacter:GetServerInstanceId()
        return BattleItemSystemHelper:GetEquippedItem(
            nCharacterInstanceId,
            BattleItemCategoryDef.SHIP_WEAPON,
            nCharacterInstanceId,
            nWeaponSlot,
            GlobalVariableSystem:IsDedicatedClient()
        )
    end
end

--- 获取当前装备的武器实例
--- @param tbCharacter GameCharacter Character对象实例
--- @param nWeaponSlot ShipWeaponSlotDef 武器槽位
--- @return ShipWeaponItemBase
function BattleShipWeaponSystem:GetEquippedWeaponItem(tbCharacter, nWeaponSlot)
    if nWeaponSlot == ShipWeaponSlotDef.THROW then
        return GetComponent(tbCharacter):GetEquippedThrownItem()
    else
        local nCharacterInstanceId = tbCharacter:GetServerInstanceId()
        return BattleItemSystemHelper:GetEquippedItem(
            nCharacterInstanceId,
            BattleItemCategoryDef.SHIP_WEAPON,
            nCharacterInstanceId,
            nWeaponSlot,
            GlobalVariableSystem:IsDedicatedClient()
        )
    end
end

--- 获取当前装备是否处于开镜状态
--- @param tbCharacter GameCharacter Character对象实例
--- @return boolean
function BattleShipWeaponSystem:GetIsInAim(tbCharacter)
    return GetComponent(tbCharacter):GetIsInAim()
end

return BattleShipWeaponSystem()