local luaclass = require("luaclass")
local HumanWeaponComponentNew = require("HumanWeaponComponentNew")
local HumanWeaponComponentNew_C = luaclass("HumanWeaponComponentNew_C", HumanWeaponComponentNew)

local HumanWeaponStateLocalHelper = require("HumanWeaponStateLocalHelper")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponAttackHelper = require("HumanWeaponAttackHelper")
local SelfAnimationHelper = require("SelfAnimationHelper")
-- local ResourceManager = require("ResourceManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanWeaponHelper = require("HumanWeaponHelper")
local HumanMovementStateType = require("HumanMovementStateType")
local ClientEventDef = require("ClientEventDef")
local HumanWeaponDef = require("HumanWeaponDef")
local Timer = require("Timer")
local BattlePickupSystem = require("BattlePickupSystem")
-- local TutorialDungeonIni = require("TutorialDungeonIni")
-- local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local HumanWeaponAnimationDataTable = require("HumanWeaponAnimationDataTable")
local PropName = require("PropName")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local NO_WEAPON = 0
-- local INVALID_TEMPLATE_ID = 0
local LUA_TO_BP_STATE
local BP_WEAPON_TYPE_NONE


-- local SlotDef = HumanWeaponMisc.SlotDef
local HumanWeaponType = HumanWeaponMisc.Type

HumanWeaponComponentNew_C.bPlayerSelf = false
HumanWeaponComponentNew_C.StateHelper = nil
HumanWeaponComponentNew_C.nNextWeapon = nil
HumanWeaponComponentNew_C.AttackHelper = nil
-- HumanWeaponComponentNew_C.tbCachedMontages = nil
HumanWeaponComponentNew_C.tbDirtyType = nil
HumanWeaponComponentNew_C.tbPropertyToDirtyType = nil
HumanWeaponComponentNew_C.AttackCDTimer = nil
HumanWeaponComponentNew_C.fnAttackCDEnd = nil
HumanWeaponComponentNew_C.DispersionTimer = nil
HumanWeaponComponentNew_C.nPendingCurrentWeapon = nil   -- 等到state切到能换武器时在换
HumanWeaponComponentNew_C.bHighThrow = true   --客户端本地临时存上一次选择的投掷状态
HumanWeaponComponentNew_C.bPendingHoldThrowWeapon = false
HumanWeaponComponentNew_C.bLastRun = false
------------------------------------------------------------------------------
local function InitBPEnums()
    LUA_TO_BP_STATE = {
        [HumanWeaponStateDef.UNHOLDED]  = Enum_HumanWeaponState.Unholded,
        [HumanWeaponStateDef.UNHOLDING] = Enum_HumanWeaponState.Unholding,
        [HumanWeaponStateDef.HOLDED]    = Enum_HumanWeaponState.Holded,
        [HumanWeaponStateDef.HOLDING]   = Enum_HumanWeaponState.Holding,
        [HumanWeaponStateDef.RELOADING] = Enum_HumanWeaponState.Reloading,
        --[HumanWeaponStateDef.AIMING]    = Enum_HumanWeaponState.Aiming,
        [HumanWeaponStateDef.ATTACKING] = Enum_HumanWeaponState.Attacking,
        [HumanWeaponStateDef.NONE] =      Enum_HumanWeaponState.None,
    }

    BP_WEAPON_TYPE_NONE = Enum_HumanWeaponType.Empty
end


local function LOG_DEBUG(self, ...)
    local PlayerSelfName = GamePlayerSelfHelper:Get().szName
    log(string.format("[HumanWeaponComponent] Self[%s] Object[%s]", PlayerSelfName, self.Owner.szName), ...)
    -- log(debug.traceback())
end

local function StopAttackCD(self)
    local AttackCDTimer = self.AttackCDTimer
    if(AttackCDTimer) then
        AttackCDTimer:Clear()
        self.AttackCDTimer = nil
    end
end

local function StartAttackCD(self, nCD)
    StopAttackCD(self)

    if(nCD == nil or nCD <= 0) then
        return
    end

    local fnAttackCDEnd = self.fnAttackCDEnd
    if(fnAttackCDEnd == nil) then
        fnAttackCDEnd = function()
            self.AttackCDTimer = nil
        end
        self.fnAttackCDEnd = fnAttackCDEnd
    end

    self.AttackCDTimer = Timer.NewTimer(fnAttackCDEnd, nCD, false)
end

local function InAttackCD(self)
    return self.AttackCDTimer ~= nil
end

------------------------------------------------------------------------------
-- parent interface
local DeactivateAttackState = function(self, bCancel)
    if(self:GetCurrentState() == HumanWeaponStateDef.ATTACKING) then
        local nInstanceId = self:GetCurrentWeaponInstanceId()
        self.StateHelper:ChangeState(nInstanceId ~= NO_WEAPON and HumanWeaponStateDef.HOLDED or HumanWeaponStateDef.UNHOLDED,
            bCancel)
    end
end
local function GetHumanArmorId(self)
    local HumanBattlePropertyComponent = self.Owner.HumanBattlePropertyComponent
    if HumanBattlePropertyComponent then
        local nCurrentArmorTemplatedId = self.Owner.HumanBattlePropertyComponent:GetProp(PropName.nCurrentArmorTemplateId)
        if nCurrentArmorTemplatedId < 0 then
            return 0
        end
        return nCurrentArmorTemplatedId
    end
    return 0
end

local function SetWeaponAnimationKey(self, tbWeapon)
    if not tbWeapon then
        tbWeapon = self:GetCurrentWeapon(true)
    end
    if not tbWeapon then
        return 
    end
    local nArmorId = GetHumanArmorId(self)
    local szWeaponAnim = HumanWeaponAnimationDataTable:GetWeaponAnim(tbWeapon.nTemplateId, nArmorId)
    self.Owner.pUEActor:SetWeaponAnimName(szWeaponAnim)
end

local function OnHumanArmorChanged(self)
    SetWeaponAnimationKey(self)
end 
function HumanWeaponComponentNew_C:OnActorCreated(pUEActor)
    HumanWeaponComponentNew_C.super.OnActorCreated(self, pUEActor)
    log("HumanWeaponComponentNew OnActorCreated " , self.Owner.szName)
    InitBPEnums()

    self.bPlayerSelf = self.Owner.ObjectType == GameObjectTypeDef.PlayerSelf
    self.bHasAuthority = self.bPlayerSelf or GlobalVariableSystem:IsStandaloneServer()

    local StateHelper = HumanWeaponStateLocalHelper()
    self.StateHelper = StateHelper
    StateHelper:Init(self)

    local AttackHelper = HumanWeaponAttackHelper()
    self.AttackHelper = AttackHelper
    AttackHelper:Init(self, DeactivateAttackState)

    SetWeaponAnimationKey(self)

    self.Owner.DelegateComponent.OnHumanArmorChanged:Bind(OnHumanArmorChanged, self)
    -- self.tbCachedMontages = {}
end

function HumanWeaponComponentNew_C:OnActorDestroyed(pUEActor)
    self:DestroyDispersionTimer()
    StopAttackCD(self)
    log("HumanWeaponComponentNew OnActorDestroyed " , self.Owner.szName)
    if self.StateHelper then
        self.StateHelper:Uninit()
        self.StateHelper = nil
    end
    if self.AttackHelper then
        self.AttackHelper:Uninit()
        self.AttackHelper = nil
    end
    self.Owner.DelegateComponent.OnHumanArmorChanged:Unbind(OnHumanArmorChanged, self)
    -- for k, v in pairs(self.tbCachedMontages) do
    --     ResourceManager:Unhold(v)
    -- end
    -- self.tbCachedMontages = nil
    HumanWeaponComponentNew_C.super.OnActorDestroyed(self, pUEActor)
end

function HumanWeaponComponentNew_C:OnWeaponRemoved(nInstanceId)
    if(self.nCurrentWeapon == nInstanceId and self:IsAttacking()) then
        -- 当前武器正在攻击中，删之前强制cancelattack
        self:CancelAttack()
    end
    if self.nNextWeapon == nInstanceId then
        self.nNextWeapon = nil
    end
    if self.nPendingCurrentWeapon == nInstanceId then
        self:SetPendingCurrentWeapon(nil)
    end

    -- if self.nCurrentWeapon == nInstanceId and not self.bPlayerSelf then 
    --     self:OnCurrentWeaponChanged(NO_WEAPON, true)
    -- end

    if self:FindWeaponById(nInstanceId) ~= nil then
        HumanWeaponComponentNew_C.super.OnWeaponRemoved(self, nInstanceId)
    end
end

local function SetCurrentWeaponWithEvent(self, nNewWeapon)
    local nLastWeapon = self.nCurrentWeapon
    if(nLastWeapon == nNewWeapon) then
        return false
    end
    -- if not self:FindWeaponById(nNewWeapon) then
    --     return
    -- end
    -- local tbOldWeapon = self:GetCurrentWeapon(true)
    -- if(tbOldWeapon) then
    --     tbOldWeapon:OnDeactivate()
    -- end
    if nNewWeapon ~= NO_WEAPON and not self:FindWeaponById(nNewWeapon) then
        -- error(string.format("SetCurrentWeaponWithEvent Can't Find Weapon id [%d]", nNewWeapon))
        return false
    end
    LOG_DEBUG(self, "SetCurrentWeaponWithEvent nCurrent", self.nCurrentWeapon, "nNewWeapon", nNewWeapon)
    self.nCurrentWeapon = nNewWeapon

    -- logdebug("SetCurrentWeaponWithEvent", nNewWeapon, debug.traceback())

    -- 修改当前武器
    local tbWeapon = self:GetCurrentWeapon(true)
    -- if(tbWeapon) then
    --     tbWeapon:OnActivate()
    -- end

    -- local tbBPInfo = tbWeapon:GetBPInfo()
    -- SetWeaponAnimationKey(self, tbWeapon)
    local pUEActor = self.Owner.pUEActor
    pUEActor:SetCurrentWeaponType(nNewWeapon ~= NO_WEAPON and tbWeapon:GetWeaponBPType() or BP_WEAPON_TYPE_NONE)


    if GlobalVariableSystem:IsServerLogic() then
        self:UpdateHumanRelatedProperty(nNewWeapon)
    end

    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, nNewWeapon, nLastWeapon, self.Owner:GetServerInstanceId())
    return true
end

local function TryHideThrowActor(self, bForce, nNewWeapon)
    --1. 当前武器还在，是投掷物
    --2. 强制切空手的时候
    --3. 客户端本地
    --4. 是投掷物
    if self.bPlayerSelf then
        local tbCurrentWeapon = self:GetCurrentWeapon(true)
        if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.THROW) and nNewWeapon == NO_WEAPON and bForce then
            tbCurrentWeapon:HideThrow()
        end
    end
end

-- local function IsTutorialDungeon()
--     local nDungeonId = BattleGameModeSystem.nDungeonId
--     if nDungeonId == TutorialDungeonIni.nDungeonId then
--         return true
--     end
--     return false
-- end

-- 收到服务器同步消息
function HumanWeaponComponentNew_C:OnCurrentWeaponChanged(nNewWeapon, bForce)
    if self.bPlayerSelf then
        self:CancelReload()
        --本地自己换武器需要取消老的武器aim 状态
        HumanWeaponComponentNew_C.super.SetAim(self, false)
        --self:SetAim(false)
    end

    local StateHelper = self.StateHelper
    local nCurrentState = StateHelper:GetCurrentState()
    local nCurrentWeapon = self.nCurrentWeapon
    if(bForce == nil) then
        bForce = false
    end
    if(nNewWeapon < 0) then
        bForce = true
        nNewWeapon = -nNewWeapon
    end

    self:SetPendingCurrentWeapon(nil)
    EventManager:OnFireEvent(ClientEventDef.EV_START_CHANGE_HUMAN_WEAPON, self.Owner, nNewWeapon)
    
    self.bPendingHoldThrowWeapon = false
    -- logdebug("OnCurrentWeaponChangedClient", nCurrentWeapon, nNewWeapon, bForce, debug.traceback())
    local bCurrentWeaponValid = nCurrentWeapon ~= NO_WEAPON and self:FindWeaponById(nCurrentWeapon) == nil
    if(bForce or bCurrentWeaponValid) then
        -- 当前武器没了，或者强制，直接拿起
        TryHideThrowActor(self, bForce, nNewWeapon)
        -- 服务器强制设置为空。不这么做无法把武器放回后背
        if nNewWeapon ~= nCurrentWeapon then
            StateHelper:ChangeState(HumanWeaponStateDef.UNHOLDED, true)
        end
        SetCurrentWeaponWithEvent(self, nNewWeapon)
        if nNewWeapon ~= NO_WEAPON then
            StateHelper:ChangeState(HumanWeaponStateDef.HOLDED, true)
        end
    elseif(nCurrentWeapon == NO_WEAPON or nCurrentState == HumanWeaponStateDef.UNHOLDING) then
        -- 拿出新武器 或者 强收过程中在拿出来
        if SetCurrentWeaponWithEvent(self, nNewWeapon) then
            if nNewWeapon ~= NO_WEAPON then 
                StateHelper:ChangeState(HumanWeaponStateDef.HOLDING, true)
            end
        end
    else
        -- 不管下把武器是什么，先收了再说，真正拿出下吧武器的逻辑在OnStateChange触发
        self.nNextWeapon = nNewWeapon
        StateHelper:ChangeState(HumanWeaponStateDef.UNHOLDING, true)
    end
end

function HumanWeaponComponentNew_C:OnStateActivate(nState)
    local nCurrentWeapon = self.nCurrentWeapon
    local tbCurrentWeapon = self:GetCurrentWeapon(true)
    --logdebug("OnStateActivate", HumanWeaponStateDef.v2s(nState))
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, nState, self.Owner)
    local pUEActor = self.Owner.pUEActor
    pUEActor:SetCurrentWeaponState(LUA_TO_BP_STATE[nState])
    if(tbCurrentWeapon) then
        tbCurrentWeapon:OnStateActivate(nState)
    end

    --EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_STATE_ACTIVATE, nState, self.Owner)

    if(nState == HumanWeaponStateDef.UNHOLDED) then
        local nNextWeapon = self.nNextWeapon
        if nNextWeapon and nNextWeapon ~= NO_WEAPON and not self:FindWeaponById(nNextWeapon) then
            error(string.format("OnStateActivate Can't Find Weapon id [%d]", nNextWeapon))
            return
        end

        self.nNextWeapon = nil
        if(nCurrentWeapon == nNextWeapon) then
            return
        end

        local nNewWeapon = nNextWeapon ~= nil and nNextWeapon or NO_WEAPON
        SetCurrentWeaponWithEvent(self, nNewWeapon)

        if(nNewWeapon ~= NO_WEAPON) then
            self.StateHelper:ChangeState(HumanWeaponStateDef.HOLDING)
        end
    elseif(nState == HumanWeaponStateDef.ATTACKING) then
        local tbAttackInfo = tbCurrentWeapon:GenerateAttackInfo()
        if(tbAttackInfo and self.bPlayerSelf) then
            HumanWeaponHelper.SendAttackStart()
            self.AttackHelper:StartAttack(tbCurrentWeapon, tbAttackInfo)
        end
    elseif(nState == HumanWeaponStateDef.RELOADING) then
        if(self.bPlayerSelf) then
            -- 这个包本来应该是从system发，但不想让component引入system，所以放到helper里了
            HumanWeaponHelper.SendReloadRequest(self:GetCurrentWeaponInstanceId(), self:GetCurrentStateElapsedTime())
        end
    end

    local nPendingCurrentWeapon = self.nPendingCurrentWeapon
    if(nPendingCurrentWeapon ~= nil and self:CanChangeWeapon(nPendingCurrentWeapon)) then
        -- 当攻击结束后改变武器，为progressbar服务
        self.nPendingCurrentWeapon = nil
        LOG_DEBUG(self, "nPendingCurrentWeapon", nPendingCurrentWeapon)
        if(math.abs(nPendingCurrentWeapon) ~= self:GetCurrentWeaponInstanceId()) then
            self:OnCurrentWeaponChanged(nPendingCurrentWeapon)
        end
    end
end

function HumanWeaponComponentNew_C:OnStateDeactivate(nState, bCancel)
    --logdebug("OnStateDeactivate", HumanWeaponStateDef.v2s(nState), bCancel)

    local tbCurrentWeapon = self:GetCurrentWeapon(true)
    if(tbCurrentWeapon) then
        tbCurrentWeapon:OnStateDeactivate(nState, bCancel)
    end
    --EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_STATE_DEACTIVATE, nState, self.Owner, bCancel)

    if(self.bPlayerSelf) then
        if(nState == HumanWeaponStateDef.RELOADING) then
            if(bCancel) then
                -- 这个包本来应该是从system发，但不想让component引入system，所以放到helper里了
                HumanWeaponHelper.SendCancelReloadRequest(self:GetCurrentWeaponInstanceId())
            end
        elseif(nState == HumanWeaponStateDef.ATTACKING) then
            StartAttackCD(self, self.AttackHelper:GetCD())
            HumanWeaponHelper.SendAttackEnd()
        end
    end
end



function HumanWeaponComponentNew_C:ChangeUEActorStateForAim(bAiming, bForce)
    if not self.Owner or not self.Owner.pUEActor then
        return
    end

    local pUEActor = self.Owner.pUEActor
    pUEActor:SetAiming(bAiming)
    if bAiming and pUEActor.bRun then
        self.bLastRun = pUEActor.bRun
        pUEActor.bRun = false
    end

    if not bAiming and self.bLastRun then
        pUEActor.bRun = true
        self.bLastRun = false
    end
    if self.bPlayerSelf or bForce then
        ExtendBlueprintFunctions.SetLargeCoordPrecisionOptimize(pUEActor, bAiming)
        EngineExtActorShell.SetActorSkeletalMeshCastShadow(pUEActor, not bAiming)
        -- 把人身上背着的武器隐藏
        for _, tbWeapon in pairs(self.tbWeaponById) do
            if tbWeapon and tbWeapon.pWeaponActor then
                -- EngineExtActorShell.SetActorSkeletalMeshCastShadow(tbWeapon.pWeaponActor, not bAiming)
                local bNotThrow = not tbWeapon:IsType(HumanWeaponType.THROW)
                local bValidState = tbWeapon.nState == HumanWeaponStateDef.UNHOLDED or tbWeapon.nState == nil
                local bHide1 = bNotThrow and bValidState
                if bHide1 then
                    tbWeapon.pWeaponActor:SetActorHiddenInGame(bAiming)
                end
            end
        end
        --开镜隐藏人的若干部件
        pUEActor.HumanAvatarComponent:UpdatePartOnAimState(bAiming)
        if bAiming then
            pUEActor.Mesh.BoundsScale = 10
        else
            pUEActor.Mesh.BoundsScale = 1
        end
    end
end

function HumanWeaponComponentNew_C:OnAimingChanged(bNewAiming)
    self:ChangeUEActorStateForAim(bNewAiming)
    HumanWeaponComponentNew_C.super.OnAimingChanged(self, bNewAiming)
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, self:GetCurrentState(), self.Owner)
end

------------------------------------------------------------------------------
-- normal interface

function HumanWeaponComponentNew_C:GetCurrentStateElapsedTime()
    local tbCurrentWeapon = self:GetCurrentWeapon()
    if(tbCurrentWeapon) then
        return tbCurrentWeapon:GetCurrentStateElapsedTime()
    else
        return nil
    end
end

function HumanWeaponComponentNew_C:GetCurrentState()
    if not self.StateHelper then
        return HumanWeaponStateDef.UNHOLDED
    end
    return self.StateHelper:GetCurrentState()
end

function HumanWeaponComponentNew_C:IsAttackPendingFinished(bIncludeCancel)
    return self.AttackHelper:IsPendingFinished(bIncludeCancel)
end

function HumanWeaponComponentNew_C:StartAttack()
    self.bInAttacking = true
    if(not self.bHasAuthority or self:CanChangeState(HumanWeaponStateDef.ATTACKING)) then
        return self.StateHelper:ChangeState(HumanWeaponStateDef.ATTACKING, false)
    end
    return false
end

function HumanWeaponComponentNew_C:Reload(nTime)
    if self.bIsDying then
        return false
    end
    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    if HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.Jumping_SpeelWall then
        return
    end
    if(not self.bHasAuthority or self:CanChangeState(HumanWeaponStateDef.RELOADING)) then
        return self.StateHelper:ChangeState(HumanWeaponStateDef.RELOADING, false)
    end

    return false
end

function HumanWeaponComponentNew_C:CancelReload()
    HumanWeaponComponentNew_C.super.CancelReload(self)
    if(self:GetCurrentState() == HumanWeaponStateDef.RELOADING) then
        if self:CanChangeState(HumanWeaponStateDef.HOLDED) then
            self.StateHelper:ChangeState(HumanWeaponStateDef.HOLDED, true)
        end
    end
end

function HumanWeaponComponentNew_C:FinishAttack()
    self.bInAttacking = false
    if(self:GetCurrentState() == HumanWeaponStateDef.ATTACKING) then
        self.AttackHelper:FinishAttack()
    end
end

function HumanWeaponComponentNew_C:CancelAttack()
    self.bInAttacking = false
    if(self:GetCurrentState() == HumanWeaponStateDef.ATTACKING) then
        self.AttackHelper:CancelAttack()
    end
end


function HumanWeaponComponentNew_C:StopCurrentMontage(szAnimKey)
    if not szAnimKey then
        return
    end
    -- local pMontage = self:GetMontageWithAnimKey(szAnimKey)
    -- if(pMontage == nil) then
    --     return 0
    -- end
    -- self.Owner.pUEActor:StopAnimMontage(pMontage)
    SelfAnimationHelper:StopHumanAnimation(self.Owner, szAnimKey)
end

function HumanWeaponComponentNew_C:CreateDispersionTimer(nTime)
    if(nTime <= 0) then
        return
    end

    local DispersionTimer = self.DispersionTimer
    if(DispersionTimer == nil) then
        DispersionTimer = Timer.NewTimer(function()
            self.DispersionTimer = nil
        end, nTime, false)
        self.DispersionTimer = DispersionTimer
    else
        DispersionTimer:Restart(nTime, false)
    end
    return DispersionTimer
end

function HumanWeaponComponentNew_C:DestroyDispersionTimer()
local DispersionTimer = self.DispersionTimer
    if(DispersionTimer) then
        DispersionTimer:Clear()
        self.DispersionTimer = nil
    end
end

function HumanWeaponComponentNew_C:IsInDispersion()
    return self.DispersionTimer ~= nil
end

function HumanWeaponComponentNew_C:CanChangeAim(bNewAim)
    local nCurrentState = self:GetCurrentState()

    if self:IsAiming() == bNewAim then
        return false
    end
    -- 无武器不允许
    if(self:HasNoWeapon()) then
        return false
    end

    -- 换枪以及Reloading时不允许改变瞄准状态
    if(nCurrentState == HumanWeaponStateDef.UNHOLDING
        or nCurrentState == HumanWeaponStateDef.HOLDING
        --or nCurrentState == HumanWeaponStateDef.RELOADING
    ) then
        return false
    end

    if(bNewAim) then
        if(nCurrentState == HumanWeaponStateDef.ATTACKING) then
            --主要针对弩箭连发 连发有个过程， 此时不能点开镜
            return false
        end
    end

    --趴下移动 不能瞄准
    local MovementComponent = self.Owner.HumanMovementStateComponent
    if MovementComponent then
        if (not MovementComponent:CanChangeAimInMovement()) and bNewAim then
            return false
        end

        local nMovementState = MovementComponent:GetCurrentState()
        if nMovementState == HumanMovementStateType.Jumping_SpeelWall and bNewAim then
            return false
        end

        if nMovementState == HumanMovementStateType.Crawl_State and bNewAim then
            local tbCurrentWeapon = self:GetCurrentWeapon(true)
            if tbCurrentWeapon and
                HumanWeaponHelper.GetWeaponCategory(tbCurrentWeapon.nTemplateId) == HumanWeaponDef.WeaponCategory.Bow then
                return false
            end
        end
    end

    if self.bIsDying and bNewAim then
        return false
    end

    return true
end

function HumanWeaponComponentNew_C:SetAim(bNewAim)
    if(not self:CanChangeAim(bNewAim)) then
        return false
    end

    return HumanWeaponComponentNew_C.super.SetAim(self, bNewAim)
end

function HumanWeaponComponentNew_C:IsAttacking()
    if self.bPlayerSelf then
        return self:GetCurrentState() == HumanWeaponStateDef.ATTACKING
    else
        return self.bInAttacking
    end
end

-- 当state能改weapon时在改
function HumanWeaponComponentNew_C:SetPendingCurrentWeapon(nInstanceId)
    LOG_DEBUG(self, "SetPendingCurrentWeapon", nInstanceId)
    if self.bIsDying then
        return
    end

    if self.nCurrentWeapon == nInstanceId then 
        return
    end 

    self.nPendingCurrentWeapon = nInstanceId
end

function HumanWeaponComponentNew_C:CanChangeWeapon(nInstanceId)
    if nInstanceId ~= NO_WEAPON and self.Owner:IsDead() then 
        return 
    end
    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    if not HumanMovementStateComponent then
        return false
    end
    if self.bPlayerSelf and self.nCurrentWeapon == nInstanceId then 
        return false
    end 
    local MovementState = HumanMovementStateComponent:GetCurrentState()
    if MovementState == HumanMovementStateType.Dying_State or MovementState == HumanMovementStateType.Jumping_SpeelWall
        or HumanMovementStateComponent:IsInVehicle() then
        return false
    end
    if nInstanceId < 0 then
        nInstanceId = nInstanceId * -1
    end
    if nInstanceId ~= NO_WEAPON and not self:FindWeaponById(nInstanceId) then
        return false
    end

    local nState = self:GetCurrentState()
    return nState ~= HumanWeaponStateDef.UNHOLDING
        and nState ~= HumanWeaponStateDef.HOLDING
        -- and nState ~= HumanWeaponStateDef.RELOADING
        and nState ~= HumanWeaponStateDef.ATTACKING
end

function HumanWeaponComponentNew_C:GetLuaToBPState()
    return LUA_TO_BP_STATE
end

local function IsCrawlState(self)
    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    local nMovementState = HumanMovementStateComponent:GetCurrentState()
    return nMovementState == HumanMovementStateType.Crawl_State
end

local function IsInVehicle(self)
    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    return HumanMovementStateComponent:IsInVehicle()
end

function HumanWeaponComponentNew_C:CanChangeState(nNewState)
    local StateHelper = self.StateHelper
    local nCurrentState = StateHelper:GetCurrentState()
    local tbCurrentWeapon = self:GetCurrentWeapon(true)

    if not tbCurrentWeapon then 
        return false
    end 
    
    local nCurrentWeapon = tbCurrentWeapon.nInstanceId

    if(nCurrentState == HumanWeaponStateDef.UNHOLDING
        or nCurrentState == HumanWeaponStateDef.HOLDING) then
        -- 换枪过程中无法做任何事
        return false
    end

    if nCurrentState == nNewState then
        return false
    end

    if(nCurrentWeapon == NO_WEAPON) then
        if(nNewState == HumanWeaponStateDef.HOLDED
            or nNewState == HumanWeaponStateDef.HOLDING
            or nNewState == HumanWeaponStateDef.RELOADING
            -- or nNewState == HumanWeaponStateDef.AIMING
            -- or nNewState == HumanWeaponStateDef.ATTACKING -- 可空手攻击
            or nNewState == HumanWeaponStateDef.UNHOLDING) then
            -- 没武器的时候好多状态都切不了
            return false
        end
    end

    if(nNewState == HumanWeaponStateDef.ATTACKING) then
        if(InAttackCD(self)) then
            -- 在攻击CD中无法在进入攻击状态
            return false
        elseif(nCurrentState == HumanWeaponStateDef.UNHOLDED or
            nCurrentState == HumanWeaponStateDef.NONE) then
            -- 空手状态可以攻击，所以这里不做处理
            if(IsCrawlState(self)) then
                UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CURRENT_STATE_CANNOT_ATTACK"))
                return false
            end
        elseif(not self:IsAiming() and
            nCurrentState ~= HumanWeaponStateDef.HOLDED) then
            -- 只允许瞄准、腰射状态进行攻击
            return false
        elseif self.bPendingHoldThrowWeapon then
            return false
        else
            if(tbCurrentWeapon:IsType(HumanWeaponType.MELEE)) then
                if(IsCrawlState(self)) then
                    -- 趴着近战打不了
                    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CURRENT_STATE_CANNOT_ATTACK"))
                    return false
                end
            elseif(tbCurrentWeapon:IsType(HumanWeaponType.GUN)) then
                local nCategory = HumanWeaponHelper.GetWeaponCategory(tbCurrentWeapon.nTemplateId)
                if (nCategory == HumanWeaponDef.WeaponCategory.Bow or nCategory == HumanWeaponDef.WeaponCategory.Wand)
                and IsCrawlState(self) then
                    -- 弓趴着打不了
                    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CURRENT_STATE_CANNOT_ATTACK"))
                    return false
                end
                local nRemainAmmo, _ = tbCurrentWeapon:GetAmmoInfo()
                if(nRemainAmmo == 0) then
                    -- 没子弹不允许发
                    return false
                end
                if tbCurrentWeapon.bWaitingReloadResult then
                    -- 换弹中不许发
                    return false
                end
            end
        end
    elseif(nNewState == HumanWeaponStateDef.UNHOLDING)  then
        if(nCurrentState == HumanWeaponStateDef.ATTACKING) then
            -- ATTACKING 不允许 切换到 UNHOLDING 防止手雷仍出去后还没删除时报错
            return false
        end
    elseif(nNewState == HumanWeaponStateDef.RELOADING) then
        -- local CurrentWeaponItem = OwnerComponent:GetCurrentWeaponItem()
        -- if CurrentWeaponItem == nil then
        --     return false
        -- end

        -- if CurrentWeaponItem:IsInitialItem() then
        --     return false
        -- end
        --重伤和死亡后不可以换弹
        if not self.Owner:IsAlive() then
            return false
        end

        if(not tbCurrentWeapon:IsType(HumanWeaponType.GUN)) then
            -- 只有枪可以reload
            return false
        end

        if(tbCurrentWeapon:GetProperty().nDecreaseBulletCount <= 0) then
            return
        end        

        if(tbCurrentWeapon:IsWaitingReloadResult()) then
            log("Can't Reload In WaitingReload")
            return false
        end

        if IsInVehicle(self) then
            log("Can't Reload IsInVehicle")
            return false
        end
        if BattlePickupSystem:IsPickingUp() then
            log("Can't Reload IsPickingUp")
            return false
        end
        local ProgressBarComponent = self.Owner.ProgressBarComponent
        if ProgressBarComponent:IsInProgress() then 
            log("Can't Reload IsInProgress")
            return false 
        end 
        local nCurrentAmmo, nMaxAmmo = tbCurrentWeapon:GetAmmoInfo()
        if(nCurrentAmmo >= nMaxAmmo) then
            -- 子弹满了不允许reload
            log("Can't Reload nCurrentAmmo >= nMaxAmmo")
            return false
        else
            if(not HumanWeaponHelper.IsBulletInfinite() and HumanWeaponHelper.GetUnequipedAmmoCount(nCurrentWeapon) == 0) then
                -- 没子弹不许reload
                log("Can't Reload IsBulletInfinite")
                return false
            end
        end
    end

    return true
end

function HumanWeaponComponentNew_C:IsUnmovedWeaponState()
    local CurrentState = self:GetCurrentState()
    local tbCurrentWeapon = self:GetCurrentWeapon(true)
    local bThrowWeapon = tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.THROW) or false
    local notThrowItemAttacking = not bThrowWeapon and CurrentState == HumanWeaponStateDef.ATTACKING
    if CurrentState == HumanWeaponStateDef.RELOADING or
        notThrowItemAttacking then
        return true
    end
    return false
end

function HumanWeaponComponentNew_C:IsTryToHoldSameThrowWeapon(nInstanceId)
    local tbCurrentWeapon = self:GetCurrentWeapon(true)
    if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.THROW)
        and tbCurrentWeapon.nInstanceId == nInstanceId then
        self.bPendingHoldThrowWeapon = false
        return true
    end
    return false
end

function HumanWeaponComponentNew_C:SetIsHighThrow(bHigh)
    self.bHighThrow = bHigh
end

function HumanWeaponComponentNew_C:IsLastHighThrow()
    return self.bHighThrow
end

function HumanWeaponComponentNew_C:DeactiveLastRun()
    if self.bLastRun then
        self.bLastRun = false
    end
end

function HumanWeaponComponentNew_C:ChangeState(nNewState)
    self.StateHelper:ChangeState(nNewState)
end

return HumanWeaponComponentNew_C