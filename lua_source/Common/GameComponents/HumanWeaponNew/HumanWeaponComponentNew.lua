local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local HumanWeaponComponentNew = luaclass("HumanWeaponComponentNew", GameComponentBaseClass)

local HumanWeaponHelper = require("HumanWeaponHelper")
local HumanWeaponMisc = require("HumanWeaponMisc")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanWeaponRepHelper = require("HumanWeaponRepHelper")
--local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local HumanMovementStateType = require("HumanMovementStateType")
local TeamWatchServerHelper = require("TeamWatchServerHelper")
local PropName = require("PropName")
local HumanWeaponDef = require("HumanWeaponDef")
local HumanMiscPropertyDefaultIni = require("HumanMiscPropertyDefaultIni")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local SelfAnimationHelper = require("SelfAnimationHelper")
local GamePlayerSelfHelper = nil 
-- local BattleItemSystemHelper = require("BattleItemSystemHelper")
-- local BattleItemSourceDef = require("BattleItemSourceDef")
-- local BattleItemSystemHelper = require("BattleItemSystemHelper")
-- local BattleItemCategoryDef = require("BattleItemCategoryDef")
-- local HumanWeaponDef = require("HumanWeaponDef")
--local Timer = require("Timer")


local SlotDef = HumanWeaponMisc.SlotDef
local HumanWeaponType = HumanWeaponMisc.Type

local NO_WEAPON = 0
local INVALID_TEMPLATE_ID = 0
-- local MAX_ATTACK_NOTIFY_REPLICATE_TIME = 1
-- local EMPTY_TABLE = {}

HumanWeaponComponentNew.tbWeaponById = nil
HumanWeaponComponentNew.tbWeaponBySlot = nil
HumanWeaponComponentNew.nCurrentWeapon = NO_WEAPON
HumanWeaponComponentNew.EmptyHandWeapon = nil
HumanWeaponComponentNew.bHasAuthority = true
HumanWeaponComponentNew.bDedicatedServer = false
HumanWeaponComponentNew.nSavedCurrentWeapon = nil
HumanWeaponComponentNew.bInAttacking = false
HumanWeaponComponentNew.nTotalDamage = 0

local function LOG_DEBUG(self, ...)
    if not self.bDedicatedServer then 
        if not GamePlayerSelfHelper then 
            GamePlayerSelfHelper = require("GamePlayerSelfHelper")
        end 
        local PlayerSelfName = GamePlayerSelfHelper:Get().szName
        log(string.format("[HumanWeaponComponent] Self[%s] Object[%s]", PlayerSelfName, self.Owner.szName), ...)
    else 
        log(string.format("[HumanWeaponComponent] Object[%s]", self.Owner.szName), ...)
    end
    -- log(debug.traceback())
end

local function UpdateHumanRelatedPropertyOriginalValue(tbPlayer, tbProperty)
    local PropertyComponent = tbPlayer.HumanBattlePropertyComponent
    local WeaponPropertyToHumanPropertyMap = HumanWeaponDef.WeaponPropertyToHumanPropertyMap
    for szWeaponPropertyName, szPropName in pairs(WeaponPropertyToHumanPropertyMap) do
        local nPropId = PropName[szPropName]
        local nValue = tbProperty[szWeaponPropertyName]
        log("UpdateHumanPropertyOriginalValue", szPropName, nPropId, szWeaponPropertyName, nValue)
        PropertyComponent:SetPropOriginValue(nPropId, nValue)
    end
end

local function ResetHumanRelatedPropertyOriginalValueToDefault(tbPlayer)
    local PropertyComponent = tbPlayer.HumanBattlePropertyComponent
    local WeaponPropertyToHumanPropertyMap = HumanWeaponDef.WeaponPropertyToHumanPropertyMap
    local tbDefaultValue = HumanMiscPropertyDefaultIni.tbDefault
    for _, szPropName in pairs(WeaponPropertyToHumanPropertyMap) do
        local nPropId = PropName[szPropName]
        local nValue = tbDefaultValue[szPropName]
        log("ResetHumanRelatedPropertyOriginalValueToDefault", szPropName, nPropId, nValue)
        PropertyComponent:SetPropOriginValue(nPropId, nValue)
    end
end

function HumanWeaponComponentNew:GetMontageWithAnimKey(szAnimKey)
    local szMontage, tbTemplate = SelfAnimationHelper:GetHumanAnimation(self.Owner, szAnimKey)
    if not szMontage then 
        return nil
    end 
    local pMontage = SelfAnimationHelper:GetCacheMontage(self, szMontage)

    return pMontage, tbTemplate
end

function HumanWeaponComponentNew:PlayMontageWithAnimKey(szAnimKey, PlayRate)
    if not self.Owner.pUEActor then
        return
    end
    assert(szAnimKey)
    local pMontage = self:GetMontageWithAnimKey(szAnimKey)
    if(pMontage == nil) then
        return 0
    end
	-- local AnimInstance = self.Owner.pUEActor.Mesh:GetAnimInstance()
    -- if( AnimInstance ) then
    --     return AnimInstance:Montage_Play(pMontage, 1, EMontagePlayReturnType.MontageLength, 0, false)
    -- end

    -- local bRet, nTime, pMontage = SelfAnimationHelper:PlayHumanAnimation(self.Owner, szAnimKey, PlayRate)
    -- if bRet then
    --     return nTime, pMontage
    -- else
    --     return 0
    -- end
    if not PlayRate then  
        PlayRate = 1.0
    end 
    return self.Owner.pUEActor:PlayAnimMontage(pMontage, PlayRate, ""), pMontage
    -- return 0
end

function HumanWeaponComponentNew:UpdateHumanRelatedProperty(nNewWeapon)
    if nNewWeapon == NO_WEAPON then
        ResetHumanRelatedPropertyOriginalValueToDefault(self.Owner)
    else
        local tbWeapon = self:GetCurrentWeapon()
        if not tbWeapon:IsType(HumanWeaponType.THROW) then
            UpdateHumanRelatedPropertyOriginalValue(self.Owner, tbWeapon:GetProperty())
        end
    end
end

function HumanWeaponComponentNew:OnWeaponAdded(nInstanceId, nTemplateId, nSlot)
    assert(self.tbWeaponBySlot[nSlot] == nil)
    assert(self.tbWeaponById[nInstanceId] == nil)

    local tbNewWeapon = HumanWeaponHelper.CreateWeaponInfo(nTemplateId)
    if(tbNewWeapon == nil) then
        error("Create weapon info failed, item template id: "..tostring(nTemplateId))
    end

    local tbWeaponById = self.tbWeaponById
    assert(tbWeaponById[nInstanceId] == nil)
    tbWeaponById[nInstanceId] = tbNewWeapon

    local tbWeaponBySlot = self.tbWeaponBySlot
    assert(tbWeaponBySlot[nSlot] == nil)
    tbWeaponBySlot[nSlot] = tbNewWeapon
    LOG_DEBUG(self, "OnWeaponAdded", nInstanceId, "nTemplateId", nTemplateId)
    tbNewWeapon:OnCreated(self, nInstanceId, nTemplateId, nSlot)
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_POST, self.Owner:GetServerInstanceId(), nInstanceId)
    return tbNewWeapon
end

function HumanWeaponComponentNew:OnWeaponRemoved(nInstanceId)
    local tbWeapon = self.tbWeaponById[nInstanceId]
    assert(tbWeapon)
    local nSlot = tbWeapon.nSlot
    assert(self.tbWeaponBySlot[nSlot] == tbWeapon)

    tbWeapon:OnDestroyed()

    self.tbWeaponById[nInstanceId] = nil
    self.tbWeaponBySlot[nSlot] = nil
    LOG_DEBUG(self, "OnWeaponRemoved", nInstanceId)
end

function HumanWeaponComponentNew:OnCurrentWeaponChanged(nInstanceId, bForce, bTemporary)
    self:CancelReload()
    -- local tbOldWeapon = self:GetCurrentWeapon(true)
    -- if(tbOldWeapon) then
    --     tbOldWeapon:OnDeactivate()
    -- end
    --换武器 应该取消aim状态
    self:SetAim(false)

    local nOldWeapon = self.nCurrentWeapon
    local nNewWeapon = nInstanceId > 0 and nInstanceId or -nInstanceId
    self.nLastWeapon = nOldWeapon
    self.bTemporaryWeapon = bTemporary
    LOG_DEBUG(self, "OnCurrentWeaponChanged", nInstanceId, "bForce", bForce)
    self.nCurrentWeapon = nNewWeapon

    -- local tbNewWeapon = self:GetCurrentWeapon(true)
    -- if(tbNewWeapon) then
    --     tbNewWeapon:OnActivate()
    -- end

    --logdebug("OnCurrentWeaponChanged", nNewWeapon)
    -- 重制人物属性
    if GlobalVariableSystem:IsServerLogic() then
        self:UpdateHumanRelatedProperty(nNewWeapon)
        local tbLastWeapon = self:FindWeaponById(nOldWeapon)
        if not tbLastWeapon then 
            tbLastWeapon = self.EmptyHandWeapon 
        end
        if tbLastWeapon then 
            tbLastWeapon:OnServerUnHolded()
        end
        local tbCurrentWeapon = self:GetCurrentWeapon(true)
        if tbCurrentWeapon then 
            tbCurrentWeapon:OnServerHolded()
        end
    end

    HumanWeaponHelper.ServerChangeWeaponState(self.Owner)


    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, nNewWeapon, nOldWeapon, self.Owner:GetServerInstanceId())
end

function HumanWeaponComponentNew:OnAimingChanged(bAiming)
    local tbCurrentWeapon = self:GetCurrentWeapon()
    if(tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.GUN)) then
        tbCurrentWeapon:OnAimChanged(bAiming)
    end
end

function HumanWeaponComponentNew:OnActorCreated(pUEActor)
    HumanWeaponComponentNew.super.OnActorCreated(self, pUEActor)
    self.tbWeaponById = {}
    self.tbWeaponBySlot = {}
    self.nCurrentWeapon = NO_WEAPON
    self.bDedicatedServer = GlobalVariableSystem:IsDedicatedServer()

    HumanWeaponRepHelper.Init(self)

    local EmptyHand = HumanWeaponHelper.CreateEmptyHandWeapon()
    self.EmptyHandWeapon = EmptyHand
    EmptyHand:OnCreated(self, 0, nil, SlotDef.MELEE)
end

function HumanWeaponComponentNew:OnActorDestroyed(pUEActor)
    if self.EmptyHandWeapon then
        self.EmptyHandWeapon:OnDestroyed()
    end

    if self.tbWeaponById then
        for _, v in pairs(self.tbWeaponById) do
            v:OnDestroyed()
        end
    end

    SelfAnimationHelper:ClearOwnerCache(self)
    HumanWeaponComponentNew.super.OnActorDestroyed(self, pUEActor)
end

------------------------------------------------------------------------------
-- authority only
function HumanWeaponComponentNew:AddWeapon(nInstanceId, nTemplateId, nSlot)
    assert(self.bHasAuthority)
    assert(nInstanceId and nInstanceId > 0)
    assert(nTemplateId and nTemplateId > 0)

    if(self.bDedicatedServer) then
        self.rtbInstanceIdBySlot[nSlot]:Set(nInstanceId)
        self.rtbTemplateIdBySlot[nSlot]:Set(nTemplateId)
    end
    return self:OnWeaponAdded(nInstanceId, nTemplateId, nSlot)
end

function HumanWeaponComponentNew:RemoveWeapon(nInstanceId)
    assert(self.bHasAuthority)
    local tbWeapon = self.tbWeaponById[nInstanceId]
    assert(tbWeapon ~= nil)

    if(self.bDedicatedServer) then
        -- 背包中切换武器时会无法切换
        -- if(nInstanceId == self.nCurrentWeapon) then
        --     self:SetCurrentWeapon(NO_WEAPON, true)
        -- end
        local nSlot = tbWeapon.nSlot
        self.rtbTemplateIdBySlot[nSlot]:Set(INVALID_TEMPLATE_ID)
        self.rtbInstanceIdBySlot[nSlot]:Set(NO_WEAPON)
    end

    self:OnWeaponRemoved(nInstanceId)
end

function HumanWeaponComponentNew:TryCancelThrow()
    local tbCurrentWeapon = self:GetCurrentWeapon()
    if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.THROW)  then
        tbCurrentWeapon:OnCancel()
    end
end

function HumanWeaponComponentNew:SetCurrentWeapon(nInstanceId, bForce, bTemporary)
    assert(self.bHasAuthority)
    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    local nMovementState = HumanMovementStateComponent:GetCurrentState()
    if nInstanceId ~= NO_WEAPON then 
        if nMovementState == HumanMovementStateType.Jumping_SpeelWall then
            log("In JumpSpeel Can't SetWeapon nInstanceId", nInstanceId, self.Owner.szName)
            return
        end
    
        if nMovementState == HumanMovementStateType.Dying_State then
            log("In Dying_State Can't SetWeapon nInstanceId", nInstanceId, self.Owner.szName)
            return
        end
    
        if HumanMovementStateComponent:IsInVehicle() then
            log("In Vehicle Can't SetWeapon nInstanceId", nInstanceId, self.Owner.szName)
            return
        end        

        if nMovementState == HumanMovementStateType.Swimming then
            log("In Swimming Can't SetWeapon nInstanceId", nInstanceId, self.Owner.szName)
            return
        end

        if not self:FindWeaponById(nInstanceId) then
            log("Can't Find Weapon", nInstanceId, self.Owner.szName)
            return
        end        
    end 

    if(self.nCurrentWeapon == nInstanceId and not bForce) then
        log(" nCurrentWeapon = nInstanceId Can't SetWeapon nInstanceId", nInstanceId, self.Owner.szName)
        return
    end

    if(bForce) then
        nInstanceId = -nInstanceId
    end

    if(self.bDedicatedServer) then
        self:TryCancelThrow()
        self.rCurrentWeapon:Set(nInstanceId)
        HumanWeaponHelper.SendCurrentWeaponToClient(self, nInstanceId, bForce)
        HumanWeaponHelper.SendWeaponAmmoInfoToViewers(self, nInstanceId)
    end
    self:OnCurrentWeaponChanged(nInstanceId, bForce, bTemporary)
end

function HumanWeaponComponentNew:SetAim(bAiming)
    assert(self.bHasAuthority)
    if self:IsAiming() == bAiming then
        return false
    end

    local tbCurrentWeapon = self:GetCurrentWeapon()
    --非枪械不能切aiming, 但是如果是从 枪械切到非枪械时候,如果是aiming,那么是可以切到非aiming的
    if(not tbCurrentWeapon or not tbCurrentWeapon:IsType(HumanWeaponType.GUN)) and bAiming then
        return false
    end

    if(self.bDedicatedServer) then
        self.rInAiming:Set(bAiming)
        TeamWatchServerHelper.NotifyViewersAimState(self.Owner, false, bAiming)
    end
    self:OnAimingChanged(bAiming)
    return true
end

function HumanWeaponComponentNew:Reload(nTime)
    assert(self.bHasAuthority)

    local tbPlayer = self.Owner
    if tbPlayer:IsDead() or tbPlayer:IsDying() then
        return false
    end

    local tbCurrentWeapon = self:GetCurrentWeapon()
    if(not tbCurrentWeapon or not tbCurrentWeapon:IsType(HumanWeaponType.GUN)) then
        return false
    end

    local nServerTime = tbCurrentWeapon:GetCurrentMontageInStateLength(HumanWeaponStateDef.RELOADING)
    if nServerTime then
        nTime = nServerTime
    end

    if(not tbCurrentWeapon:Reload(nTime)) then
        return false
    end

    if(self.bDedicatedServer) then
        local nReload = self.rHumanReloading:Get()
        if nReload ~= 0 then
            nReload = nReload * -1
        else
            nReload = 1
        end
        self.rHumanReloading:Set(nReload)
    end

    return true
end

function HumanWeaponComponentNew:CancelReload()
    assert(self.bHasAuthority)
    local tbCurrentWeapon = self:GetCurrentWeapon()
    if(not tbCurrentWeapon or not tbCurrentWeapon:IsType(HumanWeaponType.GUN)) then
        return
    end
    tbCurrentWeapon:CancelReload()
    if(self.bDedicatedServer) then
        self.rHumanReloading:Set(0)
    end
end

function HumanWeaponComponentNew:UpdateAttachments(nWeaponInstanceId, tbAttachmentTemplateIds)
    local tbWeapon = self:FindWeaponById(nWeaponInstanceId)
    if(tbWeapon) then
        tbWeapon:OnUpdateAttachments(tbAttachmentTemplateIds)
    end
end

------------------------------------------------------------------------------
function HumanWeaponComponentNew:GetCurrentWeaponInstanceId()
    return self.nCurrentWeapon
end

function HumanWeaponComponentNew:GetCurrentWeaponTemplateId()
    local tbWeapon = self:GetCurrentWeapon()
    if not tbWeapon then
        return NO_WEAPON
    end
    return self:GetCurrentWeapon(true).nTemplateId
end

function HumanWeaponComponentNew:GetCurrentWeaponCategory()
    return HumanWeaponHelper.GetWeaponCategory(self:GetCurrentWeaponTemplateId())
end
function HumanWeaponComponentNew:GetCurrentSlot()
    local tbWeapon = self:GetCurrentWeapon()
    return tbWeapon ~= nil and tbWeapon.nSlot or nil
end

function HumanWeaponComponentNew:GetCurrentWeapon(bWithEmptyHand)
    local nCurrentWeapon = self.nCurrentWeapon
    -- LOG_DEBUG(self, "GetCurrentWeapon", nCurrentWeapon)

    if(nCurrentWeapon == NO_WEAPON) then
        return bWithEmptyHand and self.EmptyHandWeapon or nil
    else
        return self.tbWeaponById[nCurrentWeapon]
    end
end

function HumanWeaponComponentNew:FindWeaponById(nInstanceId)
    return self.tbWeaponById[nInstanceId]
end

function HumanWeaponComponentNew:FindWeaponBySlot(nSlot)
    if not self.tbWeaponBySlot then
        return nil
    end
    return self.tbWeaponBySlot[nSlot]
end

function HumanWeaponComponentNew:FindWeaponByType(nType)
    if not self.tbWeaponById then  
        return nil
    end 

    for _, v in pairs(self.tbWeaponById) do
        if(v:IsType(nType)) then
            return v
        end
    end
    return nil
end

function HumanWeaponComponentNew:IsAiming()
    local tbCurrentWeapon = self:GetCurrentWeapon()
    if(not tbCurrentWeapon or not tbCurrentWeapon:IsType(HumanWeaponType.GUN)) then
        return false
    end

    return tbCurrentWeapon:IsAiming()
end

function HumanWeaponComponentNew:CanChangeWeapon()
    return true
end

-- 专门为服务器发起的攻击使用，多用于ai，如果未打中nDamageType请填nil
function HumanWeaponComponentNew:CheatAttack(tbTarget, nDamageType, tbParam)
    local tbCurrentWeapon = self:GetCurrentWeapon(true)
    tbCurrentWeapon:CheatAttack(tbTarget, nDamageType, tbParam)
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_CHEAT_ATTACK, self.Owner:GetServerInstanceId())
end

function HumanWeaponComponentNew:GetCurrentState()
    return self.StateHelper:GetCurrentState()
end

function HumanWeaponComponentNew:HasNoWeapon()
    return self.nCurrentWeapon == NO_WEAPON
end

function HumanWeaponComponentNew:SaveCurrentWeapon()
    assert(GlobalVariableSystem:IsServerLogic())

    self.nSavedCurrentWeapon = self.nCurrentWeapon
end

function HumanWeaponComponentNew:GetSavedWeaponIntanceId()
    return self.nSavedCurrentWeapon
end

function HumanWeaponComponentNew:RestoreCurrentWeapon(bForce)
    assert(GlobalVariableSystem:IsServerLogic())

    local nSavedCurrentWeapon = self.nSavedCurrentWeapon
    if(nSavedCurrentWeapon ~= nil) then
        self.nSavedCurrentWeapon = nil
        self:SetCurrentWeapon(nSavedCurrentWeapon, bForce)
    end
end

function HumanWeaponComponentNew:OnDyingChanged(bIsDying)
    -- if not GlobalVariableSystem:IsServerLogic() then
    --     return
    -- end

    -- if bIsDying then
    --     self:SaveCurrentWeapon()
    --     self:SetCurrentWeapon(NO_WEAPON, true)
    -- else
    --     self:RestoreCurrentWeapon()
    -- end
    self.bIsDying = bIsDying
    if(self.bHasAuthority) then
        self:CancelReload()
    end
end

function HumanWeaponComponentNew:IsReloading()
    local tbWeapon = self:GetCurrentWeapon()
    if not tbWeapon then
        return false
    end

    if(tbWeapon:IsType(HumanWeaponType.GUN)) then
        return tbWeapon:IsReloading()
    end
    return false
end

function HumanWeaponComponentNew:GetWeaponSpeedFactor()
    local nCurrentWeapon = self.nCurrentWeapon

    local nSpeedFactor = 1
    local tbWeaponCategoryProperty = nil

    for nInstanceId, tbWeapon in pairs(self.tbWeaponById) do
        local tbProperty = tbWeapon:GetProperty()
        if tbProperty then
            tbWeaponCategoryProperty = tbProperty.tbWeaponCategoryProperty
        end
        if tbWeaponCategoryProperty then
            if(nInstanceId == nCurrentWeapon) then
                local bReloading, bAiming
                if(tbWeapon:IsType(HumanWeaponType.GUN)) then
                    bReloading = tbWeapon:IsReloading()
                    bAiming = tbWeapon:IsAiming()
                end

                if bAiming and not bReloading then
                    nSpeedFactor = nSpeedFactor * tbWeaponCategoryProperty.nSpeedFactorWhenAim
                elseif self:IsAttacking() then
                    nSpeedFactor = nSpeedFactor * tbWeaponCategoryProperty.nSpeedFactorWhenFire
                elseif bReloading then
                    nSpeedFactor = nSpeedFactor * tbWeaponCategoryProperty.nSpeedFactorWhenLoad
                else
                    nSpeedFactor = nSpeedFactor * tbWeaponCategoryProperty.nSpeedFactorWhenHold
                end
            else
                nSpeedFactor = nSpeedFactor * tbWeaponCategoryProperty.nSpeedFactorWhenCarry
            end
        end
    end

    return nSpeedFactor
end

function HumanWeaponComponentNew:TryRemoveAllThrowWeapon()
    while(true) do
        local tbThrownWeapon = self:FindWeaponByType(HumanWeaponType.THROW)
        if(tbThrownWeapon == nil) then
            break
        end

        self:RemoveWeapon(tbThrownWeapon:GetInstanceId())
    end
end
function HumanWeaponComponentNew:OnRepAttacking(bInAttacking)
    self.bInAttacking = bInAttacking
    if bInAttacking then 
        EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, HumanWeaponStateDef.ATTACKING, self.Owner)
    else
        EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, HumanWeaponStateDef.HOLDING, self.Owner)
    end
end
function HumanWeaponComponentNew:OnAttackStart()
    self.bInAttacking = true
    HumanWeaponHelper.ServerChangeWeaponState(self.Owner)
    self.rAttacking:Set(true)
end

function HumanWeaponComponentNew:OnAttackEnd()
    self.bInAttacking = false
    HumanWeaponHelper.ServerChangeWeaponState(self.Owner)
    self.rAttacking:Set(false)
end

function HumanWeaponComponentNew:OnHumanWeaponDamage(nDamage)
    self.nTotalDamage = self.nTotalDamage + nDamage
end

function HumanWeaponComponentNew:OnDamageEnd()
    local tbWeapon = self:GetCurrentWeapon(true)
    if not tbWeapon then 
        return
    end 
    local nWeaponTemplateId = tbWeapon.nTemplateId
    local nTotalDamage = self.nTotalDamage
    EventManager:OnFireEvent(CommonEventDef.EV_ON_CHARACTER_ATTACKED, self.Owner, nWeaponTemplateId, nTotalDamage)
    self.nTotalDamage = 0
end

function HumanWeaponComponentNew:IsAttacking()
    return self.bInAttacking
end

function HumanWeaponComponentNew:IsUnmovedWeaponState()
    local tbWeapon = self:GetCurrentWeapon()
    if not tbWeapon then
        return false
    end

    local bReloading = false
    if(tbWeapon:IsType(HumanWeaponType.GUN)) then
        bReloading = tbWeapon:IsReloading()
    end

    local tbCurrentWeapon = self:GetCurrentWeapon(true)
    local bThrowWeapon = tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.THROW) or false
    local notThrowItemAttacking = not bThrowWeapon and self:IsAttacking()
    if bReloading or notThrowItemAttacking then
        return true
    end
    return false
end

function HumanWeaponComponentNew:IsHaveAimWeapon()
    local tbWeapon = self:GetCurrentWeapon()
    if not tbWeapon then
        return false
    end

    if(tbWeapon:IsType(HumanWeaponType.GUN)) then
        return true
    end

    return false
    -- local bHas = true
    -- local nWeaponInstanceId = self:GetCurrentWeaponInstanceId()
    -- local WeaponItem = BattleItemSystemHelper:GetItem(nWeaponInstanceId, false)
    -- if nWeaponInstanceId == 0 or WeaponItem == nil then
    --     bHas = false
    -- elseif (WeaponItem:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
    --     bHas = false
    -- else
    --     local nWeaponCategory = WeaponItem:GetTemplate().nWeaponCategory
    --     if nWeaponCategory == HumanWeaponDef.WeaponCategory.Melee then
    --         bHas = false
    --     end
    -- end
    -- return bHas
end

function HumanWeaponComponentNew:OnCreate(Owner, tbParams)
    HumanWeaponComponentNew.super.OnCreate(self, Owner, tbParams)
    if GlobalVariableSystem:IsServerLogic() then
        ResetHumanRelatedPropertyOriginalValueToDefault(Owner)
    end
    return true
end

function HumanWeaponComponentNew:CancelCheatAttack()
    local tbWeapon = self:GetCurrentWeapon()
    if not tbWeapon then
        return
    end
    
    tbWeapon:CancelCheatAttack()
    return
end

function HumanWeaponComponentNew:ReloadAllWeaponOnChangeToHuman()
    for k, _ in pairs(self.tbWeaponById) do
        local tbWeapon = self:FindWeaponById(k)
        if tbWeapon then 
            if(tbWeapon:IsType(HumanWeaponType.GUN)) then
                local nCurrentAmmo, nMaxAmmo = tbWeapon:GetAmmoInfo()
                if nCurrentAmmo < nMaxAmmo then 
                    tbWeapon:ReloadImpInServer()
                    -- local tbItem = BattleItemSystemHelper:GetItem(k)
                    -- local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
                    -- BattleItemSystemServer:CreateAndEquipItemWithOwner(tbItem:GetOwnerCharacterInstanceId(), k,
                    --     tbItem:GetBulletItemTemplateId(), nMaxAmmo, BattleItemSourceDef.CHANGE_TO_HUMAN, true)   
                end            
            end
        end
    end
    return nil
end

return HumanWeaponComponentNew