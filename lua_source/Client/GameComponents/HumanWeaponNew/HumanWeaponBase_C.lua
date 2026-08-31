local luaclass = require("luaclass")
local HumanWeaponBase =  require("HumanWeaponBase")
local HumanWeaponBase_C = luaclass("HumanWeaponBase_C", HumanWeaponBase)

local HumanWeaponHelper = require("HumanWeaponHelper")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
-- local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanMovementStateType = require("HumanMovementStateType")
local SelfAnimationHelper = require("SelfAnimationHelper")
local Timer = require("Timer")
local HumanWeaponMisc = require("HumanWeaponMisc")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local PropName = require("PropName")
local AnimDef = require("AnimDef")
local HumanWeaponAnimationDataTable = require("HumanWeaponAnimationDataTable")

local DELAY_HOLD_TIMER = "DelayHoldTimer"
local STATE_UNHOLDED    = HumanWeaponStateDef.UNHOLDED
local STATE_UNHOLDING   = HumanWeaponStateDef.UNHOLDING
--local STATE_HOLDED      = HumanWeaponStateDef.HOLDED
local STATE_HOLDING     = HumanWeaponStateDef.HOLDING
local STATE_RELOADING   = HumanWeaponStateDef.RELOADING
local STATE_HOLDED      = HumanWeaponStateDef.HOLDED
--local STATE_ATTACKING   = HumanWeaponStateDef.ATTACKING
local AttackSubState = HumanWeaponMisc.AttackSubState
local IDENTITY_TRANSFORM = Transform()
local EMPTY_HAND_TEMPLATE_ID = 1

HumanWeaponBase_C.pWeaponActor = nil
HumanWeaponBase_C.nState = nil
HumanWeaponBase_C.nCurrentStateElapsedTime = nil
HumanWeaponBase_C.bAttachedToHand = false
HumanWeaponBase_C.bSelf = false
HumanWeaponBase_C.nCurrentAttackSubState = AttackSubState.IDLE

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

local function SetWeaponAnimationKey(self, bHold)
    local nArmorId = GetHumanArmorId(self)
    local nTemplateId = self.nTemplateId 
    if not bHold then 
        nTemplateId = EMPTY_HAND_TEMPLATE_ID
    end
    local szWeaponAnim = HumanWeaponAnimationDataTable:GetWeaponAnim(nTemplateId, nArmorId)
    self.pOwnerActor:SetWeaponAnimName(szWeaponAnim)
end

function HumanWeaponBase_C:CreateWeaponActor()
    local nTemplateId = self.nTemplateId
    if(nTemplateId == 0) then
        return
    end
    local pClass = HumanWeaponHelper.GetWeaponResClass(self.nTemplateId)
    assert(pClass)
    local pWeaponActor = EngineExtActorShell.SpawnActorForScript(GWorld, pClass, IDENTITY_TRANSFORM, nil)
    if(pWeaponActor == nil) then
        return
    end
    pWeaponActor:SetActorHiddenInGame(false)
    -- pWeaponActor.MyPawn = self.pOwnerActor
    pWeaponActor:SetMyPawn(self.pOwnerActor)
    self.pWeaponActor = pWeaponActor
    self.Owner.DelegateComponent.OnHumanWeaponActorCreated:Fire(self.nInstanceId)
end

function HumanWeaponBase_C:DestroyWeaponActor()
    local pWeaponActor = self.pWeaponActor
    self.pWeaponActor = nil
    if(isvalidhandle(pWeaponActor)) then
        EngineExtActorShell.DestroyActor(GWorld, pWeaponActor, false)
    end
end

function HumanWeaponBase_C:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponBase_C.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)

    self.bSelf = self.Owner.ObjectType == GameObjectTypeDef.PlayerSelf

    if(nTemplateId ~= nil) then
        self:CreateWeaponActor()
        self:UpdateAttachState(true)
    end
end

function HumanWeaponBase_C:OnDestroyed()
    if self.nState ~= STATE_UNHOLDED then 
        self.nState = STATE_UNHOLDED
        self:UpdateAttachState(true)
    end
    Timer.StopOwnerTimer(self, DELAY_HOLD_TIMER)
    self:DestroyWeaponActor()
    HumanWeaponBase_C.super.OnDestroyed(self)
end

function HumanWeaponBase_C:OnStateActivate(nState)
    self.nState = nState
    Timer.StopOwnerTimer(self, DELAY_HOLD_TIMER)

    if self.bSelf or self.pOwnerActor:WasRecentlyRendered(0.2) then 
        local nElasedTime, nAttachTime = self:PlayMontageInState(nState)
        self.nCurrentStateElapsedTime = nElasedTime
        Timer.StartOwnerTimer(self, DELAY_HOLD_TIMER, function()
            self:UpdateAttachState()
        end, nAttachTime, false)
    else 
        local tbBPInfo = self.tbBPInfo
        local szAnimKey = nil 
        if(nState == STATE_UNHOLDING) then
            szAnimKey = tbBPInfo.szUnholdedAnimKey
        elseif(nState == STATE_HOLDING) then
            szAnimKey = tbBPInfo.szHoldedAnimKey
        elseif(nState == STATE_RELOADING) then
            szAnimKey = tbBPInfo.szReloadAnimKey
        end

        if(szAnimKey == nil) then
            self.nCurrentStateElapsedTime = nil
        else 
            self.nCurrentStateElapsedTime = 0
        end

        self:UpdateAttachState()
    end

    --- 提前刷一下newplayer的weaponactor
    local pOwnerActor = self.pOwnerActor
    if not pOwnerActor then
        return
    end

    if(nState == STATE_HOLDING or nState == STATE_HOLDED) then
        pOwnerActor.CurrentWeaponActor =  self.pWeaponActor
    elseif(nState == STATE_UNHOLDED) then
        if pOwnerActor.CurrentWeaponActor == self.pWeaponActor then  
            pOwnerActor.CurrentWeaponActor =  nil 
        end
    end
end

function HumanWeaponBase_C:OnStateDeactivate(nState, bCancel)
    --self.nState = nil
    if bCancel then  
        self:StopMontage(nState)
    end 
    self.nCurrentStateElapsedTime = nil
end

function HumanWeaponBase_C:OnAimChanged(bAiming)
    -- HumanWeaponBase_C.super.OnAimChanged(self, bAiming)

    -- TODO: 做动作？
end

function HumanWeaponBase_C:GetCurrentStateElapsedTime()
    if self.nState and self.nState == HumanWeaponStateDef.RELOADING then
        -- GM指令作弊用
        if GlobalVariableSystem.nReloadCDTime >= 0 then
            return GlobalVariableSystem.nReloadCDTime
        end
    end
    return self.nCurrentStateElapsedTime
end

function HumanWeaponBase_C:GetBPInfo()
    return self.tbBPInfo
end

function HumanWeaponBase_C:OnWeaponAttached(bNewAttached)
    
end


function HumanWeaponBase_C:UpdateAttachState(bForce)
    local nState = self.nState
    local bNewAttachedToHand = nState ~= nil
        and (nState ~= STATE_UNHOLDED and nState ~= STATE_UNHOLDING)
    if(not bForce and self.bAttachedToHand == bNewAttachedToHand) then
        return false
    end
    local bAttachedToHandLast = self.bAttachedToHand

    self.bAttachedToHand = bNewAttachedToHand

    if(self.pWeaponActor == nil) then
        return false
    end

    local szSocketName
    local pOwnerActor = self.pOwnerActor
    if not pOwnerActor then
        return false
    end
    Timer.StopOwnerTimer(self, DELAY_HOLD_TIMER)
    -- local tbBPInfo = self.tbBPInfo
    if(bNewAttachedToHand) then
        -- szSocketName = pOwnerActor[self:GetHoldSocketName()]
        szSocketName = self:GetHoldSocketName()
        if bForce then 
            pOwnerActor.CurrentWeaponActor =  self.pWeaponActor
        end
    else
        -- szSocketName = pOwnerActor[self:GetUnholdSocketName()]
        szSocketName = self:GetUnholdSocketName()
        if bForce and pOwnerActor.CurrentWeaponActor == self.pWeaponActor then  
            pOwnerActor.CurrentWeaponActor =  nil 
        end
    end
    self.pWeaponActor:K2_AttachToComponent(pOwnerActor.Mesh, szSocketName, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, false)
    self.pOwnerActor.ConcealComponent:UpdatePrimitiveAlpha()
    if bAttachedToHandLast or bNewAttachedToHand then 
        SetWeaponAnimationKey(self, bNewAttachedToHand)
    end
    if bNewAttachedToHand then 
        self.pWeaponActor:OnHold()
    else 
        self.pWeaponActor:OnUnHold()
    end 
    self:OnWeaponAttached(bNewAttachedToHand)
    return true
end

function HumanWeaponBase_C:PlayMontageInState(nState)
    local szAnimKey
    local tbBPInfo = self.tbBPInfo
    local nTime = 0
    local PlayRate = 1
    if(nState == STATE_UNHOLDING) then
        szAnimKey = tbBPInfo.szUnholdedAnimKey
        nTime = 0.3
    elseif(nState == STATE_HOLDING) then
        szAnimKey = tbBPInfo.szHoldedAnimKey
    elseif(nState == STATE_RELOADING) then
        szAnimKey = tbBPInfo.szReloadAnimKey
        PlayRate = self:GetOwnerProperty(PropName.nReloadCoefficient)
    end
    if(szAnimKey == nil) then
        return nil
    end
    local nAnimrationTime, pMontage= self.OwnerComponent:PlayMontageWithAnimKey(szAnimKey, PlayRate)
    nAnimrationTime = nAnimrationTime/ PlayRate
    local nAttachTime = 0
    if pMontage then 
        if(nState == STATE_HOLDING or nState == STATE_UNHOLDING) then
            nAttachTime = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, AnimDef.SectionName.ATTACH_SECTION_KEY) 
        end
    end 

    if nAnimrationTime > nTime then 
        return (nAnimrationTime - nTime), nAttachTime
    else 
        return 0, nAttachTime
    end
end

function HumanWeaponBase_C:StopMontage(nState)
    local szAnimKey
    local tbBPInfo = self.tbBPInfo
    if(nState == STATE_UNHOLDING) then
        szAnimKey = tbBPInfo.szUnholdedAnimKey
    elseif(nState == STATE_HOLDING) then
        szAnimKey = tbBPInfo.szHoldedAnimKey
    elseif(nState == STATE_RELOADING) then
        szAnimKey = tbBPInfo.szReloadAnimKey
    end
    if(szAnimKey == nil) then
        return nil
    end

    self.OwnerComponent:StopCurrentMontage(szAnimKey)

    -- 这里有可能要停掉武器的动作
end

function HumanWeaponBase_C:AddAttackSubState(tbAttackInfo, tbSubStateInfo)
    local nStateCount = tbAttackInfo.nStateCount
    if(nStateCount == nil) then
        nStateCount = 1
    else
        nStateCount = nStateCount + 1
    end
    tbAttackInfo[nStateCount] = tbSubStateInfo
    tbAttackInfo.nStateCount = nStateCount
end

-- 生成attackinfo
function HumanWeaponBase_C:GenerateAttackInfo()
--[[
    函数AddSubState参数：
    tbAttackInfo  = {
        nCD = float,                -- 可选，下次在进入Attacking状态所需要的时间
        nExitTypeWhenFinish,        -- 可选，当外部finish时如何退出Attacking状态，type定义参考HumanWeaponAttackHelper.ExitType
        nAllLoopCount,              -- 可选，所有子状态的循环次数，-1无限循环，>0则会循环指定次数，注意：此变量会在子状态都执行完后进行修改
    },
    tbSubStateInfo = {
        OnActivate,                 -- 可选，状态激活时触发
        OnDeactivate,               -- 可选，状态结束时触发
        nDuration,                  -- 可选，状态持续时间，小于0或者nil时状态不会停止，等于0时状态激活后立即结束
        bCanDeactivateExternally,   -- 可选，当外部finish时可以deactivate当前子状态
    },

    OnFinished(tbWeapon, bCancel) 结束时会回掉回来
]]
    return nil
end

function HumanWeaponBase_C:GetWeaponBPType()
    return self.tbBPInfo.nBPType
end 

function HumanWeaponBase_C:GetHoldSocketName()
    local szSocket = HumanWeaponHelper.GetWeaponHoldSocket(self.Owner, self.nTemplateId, self.nSlot)
    if szSocket ~= nil then 
        return szSocket
    end 
    return self.pOwnerActor[self.tbBPInfo.szHoldedSocket]
    -- return self.tbBPInfo.szHoldedSocket
end 

function HumanWeaponBase_C:GetUnholdSocketName()
    local szSocket = HumanWeaponHelper.GetWeaponUnHoldSocket(self.nTemplateId, self.nSlot)
    if szSocket ~= nil then 
        return szSocket
    end     
    return self.pOwnerActor[self.tbBPInfo.szUnholdedSocket]
    -- return self.tbBPInfo.szUnholdedSocket
end 

function HumanWeaponBase_C:OnRepAttackSubState(nState)
    -- 用于更新其他人的AttackSubState
end

function HumanWeaponBase_C:PlayHitAnimation(tbTaker)
    if not tbTaker or (GameObjectSystem:IsCharacter(tbTaker) and tbTaker:IsShip()) then
        return
    end

    if self.Owner.ObjectType ~= GameObjectTypeDef.PlayerSelf or tbTaker.ObjectType ==  GameObjectTypeDef.PlayerSelf then
        return
    end
    if self.Owner.nServerInstanceId == tbTaker.nServerInstanceId  then
        return
    end

    local HumanMovementStateComponent = tbTaker.HumanMovementStateComponent
    if not HumanMovementStateComponent or HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.Dying_State or tbTaker.pUEActor:IsPlayingRootMotion() then
        return
    end

    if HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.Crawl_State then
        SelfAnimationHelper:PlayHumanAnimation(tbTaker, SelfAnimationHelper.AnimDef.ON_HIT_CRAWL)
        log("[HitAnim] HumanWeaponBase_C:PlayHitAnimation ON_HIT_CRAWL Taker:", tbTaker:GetName())
    else
        local Direction = tbTaker.pUEActor:GetDirectionFromActor(self.Owner.pUEActor)
        if Direction >= -45 and Direction <= 45 then  -- Forward
            SelfAnimationHelper:PlayHumanAnimation(tbTaker, SelfAnimationHelper.AnimDef.ON_HIT_FORWARD)
            log("[HitAnim] HumanWeaponBase_C:PlayHitAnimation Forward Taker:", tbTaker:GetName())
        elseif Direction >= 145 or Direction <= -145 then -- Back
            SelfAnimationHelper:PlayHumanAnimation(tbTaker, SelfAnimationHelper.AnimDef.ON_HIT_BACK)
            log("[HitAnim] HumanWeaponBase_C:PlayHitAnimation Back Taker:", tbTaker:GetName())
        elseif Direction <-45 and Direction >-145 then  --Left
            SelfAnimationHelper:PlayHumanAnimation(tbTaker, SelfAnimationHelper.AnimDef.ON_HIT_LEFT)
            log("[HitAnim] HumanWeaponBase_C:PlayHitAnimation Left Taker:", tbTaker:GetName())
        else --Right
            SelfAnimationHelper:PlayHumanAnimation(tbTaker, SelfAnimationHelper.AnimDef.ON_HIT_RIGHT)
            log("[HitAnim] HumanWeaponBase_C:PlayHitAnimation Right Taker:", tbTaker:GetName())
        end
    end
end

return HumanWeaponBase_C