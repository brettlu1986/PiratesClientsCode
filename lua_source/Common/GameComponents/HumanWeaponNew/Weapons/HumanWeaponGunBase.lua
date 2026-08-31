local luaclass = require("luaclass")
local HumanWeaponBase = dynamic_require("HumanWeaponBase")
local HumanWeaponGunBase = luaclass("HumanWeaponGunBase", HumanWeaponBase)

local Timer = require("Timer")
local HumanWeaponHelper = require("HumanWeaponHelper")
local TakeDamage = require("HDC_HumanBulletNew")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local AIHelper = require("AIHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleAbilitySystem = require("BattleAbilitySystem")
local BattleAbilityDefine = require("BattleAbilityDefine")
local MathUtil = require("MathUtil")
local PropName = require("PropName")
local ShipUtilityExHelper = require("ShipUtilityExHelper")
-- local CheaterCheckSystem = dynamic_require("CheaterCheckSystem")
-- local CheatingTypeDef = require("CheatingTypeDef")

local REP_CLEAR_TIMER = "RepClearTimer"
local RELOAD_TIMER = "ReloadTimer"

local MUZZLE_TOO_FAR_FORMAT = "Muzzle location is too far from shooter location with distance %f, muzzle location is (%f, %f, %f), shooter location is (%f, %f, %f)."
local THROUGH_WALL_FORMAT = "Muzzle location is blocked from camera location, muzzle location is (%f, %f, %f), camera location is (%f, %f, %f)."
local NOT_FIND_TAKER_FORMAT = "Cannot find taker in shooting direction. Taker is %s, shooter position is (%f, %f, %f), taker position is (%f, %f, %f)."
local MAX_MUZZLE_DISTANCE = 200
local RANGE_BOX_Y = 200
local SECTOR_ANGLE = 45

local RANGE_TYPE                = BattleAbilityDefine.RangeType
local MILLISECONDS_PER_SECOND   = 1000
local TOLERANCE_PERCENTAGE      = 0.8

local BULLET_RADIUS = 10

local tbTempEnds = {}
local tbTempNotify = {}
tbTempNotify.ends = tbTempEnds

HumanWeaponGunBase.tbAttachments = nil
HumanWeaponGunBase.bAiming = false

HumanWeaponGunBase.rHumanGunAttackRoute = nil
HumanWeaponGunBase.rHumanGunAttackOnceResult = nil
HumanWeaponGunBase.rHumanGunAttackMultiResult = nil

local CHEAT_ATTACK_TIMER = "CheatAttackTimer"

local tbTemp1 = {}
local tbTemp2 = {}

local pStartPos = Vector()
local pEndPos = Vector()

local IllegalAttackReasonDef ={
    Legal = 0,
    MuzzleTooFar = -1,
    ThroughWall = -2,
}

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

local function TableToVector(teTemp)
    CopyVector(pStartPos, teTemp)
    return tbTemp1
end

local function LOG_AMMO_AMOUNT(self, szInfo)
    if GlobalVariableSystem:IsServerLogic() then
        local nAmmoStackCount, _ = HumanWeaponHelper.GetAmmoInfo(self.nInstanceId)
        if nAmmoStackCount ~= self.nRemainAmmo then
            logerror(szInfo, self.nRemainAmmo, nAmmoStackCount, self.nInstanceId, self.Owner:GetName())
            log(debug.traceback())
        end
    end
end

function HumanWeaponGunBase:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponGunBase.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)

    self.rHumanGunAttackRoute = OwnerComponent.rHumanGunAttackRoute
    self.rHumanGunAttackOnceResult = OwnerComponent.rHumanGunAttackOnceResult
    self.rHumanGunAttackMultiResult = OwnerComponent.rHumanGunAttackMultiResult
end

local function ClearWeaponData(self)
    Timer.StopOwnerAllTimer(self, true)

    if(self.bServer and self.Owner.CustomReplicationComponent:IsValid()) then
        self:OnClearAllRepData()
    end

    if self:IsReloading() then
        self:CancelReload()
    end
end 

function HumanWeaponGunBase:OnDestroyed()
    ClearWeaponData(self)
    HumanWeaponGunBase.super.OnDestroyed(self)
end

function HumanWeaponGunBase:OnServerUnHolded()
    ClearWeaponData(self)
end

function HumanWeaponGunBase:OnServerHolded()
    if AIHelper.IsAIControlled(self.Owner) then
        if self:GetCurrentAmmo() <= 0 then
            local tbProperty = self:GetProperty()
            if tbProperty and tbProperty.nReloadTime then
                local nReloadTime = tbProperty.nReloadTime
                self.OwnerComponent:Reload(nReloadTime)
            end
        end
    end
end

function HumanWeaponGunBase:ReloadImpInServer()
    if(not self.bServer) then
        return
    end

    if not self.Owner:IsAlive() then
        return false
    end
    local nCurrentAmmo, nMaxAmmo = self:GetAmmoInfo()
    -- logdebug("nCurrentAmmo", nCurrentAmmo, nMaxAmmo)
    if(nCurrentAmmo >= nMaxAmmo) then
        -- 子弹满了不允许reload
        log("Can't Reload nCurrentAmmo >= nMaxAmmo")
        return false    
    end
    local nRemain, nMax = HumanWeaponHelper.ReloadAmmo(self.nInstanceId)
    assert(nRemain ~= nil and nMax ~= nil)
    self:SetAmmoInfo(nRemain, nMax)

    if GlobalVariableSystem:IsServerLogic() then
        if  nRemain ~= nMax then
            logerror("HumanWeaponGunBase:ReloadImpInServer() failed", self.Owner:GetName(), self.nInstanceId)
        end
    end

    --通知观战对象弹药变化
    HumanWeaponHelper.SendWeaponAmmoInfoToViewers(self.OwnerComponent, self.nInstanceId)
    -- self.OwnerComponent:CancelReload()
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_RELOADED_DEACTIVATE, self.Owner:GetServerInstanceId())
    HumanWeaponHelper.ServerChangeWeaponState(self.Owner)
    return true
end

function HumanWeaponGunBase:Reload(nTime)
    if(not self.bServer) then
        return
    end

    -- if(Timer.IsOwnerTimerAlived(self, RELOAD_TIMER)) then
    --     return false
    -- end

    Timer.StartOwnerTimer(self, RELOAD_TIMER, self.ReloadImpInServer, nTime)
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_RELOADED_ACTIVATE, nTime, self.Owner:GetServerInstanceId())
    HumanWeaponHelper.ServerChangeWeaponState(self.Owner)
    return true
end

function HumanWeaponGunBase:CancelReload()
    if(not self.bServer) then
        return
    end
    HumanWeaponHelper.ServerChangeWeaponState(self.Owner)
    Timer.StopOwnerTimer(self, RELOAD_TIMER)
    Timer.StopOwnerTimer(self, CHEAT_ATTACK_TIMER)
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_RELOADED_DEACTIVATE, self.Owner:GetServerInstanceId())
end

function HumanWeaponGunBase:IsReloading()
    return Timer.IsOwnerTimerAlived(self, RELOAD_TIMER)
end


function HumanWeaponGunBase:GetRemainReloadingTime()
    if self:IsReloading() then
        local ReloadTimer = Timer.GetOwnerTimer(self, RELOAD_TIMER)
        return ReloadTimer:GetRemainingTime()
    end
    return 0
end

function HumanWeaponGunBase:OnAimChanged(bAiming)
    if(self.bAiming == bAiming) then
        return
    end

    self.bAiming = bAiming
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_AIM_CHANGED, bAiming, self.Owner)
    HumanWeaponHelper.ServerChangeWeaponState(self.Owner)
    -- 这里可以播枪械动画

    if self.pWeaponActor then
        HumanWeaponHelper.CheckAndPlayHoldToAim(self.Owner, bAiming)
        if self.pWeaponActor then
            HumanWeaponHelper.ChangeWeaponActorStateForAim(self.Owner, self.pWeaponActor, bAiming)
        end
    end
end

function HumanWeaponGunBase:IsAiming()
    return self.bAiming
end

function HumanWeaponGunBase:GetAmmoInfo()
    local nRemainAmmo = self.nRemainAmmo
    if(nRemainAmmo == nil) then
        nRemainAmmo, self.nMaxAmmo = HumanWeaponHelper.GetAmmoInfo(self.nInstanceId)
        if nRemainAmmo == 0 then
            logerror("HumanWeaponGunBase:GetAmmoInfo getting 0", self.nInstanceId, self.Owner:GetName())
        end
        self.nRemainAmmo = nRemainAmmo
    end

    LOG_AMMO_AMOUNT(self, "HumanWeaponGunBase:GetAmmoInfo")
    return nRemainAmmo, self.nMaxAmmo
end

function HumanWeaponGunBase:GetCurrentAmmo()
    local nRet, _ = self:GetAmmoInfo()
    return nRet
end

function HumanWeaponGunBase:SetCurrentAmmo(nAmmo)
    self.nRemainAmmo = nAmmo

    if nAmmo == 0 then
        LOG_AMMO_AMOUNT(self, "HumanWeaponGunBase:SetCurrentAmmo")
    end
end

function HumanWeaponGunBase:SetAmmoInfo(nRemainAmmo, nMaxAmmo)
    self.nRemainAmmo = nRemainAmmo
    self.nMaxAmmo = nMaxAmmo

    if nRemainAmmo == 0 then
        LOG_AMMO_AMOUNT(self, "HumanWeaponGunBase:SetAmmoInfo")
    end
end

function HumanWeaponGunBase:DecreaseAmmo(nCount)
    if(self:GetCurrentAmmo() < nCount or nCount <=0 ) then
        return false
    end

    HumanWeaponHelper.DecreaseAmmo(self.nInstanceId, nCount)
    HumanWeaponHelper.SendWeaponAmmoInfoToViewers(self.OwnerComponent, self.nInstanceId)
    self.nRemainAmmo = self.nRemainAmmo - nCount

    if GlobalVariableSystem:IsServerLogic() then
        local nAmmoStackCount, _ = HumanWeaponHelper.GetAmmoInfo(self.nInstanceId)
        if nAmmoStackCount ~= self.nRemainAmmo then
            logerror("HumanWeaponGunBase:DecreaseAmmo", self.nRemainAmmo, nAmmoStackCount, self.Owner:GetName())
        end
    end

    -- TODO: 观察模式代码
    -- local nViewerId = self.OwnerComponent:GetViewerInstanceId()
    -- if(nViewerId) then
    --     HumanWeaponHelper.SendAmmoCountToViewer(nViewerId, self.nRemainAmmo)
    -- end
    return true
end

function HumanWeaponGunBase:CheckAttackFrequency()
    if(self.Client) then
        return true
    end

    if GlobalVariableSystem:IsStandalone() then
        return true
    end

    if not self.Owner.ObjectType == GameObjectTypeDef.PlayerSelf then
        return true
    end

    if AIHelper.IsAIControlled(self.Owner) then
        return true
    end
    
    local tbWeaponProperty = self:GetProperty()
    local nCurrentTime = ExtendBlueprintFunctions:GetPlatformMilliseconds()
    if (nCurrentTime - self.nLastAttackTime < tbWeaponProperty.nRateOfFire * MILLISECONDS_PER_SECOND * TOLERANCE_PERCENTAGE) then
        log("Server ignoring attack due to attacking too frequently.")
        return false;
    end
    self.nLastAttackTime = nCurrentTime
    return true
end

-- 判断此次攻击是否合法，不合法返回原因，合法返回nil
function HumanWeaponGunBase:CheckAttackIllegal(StartPos, EndPos, Taker, nHitBodyType)
    local pPlayerController = self.Owner.pUEActor:GetController()
    if not pPlayerController then
        return nil
    end
    local pCameraLocation, _ = EngineExtActorShell.GetPlayerViewPoint(pPlayerController)
    local nRetReason = ExtendBlueprintFunctions.CheckAttackIllegal(GWorld, StartPos, pCameraLocation)
    local szReason = nil
    if nRetReason == IllegalAttackReasonDef.ThroughWall then
        szReason = string.format(THROUGH_WALL_FORMAT, StartPos.X, StartPos.Y, StartPos.Z, pCameraLocation.X, pCameraLocation.Y, pCameraLocation.Z)
    end

    return szReason
end

function HumanWeaponGunBase:CheckAttackIllegalOnFire(pMuzzleLoc)
    if(self.Client) then
        return nil
    end

    if GlobalVariableSystem:IsStandalone() then
        return nil
    end

    if not self.Owner.ObjectType == GameObjectTypeDef.PlayerSelf then
        return nil
    end

    if AIHelper.IsAIControlled(self.Owner) then
        return nil
    end
    
    local pShooterLoc = self.Owner:GetLocation()
    local nMuzzleDistance = ExtendBlueprintFunctions.GetVectorToVectorDistance(pMuzzleLoc, pShooterLoc)
    local szReason = nil
    if nMuzzleDistance > MAX_MUZZLE_DISTANCE then
        szReason = string.format(MUZZLE_TOO_FAR_FORMAT, nMuzzleDistance, pMuzzleLoc.X, pMuzzleLoc.Y, pMuzzleLoc.Z, pShooterLoc.X, pShooterLoc.Y, pShooterLoc.Z)
    end
    return szReason
end

-- 判断此次攻击是否命中
function HumanWeaponGunBase:CheckAttackHit(StartPos, EndPos, Taker, nHitBodyType)
    if( not HumanWeaponHelper.CanBeAttacked(Taker) or (GameObjectSystem:IsCharacter(Taker) and Taker:IsHuman() and nHitBodyType == 0)) then
        return false
    end

    if(self.Client) then
        return true
    end

    if GlobalVariableSystem:IsStandalone() then
        return true
    end

    if not self.Owner.ObjectType == GameObjectTypeDef.PlayerSelf then
        return true
    end

    if not Taker then
        return
    end

    if Taker.ObjectType == GameObjectTypeDef.DestructibleObject then
        return true
    end

    if AIHelper.IsAIControlled(self.Owner) then
        return true
    end

    if not (StartPos and EndPos) then
        log("HumanWeaponGunBase:CheckAttackHit, StartPos or EndPos is nil.")
        return false
    end

    local tbWeaponProperty = self:GetProperty()

    local nAttackRange = tbWeaponProperty.nEffectiveRange * 100
    pEndPos.X = StartPos.X + EndPos.X * nAttackRange
    pEndPos.Y = StartPos.Y + EndPos.Y * nAttackRange
    pEndPos.Z = StartPos.Z + EndPos.Z * nAttackRange
    pStartPos.X = StartPos.X
    pStartPos.Y = StartPos.Y
    pStartPos.Z = StartPos.Z
    -- destroyUserData(StartPos)
    -- destroyUserData(EndPos)

    local pUEActor = self.pOwnerActor
    local pShooterLoc = pUEActor:K2_GetActorLocation()
    local pShooterRot = pUEActor:K2_GetActorRotation()
    local nRangeType = RANGE_TYPE.SECTOR
    local pCheckLoc = pShooterLoc
    local tbRangeParams = {nAttackRange, SECTOR_ANGLE}
    local nMaxBulletCountOnceTime = self:GetOwnerProperty(PropName.nBulletCostPerAttack) * self:GetOwnerProperty(PropName.nBulletCountPerAttack)
    if nMaxBulletCountOnceTime == 1 then
        nRangeType = RANGE_TYPE.RECT
        tbRangeParams = {nAttackRange, RANGE_BOX_Y}
        pCheckLoc = ExtendBlueprintFunctions.GetForwardLocationByDistance(pShooterLoc, pShooterRot, nAttackRange / 2)
    end
    local bFindTaker = false
    local tbRetPawns = BattleAbilitySystem:GetPawnsInRange(pCheckLoc, pShooterRot, nRangeType, tbRangeParams)
    if tbRetPawns then
        for _, pPawn in ipairs(tbRetPawns) do
            if pPawn == Taker then
                bFindTaker = true
                break
            end
        end
    end
    if not bFindTaker then
        local pTakerPos = Taker:GetLocation()
        local szLogMessage = string.format(NOT_FIND_TAKER_FORMAT, Taker.szName, pShooterLoc.X, pShooterLoc.Y, pShooterLoc.Z, pTakerPos.X, pTakerPos.Y, pTakerPos.Z)
        log(szLogMessage)
        return false
    end
    destroyUserData(pShooterLoc)
    destroyUserData(pShooterRot)
    local szReason = self:CheckAttackIllegal(pStartPos, pEndPos, Taker, nHitBodyType)
    if(szReason ~= nil) then
        HumanWeaponHelper.OnIllegalAttack(self.Owner, szReason)
        -- CheaterCheckSystem:RecordCheating(self.Owner, CheatingTypeDef.ILLEGAL_ATTACK)
        return false
    end

    return true
end

function HumanWeaponGunBase:AttackOnceInServer(nTakerId, StartPos, EndPos, nHitBodyType, szDamageType)
    logdebug("lz attack once 3")
    local Owner = self.Owner
    local tbProperty = self:GetProperty()
    local nDamage = self:GetOwnerProperty(PropName.nDamagePerAttack)
    local nInstanceId = self.nInstanceId
    if(not self:DecreaseAmmo(self:GetOwnerProperty(PropName.nBulletCostPerAttack))) then
        return
    end
    local Taker = GameObjectSystem:FindByInstanceId(nTakerId)
    if(Taker == nil) then
        return
    end
    if not self:CheckAttackFrequency() then
        return
    end
    tbTempEnds[1] = EndPos
    tbTempNotify.weapon_id = nInstanceId
    tbTempNotify.start = StartPos
    tbTempNotify.end_pos = EndPos
    if(self:CheckAttackHit(StartPos, EndPos, Taker, nHitBodyType)) then
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
    tbTempNotify = {}

    HumanWeaponHelper.ServerAttackEvent(Owner, nInstanceId)
end

function HumanWeaponGunBase:AttackMultiInServer(tbTakers, StartPos, tbAttackEnds, tbHitBodyTypes, tbMissEnds, tbOriginalHitTypes)
    local EndPos, nHitBodyType, Taker
    local nCount 
    if tbAttackEnds then 
        nCount = #tbAttackEnds
    else  
        nCount = #tbTakers
    end
    local Owner = self.Owner
    local nInstanceId = self.nInstanceId
    local tbProperty = self:GetProperty()
    local nDamage = self:GetOwnerProperty(PropName.nDamagePerAttack) 
    assert(nCount == #tbTakers)

    if(not self:DecreaseAmmo(self:GetOwnerProperty(PropName.nBulletCostPerAttack))) then
        return
    end

    if not self:CheckAttackFrequency() then
        return
    end

    if(tbMissEnds == nil) then
        tbMissEnds = {}
    end

    local tbResult = {}
    tbResult.weapon_id = nInstanceId
    tbResult.start = StartPos
    tbResult.miss_ends = tbMissEnds
    if tbOriginalHitTypes then 
        -- logdebug("AttackMultiInServer", #tbOriginalHitTypes)
        tbResult.hit_types = tbOriginalHitTypes
    end

    local tbHitTakers, tbHitEnds
    for i=1, nCount do
        Taker = GameObjectSystem:FindByInstanceId(tbTakers[i])
        if(Taker ~= nil) then
            if tbAttackEnds then 
                EndPos = tbAttackEnds[i]
            end
            nHitBodyType = tbHitBodyTypes[i]

            if(self:CheckAttackHit(StartPos, EndPos, Taker, nHitBodyType)) then
                TakeDamage(Taker, nDamage, Owner, tbProperty, nHitBodyType)
                if(tbHitTakers == nil) then
                    tbHitTakers = {}
                    tbHitEnds = {}
                    tbResult.takers = tbHitTakers
                    tbResult.hit_ends = tbHitEnds
                end
                table.insert(tbHitTakers, Taker:GetServerInstanceId())
                if EndPos then 
                    table.insert(tbHitEnds, EndPos)
                end
            else
                if EndPos then 
                    table.insert(tbMissEnds, EndPos)
                end
            end
        end
    end
    self.OwnerComponent:OnDamageEnd()
    self:RepAttack(self.rHumanGunAttackMultiResult, tbResult)

    HumanWeaponHelper.ServerAttackEvent(Owner, nInstanceId)
end

function HumanWeaponGunBase:OnClearAllRepData()
    self.rHumanGunAttackRoute:Set(nil)
    self.rHumanGunAttackOnceResult:Set(nil)
    self.rHumanGunAttackMultiResult:Set(nil)
end

function HumanWeaponGunBase:RepAttack(rProperty, tbRepData)
    rProperty:Set(tbRepData)
    Timer.StartOwnerTimer(self, REP_CLEAR_TIMER, self.OnClearAllRepData, self.REP_PROPERTY_CLEAR_TIME)
    EventManager:OnFireEvent(CommonEventDef.EV_PERCEPTION_WEAPON_FIRE_SOUND, self.Owner:GetServerInstanceId())
end

function HumanWeaponGunBase:RouteAttack(tbRepData)
    assert(self.bServer)
    -- local tbProperty = self:GetProperty()
    if(not self:DecreaseAmmo(self:GetOwnerProperty(PropName.nBulletCostPerAttack))) then
        return
    end
    local nCategory = HumanWeaponHelper.GetWeaponCategory(self.nTemplateId)
    local TorpedoTriggerType = self.pOwnerActor:ConvertWeaponTypeToTorpedoTriggerType(nCategory)
    for i,v in ipairs(tbRepData.ends) do
        TableToVector(v)
        ShipUtilityExHelper.TriggerTorpedoBySphere(TorpedoTriggerType, pStartPos, BULLET_RADIUS, GWorld)
    end

    self:RepAttack(self.rHumanGunAttackRoute, tbRepData)

    HumanWeaponHelper.ServerAttackEvent(self.Owner, self.nInstanceId)
end

-- 专门为服务器发起的攻击使用，多用于ai，如果未打中szDamageType请填nil
function HumanWeaponGunBase:CheatAttack(Target, szDamageType)
    assert(self.bServer)
    if self:GetCurrentAmmo() <= 0 then
        return
    end
    local tbProperty = self:GetProperty()
    local TargetObject = nil
    if Target then
        local nUniqueId = EngineExtActorShell.GetActorUniqueId(Target)
        TargetObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    end

    local StartPos = self.pOwnerActor:GetActorEyesViewPoint()
    local StartPosTemp = VectorToTempTable1(StartPos)
    local Dir = self.pOwnerActor:GetBaseAimRotation()
    Dir = KismetMathLibrary.Conv_RotatorToVector(Dir)
    local tbRepData = {}
    tbRepData.weapon_id = self.nInstanceId
    tbRepData.start = StartPosTemp
    tbRepData.ends = {VectorToTempTable2(Dir)}
    pStartPos.X = StartPos.X
    pStartPos.Y = StartPos.Y
    pStartPos.Z = StartPos.Z
    destroyUserData(StartPos)
    destroyUserData(Dir)
    
    if szDamageType and TargetObject then
        local nState = nil
        if TargetObject.HumanMovementStateComponent then
            nState = TargetObject.HumanMovementStateComponent:GetCurrentState()
        end
        local EndPos = HumanWeaponHelper.GetLocationByHitTypeAndMovementState(Target, szDamageType, nState)
        if EndPos ~= nil then
            Dir = KismetMathLibrary.GetDirectionUnitVector(pStartPos, EndPos)
            
            local Distance = KismetMathLibrary.VSize(KismetMathLibrary.Subtract_VectorVector(EndPos, pStartPos))
            local bBlocked = true 
            local BulletRange = tbProperty.nEffectiveRange*100
            if Distance <  BulletRange then 
                 bBlocked = self.pOwnerActor:CheckAttackBlocked(pStartPos, EndPos)
            end
            -- EndPos = VectorToTempTable2(Dir)
            destroyUserData(EndPos)
            if not bBlocked and HumanWeaponHelper.CanBeAttacked(TargetObject) and (not TargetObject:IsDead()) then
                -- Will get EndPos according to szDamageType in client
                local nAttackCount = self:GetOwnerProperty(PropName.nBulletCostPerAttack) * self:GetOwnerProperty(PropName.nBulletCountPerAttack)
                if(GlobalVariableSystem.bEnableAIGameCore and nAttackCount > 1) then
                    local nCount = MathUtil.Round( MathUtil.Power(1 -(Distance / BulletRange), 5) * nAttackCount)
                    local tbHitTypes = {}
                    local tbTackers = {}
                    local tbOriginalHitTypes = {}
                    local nHitType = HumanWeaponHelper.GetHitType(szDamageType)
                    local nOriginalHitType = HumanWeaponHelper.GetHumanPartProperty(szDamageType)
                    for i = 1, nCount do
                       table.insert(tbHitTypes, nHitType) 
                       table.insert(tbTackers, TargetObject.nServerInstanceId) 
                       table.insert(tbOriginalHitTypes, nOriginalHitType) 
                    end
                    --  self:AttackMultiInServer(tbHitTakers, pStartPos, tbHitEnds, tbHitTypes, tbMissEnds)
                     self:AttackMultiInServer(tbTackers, StartPosTemp, nil, tbHitTypes, nil, tbOriginalHitTypes)
                else 
                    logdebug("lz attack once 4")
                    self:AttackOnceInServer(TargetObject.nServerInstanceId, StartPosTemp, nil, HumanWeaponHelper.GetHitType(szDamageType), szDamageType)
                end
            else
                tbRepData.ends = {VectorToTempTable2(Dir)}
                destroyUserData(Dir)
                self:RouteAttack(tbRepData)
            end
        else
            self:RouteAttack(tbRepData)
        end
    else
        self:RouteAttack(tbRepData)
    end
    local nAttackDuration = tbProperty.nRateOfFire
    local nReloadTime = tbProperty.nReloadTime
    Timer.StartOwnerTimer(self, CHEAT_ATTACK_TIMER, function()
        self.OwnerComponent:Reload(nReloadTime)
    end, nAttackDuration)
end

function HumanWeaponGunBase:GetMinAttackIntervalTime()
    local tbWeaponProperty = self:GetProperty()
    local nIntervalTime = tbWeaponProperty.nRateOfFire * MILLISECONDS_PER_SECOND * TOLERANCE_PERCENTAGE
    return nIntervalTime
end

return HumanWeaponGunBase