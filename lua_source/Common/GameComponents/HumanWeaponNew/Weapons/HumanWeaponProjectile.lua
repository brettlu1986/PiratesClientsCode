local luaclass = require("luaclass")
local HumanWeaponGunBase = dynamic_require("HumanWeaponGunBase")
local HumanWeaponProjectile = luaclass("HumanWeaponProjectile", HumanWeaponGunBase)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local TakeDamage = require("HDC_HumanBulletNew")
local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponHelper = require("HumanWeaponHelper")
local Timer = require("Timer")
local PropName = require("PropName")
local ShipUtilityExHelper = require("ShipUtilityExHelper")
local HumanWeaponDef = require("HumanWeaponDef")

local CHEAT_ATTACK_TIMER = "CheatAttackTimer"
local CHEAT_RELOAD_TIMER = "CheatReloadTimer"

local SELF_TYPE = HumanWeaponMisc.Type.PROJECTILE
local AttackSubState = HumanWeaponMisc.AttackSubState
local MILLISECONDS_PER_SECOND   = 1000
local GRAVITY = 1000
local tbTempNotify = {}


HumanWeaponProjectile.StartAttackPos = nil
HumanWeaponProjectile.StartAttackDir = nil

HumanWeaponProjectile.tbStartAttackPoses = {}
HumanWeaponProjectile.tbStartAttackDirs = {}

HumanWeaponProjectile.nLastCheatAttackTime = 0
HumanWeaponProjectile.tbCheatAttackList = {}
HumanWeaponProjectile.nGravityScale = 1
HumanWeaponProjectile.nBulletRadiusForTorpedo = 10

local tbTemp1 = {}
local tbTemp2 = {}
local tbTempIndexs = {}
local pEndPos = Vector()
local TempAxisVector = Vector()

local function CopyVector(Dest, From)
    Dest.X = From.X
    Dest.Y = From.Y
    Dest.Z = From.Z
end
local function VectorToTempTable1(Vector)
    CopyVector(tbTemp1, Vector)
    return tbTemp1
end

local function VectorToTempTable2(Vector)
    CopyVector(tbTemp2, Vector)
    return tbTemp2
end

local function LOG(...)
    log("[HumanWeaponProjectile]", ...)
end
local function TableToVector(teTemp)
    CopyVector(pEndPos, teTemp)
    return tbTemp1
end
local function CalcCheatHitAttackDir(self, StartPos, EndPos)
    local nSpeed = self:GetOwnerProperty(PropName.nBulletInitialSpeed)
    local vDirection = KismetMathLibrary.Subtract_VectorVector(EndPos, StartPos)
    local nDistance = KismetMathLibrary.VSizeXY(vDirection)
    vDirection = KismetMathLibrary.Normal(vDirection, GDefaultTolerance)

    local nGravity = GRAVITY * (self.nGravityScale and self.nGravityScale or 1)
    
    local nHeight = EndPos.Z - StartPos.Z
    if nHeight < 0 then
        nHeight = 0
    end
    local nTanAlpha1 = (nSpeed^2 + math.sqrt(nSpeed^4 - nGravity * (nGravity*(nDistance^2) + 2*nHeight*(nSpeed^2))))/(nGravity*nDistance)
    local nTanAlpha2 = (nSpeed^2 - math.sqrt(nSpeed^4 - nGravity * (nGravity*(nDistance^2) + 2*nHeight*(nSpeed^2))))/(nGravity*nDistance)
    
    local nAlpha1 = math.atan(nTanAlpha1)
    local nAlpha2 = math.atan(nTanAlpha2)
    
    local nTanAlpha = nTanAlpha1
    if nAlpha1 > nAlpha2 then
        nTanAlpha = nTanAlpha2
    end

    local nAlpha = math.deg(math.atan(nTanAlpha))
    
    if nAlpha > 0 then
        TempAxisVector.X = vDirection.Y
        TempAxisVector.Y = - vDirection.X
        TempAxisVector.Z = 0
        TempAxisVector = KismetMathLibrary.Normal(TempAxisVector, GDefaultTolerance)
        vDirection = KismetMathLibrary.RotateAngleAxis(vDirection, nAlpha, TempAxisVector)
    end

    return vDirection
end

function HumanWeaponProjectile:ApplyCheatAttack()
    if not self.tbCheatAttackList or #self.tbCheatAttackList == 0 then
        LOG("tbCheatAttackList is clear")
        return
    end

    local CheatAttackTimer = Timer.GetOwnerTimer(self, CHEAT_ATTACK_TIMER)
    if CheatAttackTimer then
        LOG("CheatAttackTimer remains:", CheatAttackTimer:GetRemainingTime())
        return
    end

    LOG("ApplyCheatAttack")


    local nCurrentTime = ExtendBlueprintFunctions:GetPlatformMilliseconds()
    local tbCheatAttackInfo = table.remove(self.tbCheatAttackList)

    if tbCheatAttackInfo.szDamageType and tbCheatAttackInfo.nTargetUniqueId then
        local StartPos = tbCheatAttackInfo.StartPos
        local EndPos = tbCheatAttackInfo.EndPos
        local Direction = KismetMathLibrary.Subtract_VectorVector(EndPos, StartPos)
        local Distance = KismetMathLibrary.VSize(Direction)

        local nTime = Distance / (tbCheatAttackInfo.nInitialSpeed / 1000)   -- ms
        nTime = nTime - (nCurrentTime - tbCheatAttackInfo.nStartTime)       -- ms
        nTime = nTime / 1000
        Timer.StartOwnerTimer(self, CHEAT_ATTACK_TIMER, function()
            -- local ActorsToIgnore = {self.pOwnerActor}
            -- local bRet = KismetSystemLibrary.LineTraceSingle(GWorld, StartPos, EndPos, ECollisionChannel.ECC_Pawn, false, ActorsToIgnore, EDrawDebugTrace.None)
            local bBlocked = self.pOwnerActor:CheckAttackBlocked(StartPos, EndPos)
            local TargetObject = GameObjectSystem:FindByUniqueId(tbCheatAttackInfo.nTargetUniqueId)
            if TargetObject and (not bBlocked) and HumanWeaponHelper.CanBeAttacked(TargetObject) and (not TargetObject:IsDead()) then
                -- self.StartAttackDir = tbCheatAttackInfo.tbRepData.ends[1]
                -- self.StartAttackPos = tbCheatAttackInfo.tbRepData.start
                local StartAttackDir = tbCheatAttackInfo.tbRepData.ends[1]
                -- local StartAttackPos = tbCheatAttackInfo.tbRepData.start
                local nProjectilIndex = tbCheatAttackInfo.tbRepData.indexes[1]
                -- Will get EndPos according to szDamageType in client
                StartPos.X = EndPos.X - 50 * StartAttackDir.X
                StartPos.Y = EndPos.Y - 50 * StartAttackDir.Y
                StartPos.Z = EndPos.Z - 50 * StartAttackDir.Z
                logdebug("lz attack once 5")
                self:AttackOnceInServer(TargetObject.nServerInstanceId, VectorToTempTable2(StartPos), nil, HumanWeaponHelper.GetHitType(tbCheatAttackInfo.szDamageType), tbCheatAttackInfo.szDamageType, nProjectilIndex)
            else
                self:RouteProjectAttack(tbCheatAttackInfo.tbRepData)
            end
            Timer.StopOwnerTimer(self, CHEAT_ATTACK_TIMER)
            self:ApplyCheatAttack(self)
        end, nTime)
    else
        local nTime =  0.5
        nTime = nTime - (nCurrentTime - tbCheatAttackInfo.nStartTime) / 1000
        Timer.StartOwnerTimer(self, CHEAT_ATTACK_TIMER, function()
            self:RouteProjectAttack(tbCheatAttackInfo.tbRepData)
            Timer.StopOwnerTimer(self, CHEAT_ATTACK_TIMER)
            self:ApplyCheatAttack(self)
        end, nTime)

    end

end

function HumanWeaponProjectile:GetType()
    return SELF_TYPE
end
function HumanWeaponProjectile:RouteAttack(tbRepData)
    assert(self.bServer)
    if(not self:DecreaseAmmo(self:GetOwnerProperty(PropName.nBulletCostPerAttack))) then
        return
    end

    local nProjectilIndex = 0
    if tbRepData.indexes and tbRepData.indexes[1] then
        nProjectilIndex = tbRepData.indexes[1]
    end

    local szReason = self:CheckAttackIllegalOnFire(KismetMathLibrary.MakeVector(tbRepData.start.X, tbRepData.start.Y, tbRepData.start.Z))
    if szReason then
        HumanWeaponHelper.OnIllegalAttack(self.Owner, szReason)
        -- self.StartAttackPos = nil
        -- self.StartAttackDir = nil
        self.tbStartAttackPoses[nProjectilIndex] = nil
        self.tbStartAttackDirs[nProjectilIndex] = nil
        return
    end

    self:RepAttack(self.rHumanGunAttackRoute, tbRepData)

    -- self.StartAttackPos = tbRepData.start
    -- self.StartAttackDir = tbRepData.ends[1]
    self.tbStartAttackPoses[nProjectilIndex] = tbRepData.start
    self.tbStartAttackDirs[nProjectilIndex] = tbRepData.ends[1]

    if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) == HumanWeaponDef.WeaponCategory.Crossbow then
        HumanWeaponHelper.ServerAttackEvent(self.Owner, self.nInstanceId)
    end
end
function HumanWeaponProjectile:TriggerTorpedoBySphere(tbEndPos)
    local nCategory = HumanWeaponHelper.GetWeaponCategory(self.nTemplateId)
    local TorpedoTriggerType = self.pOwnerActor:ConvertWeaponTypeToTorpedoTriggerType(nCategory)

    TableToVector(tbEndPos)
    ShipUtilityExHelper.TriggerTorpedoBySphere(TorpedoTriggerType, pEndPos, self.nBulletRadiusForTorpedo, GWorld)
end

function HumanWeaponProjectile:RouteProjectAttack(tbRepData)
    self:RepAttack(self.rHumanProjectGunAttackRoute, tbRepData)
    -- self.StartAttackPos = nil
    -- self.StartAttackDir = nil
    local nProjectilIndex = 0
    if tbRepData.indexes and tbRepData.indexes[1] then
        nProjectilIndex = tbRepData.indexes[1]
    end
    self.tbStartAttackPoses[nProjectilIndex] = nil
    self.tbStartAttackDirs[nProjectilIndex] = nil

    for i,v in ipairs(tbRepData.ends) do
        self:TriggerTorpedoBySphere(v)
    end
end

function HumanWeaponProjectile:AttackOnceInServer(nTakerId, StartPos, EndPos, nHitBodyType, szDamageType, nProjectilIndex)
    logdebug("lz attack once 6")
    local Owner = self.Owner
    local tbProperty = self:GetProperty()
    local nDamage = self:GetOwnerProperty(PropName.nDamagePerAttack)
    local nInstanceId = self.nInstanceId
    --  已经扣过一次了
    -- if(not self:DecreaseAmmo(tbProperty.nDecreaseBulletCount)) then
    --     return
    -- end
    local Taker = GameObjectSystem:FindByInstanceId(nTakerId)
    if(Taker == nil) then
        return
    end
    if not self:CheckAttackFrequency() then
        return
    end
    -- tbTempEnds[1] = EndPos
    tbTempNotify.weapon_id = nInstanceId
    tbTempNotify.start = StartPos
    tbTempNotify.end_pos = EndPos

    local StartAttackPos = self.tbStartAttackPoses[nProjectilIndex]
    local StartAttackDir = self.tbStartAttackDirs[nProjectilIndex]
    if(self:CheckAttackHit(StartAttackPos, StartAttackDir, Taker, nHitBodyType)) then
        TakeDamage(Taker, nDamage, Owner, tbProperty, nHitBodyType)
        tbTempNotify.taker = Taker:GetServerInstanceId()
        if szDamageType then
            tbTempNotify.hit_type = HumanWeaponHelper.GetHumanPartProperty(szDamageType)
        end
    else
        tbTempNotify.taker = nil
    end
    self.OwnerComponent:OnDamageEnd()
    self:RepAttack(self.rHumanGunAttackOnceResult, tbTempNotify)
    -- self.StartAttackPos = nil
    -- self.StartAttackDir = nil
    self.tbStartAttackPoses[nProjectilIndex] = nil
    self.tbStartAttackDirs[nProjectilIndex] = nil
end

function HumanWeaponProjectile:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponProjectile.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)

    self.rHumanProjectGunAttackRoute = OwnerComponent.rHumanProjectGunAttackRoute
end

function HumanWeaponProjectile:OnDestroyed()
    Timer.StopOwnerAllTimer(self, true)
    HumanWeaponProjectile.super.OnDestroyed(self)
end


function HumanWeaponProjectile:OnClearAllRepData()
    HumanWeaponProjectile.super.OnClearAllRepData(self)
    self.rHumanProjectGunAttackRoute:Set(nil)
end

function HumanWeaponProjectile:CheatAttack(Target, szDamageType)
    assert(self.bServer)
    if self:GetCurrentAmmo() <= 0 then
        return
    end

    LOG("CheatAttack")

    local tbWeaponProperty = self:GetProperty()
    local TargetObject = nil
    local nTargetUniqueId = nil
    if Target then
        nTargetUniqueId = EngineExtActorShell.GetActorUniqueId(Target)
        TargetObject = GameObjectSystem:FindByUniqueId(nTargetUniqueId)
    end
    
    local tbRepData = {}
    tbRepData.weapon_id = self.nInstanceId
    tbRepData.ends = {}
    local StartPos = self.pOwnerActor:GetActorEyesViewPoint()
    local nCapsuleHalfHeight = HumanWeaponHelper.GetHumanCapsuleHalfHeight(self.Owner)
    -- 防止多次攻击之间数据没有变化，客户端收不到rHumanProjectGunAttackRoute的rep事件，导致播不出动作
    StartPos.Z = StartPos.Z + (math.random(100, 500) / 1000000) - nCapsuleHalfHeight / 2
    tbRepData.start = VectorToTempTable1(StartPos)
    
    local EndPos = nil
    if Target and szDamageType and TargetObject then
        if TargetObject.HumanMovementStateComponent then
            local nState = TargetObject.HumanMovementStateComponent:GetCurrentState()
            EndPos = HumanWeaponHelper.GetLocationByHitTypeAndMovementState(Target, szDamageType, nState)
        else
            EndPos = HumanWeaponHelper.GetLocationByHitType(Target, szDamageType)
        end
        if not EndPos then
            return
        end
        local Dir = CalcCheatHitAttackDir(self, StartPos, EndPos)
        tbRepData.ends[1] = VectorToTempTable2(Dir)
    else
        local Dir = self.pOwnerActor:GetBaseAimRotation()
        Dir = KismetMathLibrary.Conv_RotatorToVector(Dir)
        Dir = KismetMathLibrary.Normal(Dir, GDefaultTolerance)
        tbRepData.ends[1] = VectorToTempTable2(Dir)
    end
    
    tbTempIndexs[1] = 0
    tbRepData.indexes = tbTempIndexs
    -- self.StartAttackPos = tbRepData.start
    -- self.StartAttackDir = tbRepData.ends[1]
    self:RouteAttack(tbRepData)
    
    local nCurrentTime = ExtendBlueprintFunctions:GetPlatformMilliseconds()
    local tbCheatAttackInfo = {
        StartPos = StartPos,                            -- attacker的EyesViewPoint
        EndPos = EndPos,                                -- taker的被击中位置
        nTargetUniqueId = nTargetUniqueId,              -- taker id
        szDamageType = szDamageType,                    -- taker被击中位置
        tbRepData = tbRepData,
        nInitialSpeed = tbWeaponProperty.nInitialSpeed,
        nStartTime = nCurrentTime
    }
    -- logdebug(tbCheatAttackInfo.StartPos, tbCheatAttackInfo.EndPos, tbCheatAttackInfo.TargetObject, tbCheatAttackInfo.szDamageType, tbCheatAttackInfo.tbRepData, tbCheatAttackInfo.nInitialSpeed, tbCheatAttackInfo.nStartTime)

    table.insert(self.tbCheatAttackList, 1, tbCheatAttackInfo)

    self:ApplyCheatAttack()

    local nCurrentSubstate = self:GetRepAttackSubState()
    if nCurrentSubstate ~= AttackSubState.IDLE then
        -- 有SubState的武器此时不reload
        return
    end

    log("[HumanWeaponProjectile] CheatAttack Reload")

    local tbProperty = self:GetProperty()
    local nReloadTime = tbProperty.nReloadTime
    Timer.StartOwnerTimer(self, CHEAT_RELOAD_TIMER, function()
        if self:GetCurrentAmmo() <= 0 then
            self.OwnerComponent:Reload(nReloadTime)
        end
    end, tbProperty.nRateOfFire)

end

function HumanWeaponProjectile:GetRemainReloadingTime()
    local nReloadTime = HumanWeaponProjectile.super.GetRemainReloadingTime(self)
    if nReloadTime > 0 then
        return nReloadTime
    end
    local nFireCDTime = self:GetRemainingAttackCDTimeMilliSeconds() / MILLISECONDS_PER_SECOND
    if nFireCDTime > 0 then
        return nFireCDTime
    end
    return 0
end

function HumanWeaponProjectile:GetRemainingAttackCDTimeMilliSeconds()
    return 0
end

return HumanWeaponProjectile