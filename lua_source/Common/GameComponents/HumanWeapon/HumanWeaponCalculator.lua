local HumanWeaponCalculator = {}

local MathUtil = require("MathUtil")
local HumanMovementStateType = require("HumanMovementStateType")
local PropName = require("PropName")

local RandomFloat = MathUtil.RandomFloat
local RecoilTargetAngle = Vector()
local RecoilRecoverAngle = Vector()
local RecoilPosOffset = Vector()

local SpreadAngle = Vector2D()
local NormalDistributionRandom = ExtendBlueprintFunctions.NormalDistributionRandom
local VSizeSquared = KismetMathLibrary.VSizeSquared

local function RandomNegative()
    return KismetMathLibrary.RandomBool() and 1 or -1
end


---------------------------------------------------------------------
-- 计算散布惩罚
HumanWeaponCalculator.SpreadEnum = {
    POSE_CROUCH = 1,
    POSE_CRAWL  = 2,
    POSE_STAND  = 3,
    MOVE_JUMP   = 4,
    MOVE_RUN    = 5,
    MOVE_STAY   = 6,
}

local SpreadEnum = HumanWeaponCalculator.SpreadEnum
function HumanWeaponCalculator.CalculateSpreadWithParams(OwnerObject, tbWeaponProperty, nPos, nMoveType, bFirstAttack, bInAming)
    assert(OwnerObject and tbWeaponProperty)
    assert(isvalidhandle(OwnerObject.pUEActor))

    local nPosPunishment    -- 姿势惩罚
    local nMovePunishment   -- 移动惩罚
    local nnWeaponPunishment -- 武器惩罚

    if(nPos == SpreadEnum.POSE_CROUCH) then
        -- 姿势：蹲
        nPosPunishment = tbWeaponProperty.nDispersionPublishSquat
    elseif(nPos == SpreadEnum.POSE_CRAWL) then
        -- 姿势：卧倒
        nPosPunishment = tbWeaponProperty.nDispersionPublishProne
    else
        -- 姿势：站立
        nPosPunishment = tbWeaponProperty.nDispersionPublishStand
    end

    if(nMoveType == SpreadEnum.MOVE_JUMP) then
        -- 移动：跳跃
        nMovePunishment = tbWeaponProperty.nDispersionPublishJump
    elseif(nMoveType == SpreadEnum.MOVE_RUN) then
        -- 移动：移动
        nMovePunishment = tbWeaponProperty.nDispersionPublishWalk
    else
        -- 移动：静止
        nMovePunishment = 1
    end

    if(bFirstAttack) then
        -- 第一枪
        if(bInAming) then
            nnWeaponPunishment = tbWeaponProperty.nDispersionPublishSightAim
        else
            nnWeaponPunishment = tbWeaponProperty.nDispersionPublishNormalAim
        end
    else
        -- 在散射恢复过程中
        if(bInAming) then
            nnWeaponPunishment = tbWeaponProperty.nDispersionPublishSightFire * tbWeaponProperty.nDispersionPublishSightAim
        else
            nnWeaponPunishment = tbWeaponProperty.nDispersionPublishNormalFire
        end
    end
    -- 最终散步值
    return tbWeaponProperty.nDispersion * nPosPunishment * nMovePunishment * nnWeaponPunishment
end

function HumanWeaponCalculator.GetOnwerPosAndMoveType(OwnerObject)
    assert(OwnerObject)
    assert(isvalidhandle(OwnerObject.pUEActor))

    local nPos          -- 姿势
    local nMoveType     -- 移动

    local nMovementState = OwnerObject.HumanMovementStateComponent:GetCurrentState()
    if(nMovementState == HumanMovementStateType.Crouch_State) then
        -- 姿势：蹲
        nPos = SpreadEnum.POSE_CROUCH
    elseif(nMovementState == HumanMovementStateType.Crawl_State) then
        -- 姿势：卧倒
        nPos = SpreadEnum.POSE_CRAWL
    else
        -- 姿势：站立
        nPos = SpreadEnum.POSE_STAND
    end

    local pMovementComponent = OwnerObject.pUEActor:GetMovementComponent()
    assert(pMovementComponent)
    local nSpeed = VSizeSquared(OwnerObject.pUEActor:GetVelocity())
    if(pMovementComponent:IsFalling()) then
        -- 移动：跳跃
        nMoveType = SpreadEnum.MOVE_JUMP
    elseif(nSpeed > 0) then
        -- 移动：移动
        nMoveType = SpreadEnum.MOVE_RUN
    else
        -- 移动：静止
        nMoveType = SpreadEnum.MOVE_STAY
    end
    return nPos, nMoveType
end

function HumanWeaponCalculator.CalculateSpread(OwnerObject, tbWeaponProperty)
    local WeaponComponent = OwnerObject.HumanWeaponComponent
    assert(WeaponComponent)

    local nPos, nMoveType = HumanWeaponCalculator.GetOnwerPosAndMoveType(OwnerObject)
    return HumanWeaponCalculator.CalculateSpreadWithParams(OwnerObject, tbWeaponProperty,
        nPos, nMoveType, not WeaponComponent:IsInDispersion(), WeaponComponent:IsAiming())
end

-- 计算散步角度
function HumanWeaponCalculator.CalculateSpreadAngle(OwnerObject, tbWeaponProperty, nMagnification)
    assert(OwnerObject and tbWeaponProperty)
    local nFinalSpread = HumanWeaponCalculator.CalculateSpread(OwnerObject, tbWeaponProperty)
    if nMagnification and nMagnification > 0 then 
        nFinalSpread = nFinalSpread * nMagnification
    end 
    -- local nSpreadStandardDeviation = tbWeaponProperty.nDispersionDeviation
    -- 水平
    SpreadAngle.X = NormalDistributionRandom(0, nFinalSpread)
        -- 垂直
        SpreadAngle.Y = NormalDistributionRandom(0, nFinalSpread) 
        
    if SpreadAngle.X > nFinalSpread then 
        SpreadAngle.X = nFinalSpread
    elseif SpreadAngle.X < -nFinalSpread then 
            SpreadAngle.X = -nFinalSpread        
    end  

    if SpreadAngle.Y > nFinalSpread then 
        SpreadAngle.Y = nFinalSpread
    elseif SpreadAngle.Y < -nFinalSpread then 
            SpreadAngle.Y = -nFinalSpread        
    end      

    log(string.format("SpreadValue [%f], XAngle [%f], YAngle [%f],", nFinalSpread, SpreadAngle.X, SpreadAngle.Y))
    return SpreadAngle
end

---------------------------------------------------------------------
-- 计算后坐力
function HumanWeaponCalculator.CaculateRecoil(OwnerObject, tbWeaponProperty, bAim)
    -- X: 水平，Y：垂直，Z：旋转

    local tbProp = tbWeaponProperty
    local nHMinPercent = bAim and tbProp.nRecoilHorizontalMinPercentAim or tbProp.nHorizontalMinPercent 
    local nHMaxPercent = bAim and tbProp.nRecoilHorizontalMaxPercentAim or tbProp.nHorizontalMaxPercent
    local nRecoilLowerAngle = bAim and tbProp.nRecoildLowerAngleAim or tbProp.nRecoildLowerAngle
    local nRecoilUpperAngle = bAim and tbProp.nRecoilUpperAngleAim or tbProp.nRecoilUpperAngle
    local nRecoildHUpperAngle = bAim and tbProp.nRecoildHUpperAngleAim or tbProp.nRecoildHUpperAngle
    local bUseRecoverInV = bAim and tbProp.bUseRecoverInVerticalAim or tbProp.bUseRecoverInVertical
    local RecoilMinYaw = bAim and tbProp.nRecoilMinYawAim or tbProp.nRecoilMinYaw
    local RecoilMaxYaw = bAim and tbProp.nRecoilMaxYawAim or tbProp.nRecoilMaxYaw
    local nRecoilDuration = bAim and tbProp.nRecoilDurationAim or tbProp.nRecoilDuration
    local nRecoilRecoverMinPercent = bAim and tbProp.nRecoilRecoverMinPercentAim or tbProp.nRecoilRecoverMinPercent
    local nRecoilRecoverMaxPercent = bAim and tbProp.nRecoilRecoverMaxPercentAim or tbProp.nRecoilRecoverMaxPercent

    -- 摇臂水平角度百分比  Z方向为相机自旋转
    local HorizonPercentage = RandomFloat(nHMinPercent, nHMaxPercent) / 100

    local XRandNegative = RandomNegative()
    local ZRandNegative = RandomNegative()
    -- 摇臂后座角度 Z方向为相机自旋转
    RecoilTargetAngle.Y = RandomFloat(nRecoilLowerAngle, nRecoilUpperAngle)
    RecoilTargetAngle.X = nRecoildHUpperAngle * HorizonPercentage * XRandNegative
    RecoilTargetAngle.Z = RandomFloat(RecoilMinYaw, RecoilMaxYaw) * ZRandNegative

    -- 后座力持续时间 
    local RecoilTargetTime = nRecoilDuration

    -- 摇臂恢复角度 Z方向为相机自旋转
    local RecoverPercentage = RandomFloat(nRecoilRecoverMinPercent, nRecoilRecoverMaxPercent) / 100
    --恢复角度与初始角度相反
    RecoilRecoverAngle.Y = -RecoilTargetAngle.Y * RecoverPercentage 
    RecoilRecoverAngle.X = -RecoilTargetAngle.X * RecoverPercentage
    RecoilRecoverAngle.Z = -RecoilTargetAngle.Z

    --X 相机向前方向位移， Y 水平方向位移  Z垂直方向位移
    RecoilPosOffset.X = 0
    RecoilPosOffset.Y = 0
    RecoilPosOffset.Z = 0

    local nAlphaExH = 1  
    local nAlphaExV = 1  
    if OwnerObject and OwnerObject.HumanBattlePropertyComponent then  
        nAlphaExH = OwnerObject.HumanBattlePropertyComponent:GetProp(PropName.nRecoilHorizontalRatio)
        nAlphaExV = OwnerObject.HumanBattlePropertyComponent:GetProp(PropName.nRecoilVerticalRatio)
    end

    RecoilTargetAngle.X = nAlphaExH * RecoilTargetAngle.X
    RecoilTargetAngle.Y = nAlphaExV * RecoilTargetAngle.Y

    RecoilRecoverAngle.X = nAlphaExH * RecoilRecoverAngle.X
    RecoilRecoverAngle.Y = nAlphaExV * RecoilRecoverAngle.Y

    return RecoilTargetTime, RecoilTargetAngle, RecoilRecoverAngle, RecoilPosOffset, bUseRecoverInV == 1
end

---------------------------------------------------------------------
-- 计算伤害
function HumanWeaponCalculator.CalculateDamage(tbTaker, tbCauserOwner, nActualDamage, pDamageCauser, pHitResult)
    -- TODO...
end

return HumanWeaponCalculator