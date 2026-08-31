local luaclass = require("luaclass")
local HumanWeaponBase = dynamic_require("HumanWeaponBase")
local HumanWeaponThrow = luaclass("HumanWeaponThrow", HumanWeaponBase)

local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponHelper = require("HumanWeaponHelper")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local HumanThrownItemDef = require("HumanThrownItemDef")
local Timer = require("Timer")

local SELF_TYPE = HumanWeaponMisc.Type.THROW
local EXPLODE_TIMER = "ExplodeTimer"
local RESET_TIMER = "ResetTimer"
local THROW_TIMER = "ThrowTimer"
local ABS = math.abs
local pTempLoc = Vector()
local pTempVec = Vector()
local pDefualtScale = Vector{X=1,Y=1,Z=1}
local GRAVITY = 1000
local CHEAT_THROW_DELAY = 0.15

local ThrownState = HumanWeaponMisc.ThrownState
local ThrownItemCategory = HumanThrownItemDef.ItemCategory
-- 靠正负号表明是low还是high
HumanWeaponThrow.rHumanThrownState = nil

local function ToLaunch(self, pStartLocation, pRotator, nRemainTime, pVelocity)
    local tbProperty = self:GetProperty()
    local pActor = EngineExtActorShell.SpawnActorForScript(GWorld,
        HumanWeaponHelper.GetWeaponLaunchClass(self.nTemplateId),
        KismetMathLibrary.MakeTransform(pStartLocation, pRotator, pDefualtScale),
        self.pOwnerActor)
    assert(pActor)

    local nBaseDamage = tbProperty.nDamage
    local nInnterRadius = tbProperty.nInnerRadius * 100
    local nOuterRadius = tbProperty.nOuterRadius * 100
    local nDamageFallOff = tbProperty.nDamageFallOff
    local nExplodeTime = nRemainTime
    local nBuffId = tbProperty.nBuffId
    local nGroundTime = tbProperty.nGroundLastTime

    if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) == ThrownItemCategory.Hit then  
        local tbWeaponCategoryProperty = tbProperty.tbWeaponCategoryProperty

        pActor.BodyDamageFactor = tbWeaponCategoryProperty.nBodyDamageFactor
        pActor.HeadDamageFactor = tbWeaponCategoryProperty.nHeadDamageFactor
        pActor.AllFoursDamageFactor = tbWeaponCategoryProperty.nAllFoursDamageFactor
        pActor.DecayFactor = 1
    end
    pActor.TemplateId = self.nTemplateId
    
    pActor:Launch(nExplodeTime, nBaseDamage, nInnterRadius, nBuffId, nOuterRadius, nDamageFallOff, nGroundTime, pVelocity)
end

function HumanWeaponThrow:SpawnActor(tbPos, nRemainTime)
    local tbProperty = self:GetProperty()
    local pComponent = self.pOwnerActor.ThrowComponent
    local pRotator = nil 

    pTempLoc.X = tbPos.X
    pTempLoc.Y = tbPos.Y
    pTempLoc.Z = tbPos.Z

    if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) ~= ThrownItemCategory.Hit then  
        pRotator = pComponent:GetStartRotation()
    else 
        pRotator = pComponent:GetThrowWeaponDir(pTempLoc, tbProperty.nThrowDistance)
    end 

    pTempVec.X = self:IsHighThrow() and tbProperty.nInitialSpeed * 100 or tbProperty.nInitialLowSpeed * 100
    pTempVec.Y = tbProperty.nGravityRate -- use y to save gravity rate
    pTempVec.Z = self:IsHighThrow() and tbProperty.nVerticleHighSpeed * 100 or tbProperty.nVerticleLowSpeed * 100

    ToLaunch(self, pTempLoc, pRotator, nRemainTime, pTempVec)
end

function HumanWeaponThrow:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponThrow.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)

    self.rHumanThrownState = OwnerComponent.rHumanThrownState
end

function HumanWeaponThrow:OnDestroyed()
    self:Reset()

    HumanWeaponThrow.super.OnDestroyed(self)
end

function HumanWeaponThrow:GetType()
    return SELF_TYPE
end

function HumanWeaponThrow:CreateWeaponProperty()
    self.tbProperty = HumanWeaponHelper.CreateThrownWeaponProperty(self.nTemplateId)
    return self.tbProperty
end

function HumanWeaponThrow:UpdateAttachments(tbAttachments)
    assert(false)
end

function HumanWeaponThrow:ConvertToState(bHigh, nState)
    return bHigh and nState or -nState
end

function HumanWeaponThrow:GetRepThrownState()
    return self.rHumanThrownState:Get()
end

function HumanWeaponThrow:SetRepThrownState(nState)
    self.rHumanThrownState:Set(nState)
    --logdebug("HumanWeaponThrow:SetRepThrownState", nState)
end

function HumanWeaponThrow:IsHighThrow()
    return self:GetRepThrownState() > 0
end

function HumanWeaponThrow:Reset()
    -- Timer.StopOwnerAllTimer(self, true)
    Timer.StopOwnerTimer(self, EXPLODE_TIMER)
    Timer.StopOwnerTimer(self, RESET_TIMER)
    if not self.bStantalone then 
        Timer.StopOwnerTimer(self, THROW_TIMER)
    end

    if(self.bServer and self.Owner.CustomReplicationComponent:IsValid()) then
        local nInstanceId = self.nInstanceId
        HumanWeaponHelper.SendThrowAllFinishedClient(self.Owner, nInstanceId)
        if not self.bStantalone then
            self.rHumanThrownState:Set(ThrownState.NONE)
        end
    end
end

function HumanWeaponThrow:OnReady(bHigh)
    if(ABS(self:GetRepThrownState()) == ThrownState.THROWED) then
        return
    end 

    if(self:IsThrowing()) then
        return
    end

    --logdebug("ServerReady", bHigh)
    self:SetRepThrownState(self:ConvertToState(bHigh, ThrownState.READY))
end

function HumanWeaponThrow:OnExplodeBegin()
    local tbProperty = self:GetProperty()
    if(tbProperty.nPreExplodeTime > 0) then
        Timer.StartOwnerTimer(self, EXPLODE_TIMER, self.OnExplodeTimeOut, tbProperty.nPreExplodeTime)
    end
end

function HumanWeaponThrow:OnExplodeTimeOut()
    self:OnThrow(nil, true, 0)
end

function HumanWeaponThrow:OnThrowFinished()
    Timer.StopOwnerTimer(self, THROW_TIMER)
    if self.bStantalone then 
        EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_STANDALONE_THROW_FINISHED, self.Owner, self)
    else  
        EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_THROW_FINISHED, self.Owner, self)
    end
end

function HumanWeaponThrow:BeginThrow()
    local nState = self:GetRepThrownState()
    if (ABS(nState) ~= ThrownState.READY) then
        return false
    end
    self:SetRepThrownState(self:ConvertToState(nState > 0, ThrownState.THROWED))
end

function HumanWeaponThrow:OnThrow(tbPos, bUseOwnerCurrentPos, nTime)

    --local nState = self:GetRepThrownState()
    -- if(ABS(nState) ~= ThrownState.READY) then
    --     return false
    -- end

    -- 如果bUseOwnerCurrentPos则直接炸在玩家位置
    local nRemainTime
    if(bUseOwnerCurrentPos) then
        tbPos = self.Owner:GetLocation()
        nRemainTime = 0
    else
        local ExplodeTimer = Timer.GetOwnerTimer(self, EXPLODE_TIMER)
        --self:SetRepThrownState(self:ConvertToState(nState > 0, ThrownState.THROWED))

        if(ExplodeTimer) then
            nRemainTime = ExplodeTimer:GetRemainingTime()
            Timer.StopOwnerTimer(self, EXPLODE_TIMER)
        else
            nRemainTime = -1
        end
    end
    self:SpawnActor(tbPos, nRemainTime)

    -- 一定要在setrepstate后removeitem
    if self.Owner and not self.Owner:IsDead() then
        HumanWeaponHelper.RemoveThrownItem(self.nInstanceId)
        HumanWeaponHelper.SendWeaponAmmoInfoToViewers(self.OwnerComponent, self.nInstanceId)
    end

    if(nTime ~= nil and nTime >= 0) then
        -- 延迟发事件，防止system过早删除投掷物
        Timer.StartOwnerTimer(self, THROW_TIMER, self.OnThrowFinished, nTime)
        --assert(self:IsThrowing())
    else
        nTime = 0
        self:OnThrowFinished()
    end

    --整个等Reset结束时间有点长，先去掉Rep时间试一下
    --Timer.StartOwnerTimer(self, RESET_TIMER, self.Reset, nTime)
    Timer.StartOwnerTimer(self, RESET_TIMER, self.Reset, nTime + self.REP_PROPERTY_CLEAR_TIME)
end

function HumanWeaponThrow:IsThrowing()
    return ABS(self:GetRepThrownState()) == ThrownState.THROWED
end

function HumanWeaponThrow:OnSetThrowType(bHigh)
    local nState = self:GetRepThrownState()
    if(ABS(nState) ~= ThrownState.READY) then
        -- 在服务器只有ready状态能切，客户端idle状态也能切，但不上行服务器
        return false
    end

    local nNewState = self:ConvertToState(bHigh, ThrownState.READY)
    if(nState == nNewState) then
        return true
    end

    self:SetRepThrownState(nNewState)
    return true
end

function HumanWeaponThrow:OnCancel()
    self:Reset()
end

-- 专门为服务器发起的攻击使用，多用于ai，如果未打中nDamageType请填nil
function HumanWeaponThrow:CheatAttack(Target, _, tbParam)
    assert(self.bServer)
    local pTargetPos = nil
    if tbParam then
        pTargetPos = tbParam.pLocation
    end
    if Target then
        pTargetPos = Target:K2_GetActorLocation()
    end
    assert(pTargetPos)
    --log("HumanWeaponThrow:CheatAttack pTargetPos:", pTargetPos.X, pTargetPos.Y, pTargetPos.Z)
    local pRotator = Rotator()
    local pComponent = self.pOwnerActor.ThrowComponent
    local tbProperty = self:GetProperty()
    -- logdebug("cd and pre duration and damage :", tbProperty.nCD, tbProperty.nPreExplodeTime, tbProperty.nDamage)
    -- local pStartPos = pComponent:GetStartLocation()
    local pStartPos = pComponent:GetNewThrowLocation()
    --log("HumanWeaponThrow:CheatAttack pStartPos:", pStartPos.X, pStartPos.Y, pStartPos.Z)
    if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) ~= ThrownItemCategory.Hit then  
        --投掷物
        local nVx = tbProperty.nInitialSpeed * 100

        pTempVec.X = pTargetPos.X - pStartPos.X
        pTempVec.Y = pTargetPos.Y - pStartPos.Y
        pTempVec.Z = 0

        local nDistance = KismetMathLibrary.VSizeXY(pTempVec)
        -- local nDistance = ExtendBlueprintFunctions.GetVectorToVectorDistance(pStartPos, pTargetPos)
        
        local nTime = nDistance / nVx
        local nVz =  0.5 * GRAVITY * nTime 
        
        pTempVec.X = nVx
        pTempVec.Y = tbProperty.nGravityRate
        pTempVec.Z = nVz

        pRotator = KismetMathLibrary.FindLookAtRotation(pStartPos, pTargetPos)
    else  
        --飞刀飞斧
        --pRotator = pComponent:GetThrowWeaponDir(pStartPos, tbProperty.nThrowDistance)
        pRotator = KismetMathLibrary.FindLookAtRotation(pStartPos, pTargetPos)
        pTempVec.X = tbProperty.nInitialSpeed * 100
        pTempVec.Y = 0
        pTempVec.Z = 0
    end
     -- use y to save gravity rate

    self:SetRepThrownState(ThrownState.THROWED)

    Timer.StartOwnerTimer(self, THROW_TIMER, function() 
        ToLaunch(self, pStartPos, pRotator, tbProperty.nPreExplodeTime, pTempVec)
        if self.Owner and not self.Owner:IsDead() then
            HumanWeaponHelper.RemoveThrownItem(self.nInstanceId)
            HumanWeaponHelper.SendWeaponAmmoInfoToViewers(self.OwnerComponent, self.nInstanceId)
        end
        destroyUserData(pRotator)
    end,  CHEAT_THROW_DELAY)
    
    Timer.StartOwnerTimer(self, RESET_TIMER, function() 
        self:OnThrowFinished()
        Timer.StopOwnerAllTimer(self, true)
        self.rHumanThrownState:Set(ThrownState.NONE)
    end, self.REP_PROPERTY_CLEAR_TIME + CHEAT_THROW_DELAY)
end

return HumanWeaponThrow