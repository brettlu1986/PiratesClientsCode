
local luaclass = require("luaclass")
local SAIWeaponBase = require("SAIWeaponBase")
local SAIWeaponHuman = luaclass("SAIWeaponHuman", SAIWeaponBase)
local CommonEventDef = require("CommonEventDef")
local BattleItemSystemServer    = require("BattleItemSystemServer")
local AIUtilityHelper           = require("AIUtilityHelper")
local HumanWeaponDef            = require("HumanWeaponDef")
local BattleHumanWeaponSystemNew    = dynamic_require("BattleHumanWeaponSystemNew")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local HumanWeaponSlotDef        = require("HumanWeaponSlotDef")
local HumanWeaponMisc           = require("HumanWeaponMisc")
local HumanWeaponType = HumanWeaponMisc.Type
local SAIWeaponCategory         = require("SAIWeaponCategory")

local tbKeyOfHumanBody = {
    "Uparm_l",
    "Uparm_r",
    "Forearm_l",
    "Forearm_r",
    "Head",
    "Body",
    "Thigh_r",
    "Thigh_l",
    "Calf_l",
    "Calf_r",
}


local function LOG(...)
    log("CJ->SAIWeaponHuman:", ...)
end


SAIWeaponHuman.AttackCDTimer = nil
SAIWeaponHuman.nAttackCD = 0
SAIWeaponHuman.nActivedWeaponSlot = 0
SAIWeaponHuman.nAttackRange = 0
SAIWeaponHuman.bAllowEmptyHandAttack = true


local nM2CM = 100
local nMeleeHitAngle = 120
local nEmptyHandAttackRange = 150
local nEmptyHandAttackCD = 1

local function GetWeaponDistance(tbWeaponConfig)
    return tbWeaponConfig.nBestDistance and tbWeaponConfig.nBestDistance * nM2CM or
    tbWeaponConfig.nMaxDistance * nM2CM
end

local function EnableEmptyHandAttack(self)
    if self.bAllowEmptyHandAttack then
        local pAIWeaponComponent = self.pAIWeaponComponent
        self.nAttackRange = nEmptyHandAttackRange
        self.nActivedWeaponSlot = 0
        pAIWeaponComponent:SetWeaponParams(self.nActivedWeaponSlot, SAIWeaponCategory.Melee, self.nAttackRange, 0)
        self.nAttackCD = nEmptyHandAttackCD
        self:ClearAttackCDTimer()
        self.bCanAttack = true
        LOG("enabled empty hand attack", self.Owner.szName)
    end
end

function SAIWeaponHuman:ActiveWeapon(nWeaponInstanceId)
    local tbWeaponItem = BattleItemSystemServer:GetItem(nWeaponInstanceId)
    if tbWeaponItem then
        local tbOwner = self.Owner
        local tbWeaponConfig = self:GetWeaponConfig(tbWeaponItem:GetTemplateId())
        local pAIWeaponComponent = self.pAIWeaponComponent
        local nSlotIndex = -1
        local nWeaponCategory = SAIWeaponCategory.None
        local nPreFireTime = self.tbConfig.PreFireTime
        if tbWeaponItem:GetCategory()== BattleItemCategoryDef.HUMAN_THROWN_ITEM then
            nSlotIndex = HumanWeaponSlotDef:SlotCount() + 1
            nWeaponCategory = SAIWeaponCategory.Throw
        elseif tbWeaponItem:GetCategory()== BattleItemCategoryDef.HUMAN_WEAPON then
            nSlotIndex = tbWeaponItem:GetStorageLocation().nSlotIndex
            if (tbWeaponItem:GetTemplate().nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee) then
                nWeaponCategory = SAIWeaponCategory.Melee
                nPreFireTime = 0
            else
                nWeaponCategory = SAIWeaponCategory.GunLike
                local tbWeapon =  tbOwner.HumanWeaponComponent:FindWeaponById(nWeaponInstanceId)
                if tbWeapon:GetProperty().nWeaponCategory == HumanWeaponDef.WeaponCategory.Bow then
                    nPreFireTime = math.max(nPreFireTime, 1)
                    log("bow pre time ", nPreFireTime)
                end
            end
        end
        self.nAttackRange = GetWeaponDistance(tbWeaponConfig)
        self.nActivedWeaponSlot = nSlotIndex

        pAIWeaponComponent:SetWeaponParams(self.nActivedWeaponSlot, nWeaponCategory, self.nAttackRange, nPreFireTime)
        self.nAttackCD = tbWeaponConfig.nAttackIntervalSeconds
        self:ClearAttackCDTimer()
        BattleHumanWeaponSystemNew:SaveCurrentWeaponToOwner(tbOwner)
        LOG("bot actived weapon ", self.Owner.szName, nWeaponCategory, nSlotIndex)
    end
end

function SAIWeaponHuman:DeactiveWeapon()
    local pAIWeaponComponent = self.pAIWeaponComponent
    self.nAttackRange = 0
    self.nActivedWeaponSlot = 0
    pAIWeaponComponent:SetWeaponParams(self.nActivedWeaponSlot, 0, self.nAttackRange, 0)
end

function SAIWeaponHuman:OnConfiged()
    local tbConfig = self.tbConfig
    self.bAllowEmptyHandAttack = tbConfig.AllowEmptyHandAttack
    self.nSwitchWeaponCD = tbConfig.HumanSwitchWeaponCD or 3
    LOG("nSwitchWeaponCD ", self.nSwitchWeaponCD)
end

function SAIWeaponHuman:OnStart()
    local tbOwner = self.Owner
    local nServerInstanceId = tbOwner:GetServerInstanceId()
    local WeaponComponent = tbOwner.HumanWeaponComponent
    local pAIWeaponComponent = self.pAIWeaponComponent
    pAIWeaponComponent.bFireCD = false
    pAIWeaponComponent.bWeaponReloading = false
    pAIWeaponComponent.bSwitchWeapon = false
    if WeaponComponent then
        local nCurrentWeaponInstanceId= WeaponComponent:GetCurrentWeaponInstanceId()
        if nCurrentWeaponInstanceId > 0 then
            self:OnWeaponChanged(nCurrentWeaponInstanceId, 0, nServerInstanceId)
        elseif self.bAllowEmptyHandAttack then
            EnableEmptyHandAttack(self)
        end
    end
    self.bCanAttack = self:CheckIfCanAttack()
end

function SAIWeaponHuman:RegisterEvent(SelfEventHelper)
    SAIWeaponHuman.super.RegisterEvent(self, SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_POST, self, self.OnWeaponEquipped)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_UNEQUIPED_SERVER   , self, self.OnWeaponUnEquipped)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, self.OnWeaponChanged)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_CHEAT_ATTACK     , self, self.OnHumanFired)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_RELOADED_ACTIVATE       , self, self.OnStartWeaponReload)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_RELOADED_DEACTIVATE     , self, self.OnEndWeaponReload)
end


function SAIWeaponHuman:ClearAttackCDTimer()
    if self.AttackCDTimer then
        self.AttackCDTimer:Clear()
        self.AttackCDTimer = nil
        self.pAIWeaponComponent.bFireCD = false
    end
end

function SAIWeaponHuman:CheckIfCanAttack()
    local tbOwner = self.Owner
    local WeaponComponent = tbOwner.HumanWeaponComponent
    for i=1,HumanWeaponSlotDef:SlotCount() do
        local tbWeapon = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.HUMAN_WEAPON,
        tbOwner:GetServerInstanceId(), i)
        if WeaponComponent and tbWeapon and self:CanUseWeapon(tbWeapon:GetTemplateId()) then
           return true
        end
    end
    local tbThrowItems = BattleItemSystemServer:GetUnequippedItemsByCategory(tbOwner:GetServerInstanceId(),
    BattleItemCategoryDef.HUMAN_THROWN_ITEM)
    for _,v in ipairs(tbThrowItems) do
        if WeaponComponent and self:CanUseWeapon(v:GetTemplateId()) then
            return true
        end
    end
    return self.bAllowEmptyHandAttack
end

function SAIWeaponHuman:PickOutWeapon()
    if self.nActivedWeaponSlot > 0 then
        return
    end
    local tbOwner = self.Owner
    local WeaponComponent = tbOwner.HumanWeaponComponent
    for i=1,HumanWeaponSlotDef:SlotCount() do
        local tbWeapon = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.HUMAN_WEAPON,
        tbOwner:GetServerInstanceId(), i)
        if WeaponComponent and tbWeapon and self:CanUseWeapon(tbWeapon:GetTemplateId()) then
            WeaponComponent:SetCurrentWeapon(tbWeapon:GetInstanceId())
            return
        end
    end
    local tbThrowItems = BattleItemSystemServer:GetUnequippedItemsByCategory(tbOwner:GetServerInstanceId(),
    BattleItemCategoryDef.HUMAN_THROWN_ITEM)
    for _,v in ipairs(tbThrowItems) do
        if WeaponComponent and self:CanUseWeapon(v:GetTemplateId()) then
            LOG("equipped throw item")
            BattleHumanWeaponSystemNew:OnHoldThrownWeapon(tbOwner, v:GetInstanceId())
            return
        end
    end
end

function SAIWeaponHuman:DropInWeapon()
    local tbOwner = self.Owner
    local WeaponComponent = tbOwner.HumanWeaponComponent
    WeaponComponent:SetCurrentWeapon(0)
end


function SAIWeaponHuman:OnWeaponEquipped(nOwnerCharacterInstanceId, nWeaponInstanceId)
    if nOwnerCharacterInstanceId == self.Owner.nServerInstanceId then
        self.bCanAttack = self:CheckIfCanAttack()
    end
end



function SAIWeaponHuman:OnWeaponUnEquipped(nOwnerCharacterInstanceId, tbWeaponItem)
    if nOwnerCharacterInstanceId == self.Owner.nServerInstanceId then
        local nSlotIndex  = tbWeaponItem:GetStorageLocation().nSlotIndex
        LOG("unequiped weapon ", self.Owner.szName, nSlotIndex, self.nActivedWeaponSlot)
        if nSlotIndex == self.nActivedWeaponSlot then
            if self.bAllowEmptyHandAttack then
                EnableEmptyHandAttack(self)
            else
                self:DeactiveWeapon()
            end
        end
        self.bCanAttack = self:CheckIfCanAttack()
    end
end


function SAIWeaponHuman:OnWeaponChanged(nNewWeapon, nLastWeapon, nOwnerCharacterInstanceId)
    if nOwnerCharacterInstanceId == self.Owner.nServerInstanceId then
        local tbWeaponItem = BattleItemSystemServer:GetItem(nNewWeapon)
        if tbWeaponItem then
            if (self:CanUseWeapon(tbWeaponItem:GetTemplateId())) then
                self:ActiveWeapon(nNewWeapon)
            else
                self:DeactiveWeapon()
            end
        else
            if self.bAllowEmptyHandAttack then
                EnableEmptyHandAttack(self)
            else
                self:DeactiveWeapon()
            end
        end
    end
end

function SAIWeaponHuman:OnHumanFired(nServerInstanceId)
    if nServerInstanceId == self.Owner.nServerInstanceId then
        local pAIWeaponComponent = self.pAIWeaponComponent
        local nAttackCD = self.nAttackCD
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

function SAIWeaponHuman:OnStartWeaponReload(nTime, nServerInstanceId)
    if nServerInstanceId == self.Owner.nServerInstanceId then
        local pAIWeaponComponent = self.pAIWeaponComponent
        pAIWeaponComponent.bWeaponReloading = true
    end
end

function SAIWeaponHuman:OnEndWeaponReload(nServerInstanceId)
    if nServerInstanceId == self.Owner.nServerInstanceId then
        self.pAIWeaponComponent.bWeaponReloading = false
    end
end


function SAIWeaponHuman:GetHit(X, Y, Z)
    local bHit = math.random(1, 100) <= self.nHitProb
    if bHit then
        return bHit, self.szAnimPart
    end
end


function SAIWeaponHuman:OnStartFire(X, Y, Z)
    assert(self.Owner and self.Owner.pUEActor)
    local tbOwner = self.Owner
    if tbOwner and tbOwner.HumanWeaponComponent and tbOwner:IsAlive() then
        local WeaponComponent = tbOwner.HumanWeaponComponent
        local tbCurrentWeaponInst = WeaponComponent:GetCurrentWeapon()
        local pAIWeaponComponent = self.pAIWeaponComponent
        local pTargetPawn = pAIWeaponComponent.AimTarget
        -- throw item
        if tbCurrentWeaponInst and tbCurrentWeaponInst:IsType(HumanWeaponType.THROW) then
            tbOwner.HumanWeaponComponent:CheatAttack(pTargetPawn)
        elseif tbCurrentWeaponInst and tbCurrentWeaponInst:IsType(HumanWeaponType.GUN) then
            -- gun weapon
            if tbCurrentWeaponInst:IsReloading() then
                return
            end
            local nRemainAmmo = tbCurrentWeaponInst:GetCurrentAmmo()
            if nRemainAmmo <= 0 then
                local tbProperty  = tbCurrentWeaponInst:GetProperty()
                tbOwner.HumanWeaponComponent:Reload(tbProperty.nReloadTime)
                LOG("reload ", tbProperty.nReloadTime)
                return
            end
            local bHit, szPart = self:GetHit(X, Y, Z)
            if bHit and szPart then
                for _,v in ipairs(tbKeyOfHumanBody) do
                    if v == szPart then
                        tbOwner.HumanWeaponComponent:CheatAttack(pTargetPawn, v)
                        break
                    end
                end
            else
                tbOwner.HumanWeaponComponent:CheatAttack(pTargetPawn)
                --LOG("cheat attack miss")
            end
        else
            local nAttackRange = self.nAttackRange
            local nAttackAngle = nMeleeHitAngle
            if tbCurrentWeaponInst then
                local tbProperty  = tbCurrentWeaponInst:GetProperty()
                nAttackRange = math.max(tbProperty.nEffectiveRange * 100, nAttackRange)
            else
                nAttackRange = math.max(nEmptyHandAttackRange, nAttackRange)
            end
            -- melee weapon or empty hand
            if AIUtilityHelper.IsHumanMeleeAttackHit(tbOwner.pUEActor, pTargetPawn, nAttackRange, nAttackAngle, GWorld) then
                tbOwner.HumanWeaponComponent:CheatAttack(pTargetPawn, "Body")
            else
                tbOwner.HumanWeaponComponent:CheatAttack(pTargetPawn)
            end
        end
    end
end

function SAIWeaponHuman:OnEndFire()
    assert(self.Owner and self.Owner.pUEActor)
    local tbOwner = self.Owner
    if tbOwner and tbOwner.HumanWeaponComponent then
        local WeaponComponent = tbOwner.HumanWeaponComponent
        local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
        if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.MELEE) then
            tbCurrentWeapon:StopCheatAttack()
        end
    end
end

function SAIWeaponHuman:OnPreFire()
    local tbOwner = self.Owner
    local HumanWeaponComponent = tbOwner.HumanWeaponComponent
    if HumanWeaponComponent then
        local tbCurrentWeapon = HumanWeaponComponent:GetCurrentWeapon()
        if tbCurrentWeapon and tbCurrentWeapon:GetProperty().nWeaponCategory == HumanWeaponDef.WeaponCategory.Bow then
            tbCurrentWeapon:BowPreAttack()
        end
    end
end

function SAIWeaponHuman:ChangeWeapon(nWeaponSlot)
    local tbOwner = self.Owner
    local tbWeaponItem = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.HUMAN_WEAPON,
    tbOwner:GetServerInstanceId(), nWeaponSlot)
    if tbWeaponItem  then
        local nOldWeaponInstanceId = tbOwner.HumanWeaponComponent:GetCurrentWeaponInstanceId()
        local nNewWeaponInstanceId = tbWeaponItem:GetInstanceId()
        if nOldWeaponInstanceId ~= nNewWeaponInstanceId then
            tbOwner.HumanWeaponComponent:SetCurrentWeapon(nNewWeaponInstanceId)
        else
            self:OnWeaponChanged(nNewWeaponInstanceId, nOldWeaponInstanceId, tbOwner:GetServerInstanceId())
        end
    end
    SAIWeaponHuman.super.ChangeWeapon(self, nWeaponSlot)
end

function SAIWeaponHuman:OnStop()
    self:ClearAttackCDTimer()
end


return SAIWeaponHuman