local luaclass = require("luaclass")
local HumanWeaponBase = dynamic_require("HumanWeaponBase")
local HumanWeaponMelee = luaclass("HumanWeaponMelee", HumanWeaponBase)

local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponMeleeDataTable = require("HumanWeaponMeleeDataTable")
local HumanWeaponHelper = require("HumanWeaponHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
-- local DamageTypeEx = require("DamageTypeEx")
local Timer = require("Timer")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local TakeDamage = require("HDC_HumanBulletNew")
local HumanBodyDef = require("HumanBodyDef")
local HumanMovementStateType = require("HumanMovementStateType")
local AIHelper = require("AIHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local PropName = require("PropName")
local IllegalType = require("HumanWeaponIllegalAttackType")
local AnimDef = require("AnimDef")

local REP_ATTACK_CLEAR_TIMER = "RepAttackClearTimer"
local REP_HIT_CLEAR_TIMER = "RepHitClearTimer"
local ATTACK_TIMER = "AttackTimer"
local CHEAT_ATTACK_TIMER = "CheatAttackTimer"
local DELAY_CLEAR_ANIMINDEX = "DelayClearAnimIndex"

local SELF_TYPE = HumanWeaponMisc.Type.MELEE
local EMPTY_HAND_TEMPLATE_ID = 1
local MONTAGE_POST_ATTACK_TIME = 3
local MAX_START_POS_DISTANCE = 1000

local tbMeleeHitData = {}
local tbSingleMeleeHits = {}

local REP_ROOTMOTION_MONTAGE_TIMER = "RepRootMotionMontageTimer"
local tbReasonFormatByType = {
    [IllegalType.NOT_IN_RANGE] = "Taker is not in the attackable range of attacker, angle = %f, distance = %f.",
    [IllegalType.INVALID_MELEE_START_POS] = "Melee start attack position is not valid, distance=%f, StartPos=(%f,%f,%f), CurPos=(%f,%f,%f)."
}


local TempTable = {}
local pTempVector1 = Vector()
local pTempRotator = Rotator()
local function CopyVector(Dest, From)
    Dest.X = From.X
    Dest.Y = From.Y
    Dest.Z = From.Z
end

local function VectorToTempTable(tbVector)
    CopyVector(TempTable, tbVector)
    return TempTable
end

local function TableToTempVector1(tbVector)
    CopyVector(pTempVector1, tbVector)
    return pTempVector1
end

local function NeedCheckHit(self, tbTaker)
    if(self.bClient) then
        return false
    end

    if AIHelper.IsAIControlled(self.Owner) then
        return false
    end

    if tbTaker and tbTaker.ObjectType == GameObjectTypeDef.DestructibleObject then
        return false
    end

    if tbTaker and (not GameObjectSystem:IsCharacter(tbTaker)) then
        return false
    end

    return true
end

-- 防止id一致时rep不下去

-- local ApplyDamage = HumanWeaponHelper.ApplyDamage

HumanWeaponMelee.bEmptyHand = false
HumanWeaponMelee.bChangeTakerId = false

HumanWeaponMelee.rHumanMeleeAttackRoute = nil
HumanWeaponMelee.rHumanMeleeAttackHits = nil

HumanWeaponMelee.LastMontageIndex = 0

HumanWeaponMelee.nRequestMontageIndex = 1 --记录客户端请求动作索引, 用于计算伤害

HumanWeaponMelee.tbCheatAttackList = {}
HumanWeaponMelee.tbCurrentMontageData = nil
HumanWeaponMelee.tbAttackDatas = {}

local function CheckValidStartPos(self, StartPos)
    if (not NeedCheckHit(self)) or (not StartPos) then
        return true
    end

    if StartPos.X == 0 and StartPos.Y == 0 and StartPos.Z == 0 then
        return true
    end
    
    local CurPos = self.Owner:GetLocation()

    local nDistance = KismetMathLibrary.Vector_Distance(TableToTempVector1(StartPos), CurPos)
    if nDistance > MAX_START_POS_DISTANCE then
        local nIllegalType = IllegalType.INVALID_MELEE_START_POS
        self:RecordIllegalAttack(nIllegalType, string.format(tbReasonFormatByType[nIllegalType], nDistance, StartPos.X, StartPos.Y, StartPos.Z, CurPos.X, CurPos.Y, CurPos.Z))
        return false
    end
    
    return true
end

function HumanWeaponMelee:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponMelee.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)

    if(nTemplateId == nil) then
        self.bEmptyHand = true
        self.nTemplateId = EMPTY_HAND_TEMPLATE_ID
    end

    self.rHumanMeleeAttackRoute = OwnerComponent.rHumanMeleeAttackRoute
    self.rHumanMeleeAttackHits = OwnerComponent.rHumanMeleeAttackHits

end

function HumanWeaponMelee:GetMeleeTemplate()
    local tbMelee = HumanWeaponMeleeDataTable:GetTemplate(self.nTemplateId, self:GetOwnerProperty(PropName.nCurrentArmorTemplateId))
    if tbMelee == nil then
        error("get melee template failed, template id = " .. tostring(self.nTemplateId))
    end
    return tbMelee
end

local function ClearWeaponData(self)
    self:OnAttackFinished()
    self.tbAttackDatas = nil
    Timer.StopOwnerAllTimer(self, true)

    if(self.bServer and self.Owner.CustomReplicationComponent:IsValid()) then
        self.rHumanMeleeAttackRoute:Set(nil)
        self.rHumanMeleeAttackHits:Set(nil)
    end

end

function HumanWeaponMelee:OnDestroyed()
    ClearWeaponData(self)
    HumanWeaponMelee.super.OnDestroyed(self)
end

function HumanWeaponMelee:OnServerUnHolded()
    ClearWeaponData(self)
end

function HumanWeaponMelee:OnServerHolded()
end

function HumanWeaponMelee:GetType()
    return SELF_TYPE
end

function HumanWeaponMelee:IsEmptyHand()
    return self.bEmptyHand
end

function HumanWeaponMelee:GetProperty()
    -- if(self.bEmptyHand) then
    --     return nil
    -- end

    return HumanWeaponMelee.super.GetProperty(self)
end


function HumanWeaponMelee:CreateWeaponProperty()
    self.tbProperty, self.tbBaseProperty = HumanWeaponHelper.CreateCommonWeaponProperty(self.nTemplateId, self.bEmptyHand)
    if(self.tbAttachments) then
        self:UpdateAttachments(self.tbAttachments)
    end
    return self.tbProperty
end


function HumanWeaponMelee:UpdateAttachments(tbAttachments)
    if(self.bEmptyHand) then
        return
    end

    HumanWeaponMelee.super.UpdateAttachments(self)
end

function HumanWeaponMelee:IsUseRootMotion()
    local tbTemplate = self:GetMeleeTemplate()
    local pUEActor = self.pOwnerActor

    local IsRootmotion = false
    if not pUEActor.CharacterMovement:IsFalling() then
        IsRootmotion = tbTemplate.IsRootmotion
    end
    return IsRootmotion 
end 

function HumanWeaponMelee:GetAttackMontageKey(bJumping, nAttackIndex)
    local tbTemplate = self:GetMeleeTemplate()
    local pUEActor = self.pOwnerActor

    local isInJumping = pUEActor.CharacterMovement:IsFalling()
    if bJumping ~= nil then  
        isInJumping = bJumping
    end 
    if isInJumping then
        return tbTemplate.szJumpAnimKey
    else
        local szMontage = tbTemplate.szAnimKey .. "_0" .. nAttackIndex
        return szMontage
    end
end

function HumanWeaponMelee:GetDamageFactor()
    local tbTemplate =self:GetMeleeTemplate()
    if self.bInJumpging then  
        return tbTemplate.nJumpDamageFactor
    end 

    return tbTemplate.tbDamageFactor[self.nRequestMontageIndex]
end

function HumanWeaponMelee:GetSectorAngle(bJumping, nAttackIndex)
    local tbTemplate =self:GetMeleeTemplate()
    if bJumping then  
        return tbTemplate.nJumpSectorAngle
    end 

    return tbTemplate.tbSectorAngles[nAttackIndex]
end

-- 判断此次攻击是否合法，不合法返回原因，合法返回nil
function HumanWeaponMelee:CheckAttackIllegal(tbCurrentMontageData, tbTaker, nAttackRange)
    if not tbTaker then
        return nil
    end
    if not GameObjectSystem:IsCharacter(tbTaker) then
        return nil
    end
    if not (tbTaker.pUEActor and tbTaker.pUEActor.CapsuleComponent) then
        return nil
    end
    local AttackerLocX, AttackerLocY, AttackerLocZ = self.Owner:GetLocationXYZ()
    local pTakerLoc = tbTaker:GetLocation()
    local szReason = nil

    pTakerLoc.X = pTakerLoc.X - AttackerLocX
    pTakerLoc.Y = pTakerLoc.Y - AttackerLocY
    pTakerLoc.Z = pTakerLoc.Z - AttackerLocZ
    -- logdebug("on server check attack",pAttackerLoc.X, pAttackerLoc.Y, pAttackerLoc.Z)
    local nDistance = KismetMathLibrary.VSize(pTakerLoc)
    pTakerLoc = KismetMathLibrary.Normal(pTakerLoc, GDefaultTolerance)

    local pAttackerForwardVector = self.pOwnerActor:GetActorForwardVector()
    local nAngle = KismetMathLibrary.Dot_VectorVector(pTakerLoc, pAttackerForwardVector)
    local nAttackableDistance = nAttackRange + self.pOwnerActor.CapsuleComponent:GetUnscaledCapsuleRadius() + tbTaker.pUEActor.CapsuleComponent:GetUnscaledCapsuleRadius()

    if nDistance > nAttackableDistance then 
        szReason = string.format(tbReasonFormatByType[IllegalType.NOT_IN_RANGE], nAngle, nDistance)
        self:RecordIllegalAttack(IllegalType.NOT_IN_RANGE, szReason)
    end

    return self:TryOnIllegalAttack()
end

-- 判断此次攻击是否命中
function HumanWeaponMelee:CheckAttackHit(tbCurrentMontageData, tbTaker, nAttackRange)
    if not NeedCheckHit(self, tbTaker) then
        return true
    end

    if not tbTaker then
        return false
    end

    if tbTaker:IsDead() then
        return false
    end

    local szReason = self:CheckAttackIllegal(tbCurrentMontageData, tbTaker, nAttackRange)
    if(szReason ~= nil) then
        -- HumanWeaponHelper.OnIllegalAttack(self.Owner, szReason)
        -- CheaterCheckSystem:RecordCheating(self.Owner, CheatingTypeDef.ILLEGAL_ATTACK, szReason)
        return false
    end

    -- TODO
    return true
end

function HumanWeaponMelee:OnClearRepHits()
    self.rHumanMeleeAttackHits:Set(nil)
end

function HumanWeaponMelee:AttackInServer(tbTakerIds)
    local tbCurrentMontageData = self.tbCurrentMontageData
    if(tbCurrentMontageData == nil or #tbTakerIds == 0) then
        -- 不在攻击间隔内，直接忽略
        if NeedCheckHit(self) and #tbTakerIds > 0 then
            self:TryOnIllegalAttack()
        end
        return
    end

    local DamageFactor = self:GetDamageFactor()

    local nAttackRange, BaseDamage
    local tbWeaponProperty = self:GetProperty()

    if not self.bEmptyHand then
        BaseDamage = self:GetOwnerProperty(PropName.nDamagePerAttack)
        nAttackRange = tbWeaponProperty.nEffectiveRange*100
    else
        local MeleeComponent = self.pOwnerActor.MeleeComponent
        BaseDamage = MeleeComponent.BaseDamage
        nAttackRange = MeleeComponent.AttackRange
    end
    BaseDamage = DamageFactor * BaseDamage

    local tbTaker, tbHitTakers
    -- local nDamageType = self.bEmptyHand and DamageTypeEx.HUMAN_EMPTY_HAND or DamageTypeEx.HUMAN_MELEE
    if(#tbTakerIds == 1) then
        -- 大部分情况只会打中一人
        local nTakerId = tbTakerIds[1]
        tbTaker = GameObjectSystem:FindByInstanceId(nTakerId)
        if(self:CheckAttackHit(tbCurrentMontageData, tbTaker, nAttackRange)) then
            -- if self.bEmptyHand then
            --     ApplyDamage(self, tbTaker, BaseDamage, nDamageType)
            -- else
                local Owner = self.Owner
                local tbProperty = self:GetProperty()
                TakeDamage(tbTaker, BaseDamage, Owner, tbProperty, HumanBodyDef.HUMAN_BODY)
            -- end
            tbSingleMeleeHits[1] = nTakerId
            tbHitTakers = tbSingleMeleeHits
        end
    else
        for _, nTakerId in ipairs(tbTakerIds) do
            tbTaker = GameObjectSystem:FindByInstanceId(nTakerId)
            if(self:CheckAttackHit(tbCurrentMontageData, tbTaker, nAttackRange)) then
                -- ApplyDamage(self, tbTaker, BaseDamage, nDamageType, tbDamageExtraData)
                local Owner = self.Owner
                local tbProperty = self:GetProperty()
                TakeDamage(tbTaker, BaseDamage, Owner, tbProperty, HumanBodyDef.HUMAN_BODY)

                if(tbHitTakers == nil) then
                    tbHitTakers = {}
                end
                table.insert(tbHitTakers, nTakerId)
            end
        end
    end
    self.OwnerComponent:OnDamageEnd()

    if(tbHitTakers) then
        if tbMeleeHitData.takers then
            if self.bChangeTakerId then
                tbMeleeHitData.takers = tbHitTakers
                for i,v in ipairs(tbMeleeHitData.takers) do
                    tbMeleeHitData.takers[i] = v * -1
                end
                self.bChangeTakerId = false
            else
                self.bChangeTakerId = true
                tbMeleeHitData.takers = tbHitTakers
            end
        else
            self.bChangeTakerId = true
            tbMeleeHitData.takers = tbHitTakers
        end
        self.rHumanMeleeAttackHits:Set(tbMeleeHitData)
        Timer.StartOwnerTimer(self, REP_HIT_CLEAR_TIMER, self.OnClearRepHits, self.REP_PROPERTY_CLEAR_TIME)
    end

    self.tbCurrentMontageData = nil
end

function HumanWeaponMelee:OnAttackStarted(nMontageIndex)
    if nMontageIndex == 0 then  
        return 
    end
    local CharacterMovement = self.pOwnerActor.CharacterMovement
    CharacterMovement.bEnableSlideAlongSurface = false 
    local tbTemplate = self:GetMeleeTemplate()
    if(nMontageIndex < 0 or nMontageIndex > tbTemplate.nAnimCount) then
        logerror("melee attack montage index is invalid, index: ", nMontageIndex, "Count", tbTemplate.nAnimCount)
        -- HumanWeaponHelper.OnAttackIllegal(self.Owner, "melee attack montage index is invalid, index: "..tostring(nMontageIndex))
        return
    end

    if self:IsUseRootMotion() then
        CharacterMovement.bIgnoreClientMovementErrorChecksAndCorrection = true
        local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
        local nState = HumanMovementStateComponent:GetCurrentState()
        if nState == HumanMovementStateType.Crouch_State then  
            HumanMovementStateComponent:SetMovementState(HumanMovementStateType.UpRight_State)
        end 
    end

    Timer.StartOwnerTimer(self, ATTACK_TIMER, self.OnAttackFinished, MONTAGE_POST_ATTACK_TIME)
end

function HumanWeaponMelee:OnAttackFinished()
    local CharacterMovement = self.pOwnerActor.CharacterMovement
    -- self.pOwnerActor:SetReplicateMovement(true)
    CharacterMovement.bEnableSlideAlongSurface = true 
    CharacterMovement.bIgnoreClientMovementErrorChecksAndCorrection = false
end

local function OnClearRepAttack(self)
    self.rHumanMeleeAttackRoute:Set(nil)
end

function HumanWeaponMelee:GetNextMontageIndex()
    local nMontageIndex = 1
    local tbTemplate = self:GetMeleeTemplate()
    if tbTemplate.IsRandom then
        nMontageIndex = math.random(1, tbTemplate.nAnimCount)
    else 
        nMontageIndex = self.LastMontageIndex + 1
        if nMontageIndex > tbTemplate.nAnimCount then  
            nMontageIndex = 1
        end 
    end
    return nMontageIndex
end


local function GetMovementState(tbPlayer)
    local HumanMovementStateComponent = tbPlayer.HumanMovementStateComponent
    if HumanMovementStateComponent == nil then
        return 0
    end

    return HumanMovementStateComponent:GetCurrentState()
end

local function GetCurWeaponProperty(tbPlayer)
    local nWeaponTemplateId
    local HumanWeaponComponent = tbPlayer.HumanWeaponComponent
    local nCategory = 0
    if HumanWeaponComponent then
        -- nWeaponTemplateId = HumanWeaponComponent.rCurrentWeaponTemplateId and HumanWeaponComponent.rCurrentWeaponTemplateId:Get()
        nWeaponTemplateId = HumanWeaponComponent:GetCurrentWeaponTemplateId()
        if nWeaponTemplateId and nWeaponTemplateId == 0 then
            nWeaponTemplateId = 0
        end
        nCategory = HumanWeaponComponent:GetCurrentWeaponCategory(nWeaponTemplateId)
    end
    return nWeaponTemplateId, nCategory
end

local function GetHumanArmorId(tbPlayer)
    local HumanBattlePropertyComponent = tbPlayer.HumanBattlePropertyComponent
    if HumanBattlePropertyComponent then  
        local nCurrentArmorTemplatedId = tbPlayer.HumanBattlePropertyComponent:GetProp(PropName.nCurrentArmorTemplateId)
        return nCurrentArmorTemplatedId
    end
    return -1
end

function HumanWeaponMelee:PlayMontage(nMontageIndex, bJumping, PlayRate, StartPos, Yaw)
    local szMontage = self:GetAttackMontageKey(bJumping, nMontageIndex)

    local pMontage, tbTemplate= self.OwnerComponent:GetMontageWithAnimKey(szMontage)
    if not pMontage then
        local nStateId = GetMovementState(self.Owner)
        local nWeaponTemplateId, nCategory = GetCurWeaponProperty(self.Owner)
        local nArmorId = GetHumanArmorId(self.Owner)
        local nTemplateId = self.Owner:GetTemplateId()
        logwarning("HumanWeaponMelee:PlayMontage failed PlayerName", self.Owner.szName, "nTemplateId", nTemplateId, "nArmorId", nArmorId, 
        "nWeaponTemplateId", nWeaponTemplateId, "nCategory", nCategory, "nStateId", nStateId, "szMontage", szMontage)
        return false
    end
    self.bInJumpging = bJumping
    self.nRequestMontageIndex = nMontageIndex

    if not bJumping then 
        self.LastMontageIndex = nMontageIndex
    end
    self.OwnerComponent:PlayMontageWithAnimKey(szMontage, PlayRate)

    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    local nRate = pMontage.RateScale * nAttackCoefficient    
    local nEndSectionTime = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, AnimDef.SectionName.MELEE_ATTACK_END) / nRate
    local nHitSectionTime = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, AnimDef.SectionName.MELEE_HIT_TIME) / nRate

    if not self.tbCurrentMontageData then
       self.tbCurrentMontageData = {}
    end

    self.tbCurrentMontageData.nRateScale = nRate    
    self.tbCurrentMontageData.nEndSectionTime = nEndSectionTime
    self.tbCurrentMontageData.nHitSectionTime = nHitSectionTime
    self.tbCurrentMontageData.nSequenceLength = pMontage.SequenceLength / nRate

    local pUEActor = self.pOwnerActor
    -- if szRootMotion then  
    if tbTemplate.tbRootMotionVectors then 
        local StartPosVector
        if StartPos then 
            StartPosVector = TableToTempVector1(StartPos)
        else 
            StartPosVector = self.Owner:GetLocation()
        end
        pTempRotator.Yaw = 0
        if Yaw ~= nil then  
            -- pUEActor:K2_SetActorRotation(Rotator{Pitch = 0, Yaw = Yaw, Roll = 0})
            pTempRotator.Yaw = Yaw
        end
        pUEActor.CharacterMovement:PlayRootMotion(tbTemplate.tbRootMotionVectors, 0.0, StartPosVector, pTempRotator, self.bServer, nRate)
    end     
    return true
end

-- CheatAttack  Auto Next AttackMontage
local function OnEndPlayMontage(self)
    -- 这是为了解决客户端播完了.服务器还没有播放完,就会出现拖拽,所以现在是收到客户端包会不会马上播动作,等服务器把现在动作播完自动播放下个动作
    if not self.bInCheatAttackIng and (not self.tbAttackDatas  or #self.tbAttackDatas <= 0) then 
        return 
    end
    local nMontageIndex = 1
    local StartPos = nil
    local Yaw = 0
    local bJumping = false
    if not self.bInCheatAttackIng then
        local tbAttackData = self.tbAttackDatas[1]
        if not tbAttackData then 
            return 
        end

        table.remove(self.tbAttackDatas, 1)
        nMontageIndex = tbAttackData.nMontageIndex
        StartPos = tbAttackData.StartPos
        bJumping = tbAttackData.bJumping
        Yaw = tbAttackData.Yaw
        log("play rep melee attack index", nMontageIndex)
        self:PlayRepMeleeAttackRoute(nMontageIndex, bJumping, StartPos, Yaw, true)
    -- else
    --     nMontageIndex = self:GetNextMontageIndex()

    --     local Yaw = math.floor(self.pOwnerActor:K2_GetActorRotation().Yaw)

    --     self:RouteAttack(nMontageIndex, false, true, nil, Yaw)        
    --     local TargetObject = nil
    --     if Target then
    --         local nUniqueId = EngineExtActorShell.GetActorUniqueId(Target)
    --         TargetObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    --     end
    --     local nHitTime = self.tbCurrentMontageData.nHitSectionTime
    
    --     local nCurrentTime = ExtendBlueprintFunctions:GetPlatformMilliseconds()
    --     local tbCheatAttackInfo = {
    --         TargetObject = TargetObject, 
    --         nDamageType = nDamageType,
    --         nHitTime = nHitTime,
    --         nStartTime = nCurrentTime
    --     }
    --     table.insert(self.tbCheatAttackList, 1, tbCheatAttackInfo)
    --     self:ApplyCheatAttack()
    --     log("play CheatAttack attack index")
    end
end

function HumanWeaponMelee:PlayRepMeleeAttackRoute(nMontageIndex, bJumping, StartPos, Yaw, bForce)
    if not bForce and (#self.tbAttackDatas > 0 or Timer.IsOwnerTimerAlived(self, REP_ROOTMOTION_MONTAGE_TIMER)) then  
        local tbAttackData = {nMontageIndex = nMontageIndex, bJumping = bJumping, StartPos = StartPos, Yaw = Yaw}
        table.insert(self.tbAttackDatas, tbAttackData)
        return 
    end

    if not CheckValidStartPos(self, StartPos) then
        self.tbAttackDatas = {}
        return
    end

    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    local bRet = self:PlayMontage(nMontageIndex, bJumping, nAttackCoefficient, StartPos, Yaw)
    if (not bRet) or (not self.tbCurrentMontageData) then 
        return 
    end

    local nStartTime = self.tbCurrentMontageData.nEndSectionTime
    if nStartTime > 0 then 
        log("start next animation timer")
        Timer.StartOwnerTimer(self, REP_ROOTMOTION_MONTAGE_TIMER, OnEndPlayMontage, nStartTime)
    end
end

function HumanWeaponMelee:RouteAttack(nMontageIndex, bJumping, bAIController, StartPos, Yaw)
    self:OnAttackStarted(nMontageIndex)
    -- PlayMontage(self, nMontageIndex)
    Timer.StopOwnerTimer(self, REP_ATTACK_CLEAR_TIMER)
    local rNotify = self.rHumanMeleeAttackRoute
    local tbHumanMeleeAttack = {}
    tbHumanMeleeAttack.weapon_id = self.nInstanceId
    tbHumanMeleeAttack.montage_index = nMontageIndex
    if rNotify then 
        local tbHumanMeleeAttackRoute = rNotify:Get()
        if tbHumanMeleeAttackRoute then 
            tbHumanMeleeAttack.montage_index = tbHumanMeleeAttackRoute.montage_index  > 0 and -nMontageIndex or nMontageIndex
        end
    end
    if bAIController then 
        StartPos = VectorToTempTable(self.Owner:GetLocation())
    end 
    tbHumanMeleeAttack.in_jumping = bJumping
    tbHumanMeleeAttack.start = StartPos
    tbHumanMeleeAttack.yaw = Yaw
    rNotify:Set(tbHumanMeleeAttack)
    Timer.StartOwnerTimer(self, REP_ATTACK_CLEAR_TIMER, OnClearRepAttack, self.REP_PROPERTY_CLEAR_TIME)

    if nMontageIndex ~= 0 then 
        self:PlayRepMeleeAttackRoute(nMontageIndex, bJumping, StartPos, Yaw)
        -- if bAIController then
        HumanWeaponHelper.ServerAttackEvent(self.Owner, self.nInstanceId)
    end
    --
    EventManager:OnFireEvent(CommonEventDef.EV_ON_MELEE_ATTACK, self.Owner)
end

function HumanWeaponMelee:ApplyCheatAttack()
    if not self.tbCheatAttackList or #self.tbCheatAttackList == 0 then
        return
    end

    local CheatAttackTimer = Timer.GetOwnerTimer(self, CHEAT_ATTACK_TIMER)
    if CheatAttackTimer then
        return 
    end

    local tbCheatAttackInfo = table.remove(self.tbCheatAttackList)

    local nTime = tbCheatAttackInfo.nHitTime

    if tbCheatAttackInfo.nDamageType and tbCheatAttackInfo.TargetObject then
        Timer.StartOwnerTimer(self, CHEAT_ATTACK_TIMER, function()
            local tbTargets = {}
            table.insert(tbTargets, tbCheatAttackInfo.TargetObject.nServerInstanceId)
            self:AttackInServer(tbTargets)
            Timer.StopOwnerTimer(self, CHEAT_ATTACK_TIMER)
            self:ApplyCheatAttack()
        end, nTime)
    else
        Timer.StartOwnerTimer(self, CHEAT_ATTACK_TIMER, function()
            Timer.StopOwnerTimer(self, CHEAT_ATTACK_TIMER)
            self:ApplyCheatAttack()
        end, nTime)
    end
end

function HumanWeaponMelee:CheatAttack(Target, nDamageType)
    assert(self.bServer)
    if Timer.IsOwnerTimerAlived(self, REP_ROOTMOTION_MONTAGE_TIMER) then
        return
    end
    log("on melee start cheat attack")
    self.bInCheatAttackIng = true 
    Timer.StopOwnerTimer(self, DELAY_CLEAR_ANIMINDEX)
    local nMontageIndex = self:GetNextMontageIndex()
    local Yaw = 0
    if self.pOwnerActor then
        Yaw = math.floor(self.pOwnerActor:K2_GetActorRotation().Yaw)
    end
    self:RouteAttack(nMontageIndex, false, true, nil--[[StartPos]], Yaw)
    local TargetObject = nil
    if Target then
        local nUniqueId = EngineExtActorShell.GetActorUniqueId(Target)
        TargetObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    end
    local nHitTime = self.tbCurrentMontageData.nHitSectionTime

    local nCurrentTime = ExtendBlueprintFunctions:GetPlatformMilliseconds()
    local tbCheatAttackInfo = {
        TargetObject = TargetObject, 
        nDamageType = nDamageType,
        nHitTime = nHitTime,
        nStartTime = nCurrentTime
    }
    table.insert(self.tbCheatAttackList, 1, tbCheatAttackInfo)
    self:ApplyCheatAttack()

end

function HumanWeaponMelee:OnStopAttack()
    local tbTemplate = self:GetMeleeTemplate()
    Timer.StopOwnerTimer(self, DELAY_CLEAR_ANIMINDEX)
    Timer.StartOwnerTimer(self, DELAY_CLEAR_ANIMINDEX, function() 
        self.LastMontageIndex = 0
    end, tbTemplate.nComboTime)
end
function HumanWeaponMelee:StopCheatAttack()
    self.bInCheatAttackIng = false 
    self:OnStopAttack()
end 

function HumanWeaponMelee:GetCheatCDTime()
    local RepRootMotionMontageTimer = Timer.GetOwnerTimer(self, REP_ROOTMOTION_MONTAGE_TIMER)
    if RepRootMotionMontageTimer then
        return RepRootMotionMontageTimer:GetRemainingTime()
    end
    if Timer.IsOwnerTimerAlived(self, CHEAT_ATTACK_TIMER) then
        local CheatAttackerTimer = Timer.GetOwnerTimer(self, CHEAT_ATTACK_TIMER)
        return CheatAttackerTimer:GetRemainingTime()
    end
    return 0
end

return HumanWeaponMelee 