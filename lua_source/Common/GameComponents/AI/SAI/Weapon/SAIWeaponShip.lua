local luaclass = require("luaclass")
local SAIWeaponBase = require("SAIWeaponBase")
local SAIWeaponShip = luaclass("SAIWeaponShip", SAIWeaponBase)
local CommonEventDef = require("CommonEventDef")
local ShipWeaponTemplateDef     = require("ShipWeaponTemplateDef")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local ShipWeaponSlotDef         = require("ShipWeaponSlotDef")
local BattleItemSystemServer    = require("BattleItemSystemServer")
local AIUtilityHelper           = require("AIUtilityHelper")
local CarronadeEffectDef        = require("CarronadeEffectDef")
local SAIWeaponCategory         = require("SAIWeaponCategory")
local ShipFiringOperationDef    = require("ShipFiringOperationDef")
local BattleShipWeaponSystem    = dynamic_require("BattleShipWeaponSystem")

local function LOG(...)
    log("CJ->SAIWeaponShip:", ...)
end

SAIWeaponShip.AttackCDTimer = nil
SAIWeaponShip.nAttackCD = 0
SAIWeaponShip.nActivedWeaponSlot = 0
SAIWeaponShip.nAttackRange = 0

local nM2CM = 100

local function GetWeaponDistance(tbWeaponConfig)
    return tbWeaponConfig.nBestDistance and tbWeaponConfig.nBestDistance * nM2CM or
    tbWeaponConfig.nMaxDistance * nM2CM
end

function SAIWeaponShip:ActiveWeapon(tbWeaponItem)
    local nWeaponSlot = tbWeaponItem:GetWeaponSlot()
    local tbWeaponConfig = self:GetWeaponConfig(tbWeaponItem:GetTemplateId())
    self.nActivedWeaponSlot = nWeaponSlot
    self.nAttackCD = tbWeaponConfig.nAttackIntervalSeconds
    local nWeaponCategory = SAIWeaponCategory.Cannon
    local nShipWeaponTemplateType = tbWeaponItem:GetTemplateType()
    if nShipWeaponTemplateType == ShipWeaponTemplateDef.EMBOLON or
    nShipWeaponTemplateType == ShipWeaponTemplateDef.FLAMER then
        nWeaponCategory = SAIWeaponCategory.Melee
    end
    self.nAttackRange = GetWeaponDistance(tbWeaponConfig)
    self.pAIWeaponComponent:SetWeaponParams(self.nActivedWeaponSlot, nWeaponCategory, self.nAttackRange, 0)
    self:ClearAttackCDTimer()
end


function SAIWeaponShip:DeactiveWeapon()
    self.nActivedWeaponSlot = 0
    self.nAttackRange = 0
    self.pAIWeaponComponent:SetWeaponParams(self.nActivedWeaponSlot, 0, self.nAttackRange, 0)
end


function SAIWeaponShip:RegisterEvent(SelfEventHelper)
    SAIWeaponShip.super.RegisterEvent(self, SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_EQUIPPED_SERVER , self, self.OnWeaponEquipped)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_UNEQUIPPED_SERVER   , self, self.OnWeaponUnEquipped)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_ACTIVE_WEAPON_ITEM_CHANGED    , self, self.OnWeaponActived)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_BEGAN_SERVER,   self, self.OnBulletStartLoad)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_ENDED_SERVER,   self, self.OnBulletEndLoad)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_FIRED_SERVER,   self, self.OnShipFired)
end

function SAIWeaponShip:OnConfiged()
    local tbConfig = self.tbConfig
    self.nSwitchWeaponCD = tbConfig.ShipSwitchWeaponCD or 3
    LOG("nSwitchWeaponCD ", self.nSwitchWeaponCD)
end

function SAIWeaponShip:OnStart()
    local tbOwner = self.Owner
    local tbActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbOwner)
    if tbActiveWeaponItem then
        self:OnWeaponActived(tbOwner, tbActiveWeaponItem)
    else
        self:DeactiveWeapon()
    end
    self.bCanAttack = self:CheckIfCanAttack()
end

function SAIWeaponShip:ClearAttackCDTimer()
    if self.AttackCDTimer then
        self.AttackCDTimer:Clear()
        self.AttackCDTimer = nil
        self.pAIWeaponComponent.bFireCD = false
    end
end

function SAIWeaponShip:CheckIfCanAttack()
    local tbOwner = self.Owner
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbWeapon = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.SHIP_WEAPON,
        tbOwner:GetServerInstanceId(), i)
        if tbWeapon and self:CanUseWeapon(tbWeapon:GetTemplateId()) then
           return true
        end
    end
end

function SAIWeaponShip:PickOutWeapon()
    if self.nActivedWeaponSlot > 0 then
        return
    end
    local tbOwner = self.Owner
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbWeapon = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.SHIP_WEAPON,
        tbOwner:GetServerInstanceId(), i)
        if tbWeapon and self:CanUseWeapon(tbWeapon:GetTemplateId()) then
            BattleShipWeaponSystem:ActivateWeaponItem(tbOwner, tbWeapon)
            return
        end
    end
end

function SAIWeaponShip:DropInWeapon()
    local tbOwner = self.Owner
    BattleShipWeaponSystem:ActivateWeaponItem(tbOwner)
end

function SAIWeaponShip:OnWeaponEquipped(OwnerCharacter, nWeaponSlot, tbWeaponItem)
    if OwnerCharacter and OwnerCharacter.nServerInstanceId == self.Owner.nServerInstanceId then
        self.bCanAttack = self:CheckIfCanAttack()
    end
end

function SAIWeaponShip:OnWeaponUnEquipped(OwnerCharacter, nWeaponSlot, tbWeaponItem)
    if OwnerCharacter and OwnerCharacter.nServerInstanceId == self.Owner.nServerInstanceId then
        LOG("bot unequiped weapon ", self.Owner.szName, nWeaponSlot, self.nActivedWeaponSlot)
        if nWeaponSlot == self.nActivedWeaponSlot and self.nActivedWeaponSlot > 0 then
            self:DeactiveWeapon()
        end
        self.bCanAttack = self:CheckIfCanAttack()
    end
end


function SAIWeaponShip:OnWeaponActived(OwnerCharacter, tbWeaponItem)
    if OwnerCharacter.nServerInstanceId == self.Owner.nServerInstanceId then
        if tbWeaponItem and self:CanUseWeapon(tbWeaponItem:GetTemplateId()) then
            LOG("bot weapon actived", self.Owner.szName, tbWeaponItem:GetTemplateId())
            self:ActiveWeapon(tbWeaponItem)
        else
            self:DeactiveWeapon()
        end
    end
end


function SAIWeaponShip:OnBulletStartLoad(tbCharacter, tbWeaponItem, nLoadingTime)
    if tbWeaponItem and tbCharacter == self.Owner then
        self.pAIWeaponComponent.bWeaponReloading = true
    end
end

function SAIWeaponShip:OnShipFired(tbCharacter)
    if self.Owner == tbCharacter then
        local nAttackCD = self.nAttackCD
        local pAIWeaponComponent = self.pAIWeaponComponent
        self:ClearAttackCDTimer()
        if nAttackCD > 0 then
            pAIWeaponComponent.bFireCD = true
            self.AttackCDTimer = self.TimerHelper:NewDelayRunTimer(function ()
                pAIWeaponComponent.bFireCD = false
                self.AttackCDTimer = nil
            end, nAttackCD)
        end
    end
end

function SAIWeaponShip:OnBulletEndLoad(tbCharacter, tbWeaponItem)
    if tbWeaponItem and tbCharacter == self.Owner then
        self.pAIWeaponComponent.bWeaponReloading = false
    end
end


function SAIWeaponShip:OnStartFire(X, Y, Z)
    assert(self.Owner and self.Owner.pUEActor)
    local tbOwner = self.Owner
    local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbOwner)
    if ActiveWeaponItem and tbOwner:IsAlive() then
        --LOG("fired", tbOwner.szName)
        local nWeaponType = ActiveWeaponItem:GetTemplateType()
        if ShipWeaponTemplateDef.CANNON == nWeaponType then
            ActiveWeaponItem:SetTargetLocation(X, Y, Z)
        elseif ShipWeaponTemplateDef.CARRONADE == nWeaponType then
            ActiveWeaponItem:SetEffectType(CarronadeEffectDef.BOOM)
            ActiveWeaponItem:SetTargetLocation(X, Y, Z)
        elseif ShipWeaponTemplateDef.POWDER_KEG == nWeaponType then
            local nYaw = AIUtilityHelper.GetYawToTarget(tbOwner.pUEActor, X, Y, Z, GWorld)
            ActiveWeaponItem:SetTargetYaw(nYaw)
        end
        BattleShipWeaponSystem:Fire(tbOwner, ShipFiringOperationDef.START)
    end
end

function SAIWeaponShip:OnEndFire()
    assert(self.Owner and self.Owner.pUEActor)
    BattleShipWeaponSystem:Fire(self.Owner, ShipFiringOperationDef.END)
end

function SAIWeaponShip:ChangeWeapon(nWeaponSlot)
    local tbOwner = self.Owner
    local tbWeapon = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.SHIP_WEAPON,
    tbOwner:GetServerInstanceId(), nWeaponSlot)
    local tbOldWeapon = BattleShipWeaponSystem:GetActiveWeaponItem(tbOwner)
    if tbOldWeapon ~= tbWeapon then
        BattleShipWeaponSystem:ActivateWeaponItem(tbOwner, tbWeapon)
    else
        self:OnWeaponActived(tbOwner, tbWeapon)
    end
    SAIWeaponShip.super.ChangeWeapon(self, nWeaponSlot)
end

function SAIWeaponShip:OnStop()
    self:ClearAttackCDTimer()
end

return SAIWeaponShip