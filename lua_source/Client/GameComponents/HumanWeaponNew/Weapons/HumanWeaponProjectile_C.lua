local luaclass = require("luaclass")
local HumanWeaponProjectile = require("HumanWeaponProjectile")
local HumanWeaponProjectile_C = luaclass("HumanWeaponProjectile_C", HumanWeaponProjectile)
local HumanWeaponHelper = require("HumanWeaponHelper")
local CppDelegate = require("CppDelegate")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local Timer = require("Timer")
local AutoBattleSystem = require("AutoBattleSystem")
local DELAY_RELOAD_CLIENT = "DelayReloadClient"
local HumanWeaponDef = require("HumanWeaponDef")
local PropName = require("PropName")
local WeaponCategory = HumanWeaponDef.WeaponCategory

HumanWeaponProjectile_C.OnWeaponHitActorHandler = nil
HumanWeaponProjectile_C.bAutoClearReload = true
HumanWeaponProjectile_C.nCurrentProjectileIndex = 1

local tbTemp1 = {}
local tbTemp2 = {}
local tbTempAttckOncePacket = {}
local TempTable = {}

local MAX_PROJECTILE_INDEX = 100

local tbVector = Vector{X=0, Y=0, Z=0}
local tbVector2 = Vector{X=0, Y=0, Z=0}
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

local function TableToVector(Vector)
    CopyVector(tbVector, Vector)
    return tbVector
end

local function TableToVector2(Vector)
    CopyVector(tbVector2, Vector)
    return tbVector2
end

local function RotateShotDir(self, OriginDir)
    tbVector2.X = OriginDir.Y
    tbVector2.Y = - OriginDir.X
    tbVector2.Z = 0
    local TempAxisVector = KismetMathLibrary.Normal(tbVector2, GDefaultTolerance)
    local nAlpha = self:GetProperty().nProjectileFireAngle
    if nAlpha then
        return KismetMathLibrary.RotateAngleAxis(OriginDir, nAlpha, TempAxisVector)
    else
        return OriginDir
    end
end

local function WeaponAttack(self, StartPos, ShotDir)
    local nCurrentProjectileIndex = self.nCurrentProjectileIndex
    self.pWeaponActor:AttackClient(StartPos, ShotDir, nCurrentProjectileIndex)
    self.nCurrentProjectileIndex = self.nCurrentProjectileIndex + 1
    if self.nCurrentProjectileIndex >= MAX_PROJECTILE_INDEX then
        self.nCurrentProjectileIndex = 1
    end
    return nCurrentProjectileIndex
end

local function AttackOnce(self, tbProperty)
    local pWeaponActor = self.pWeaponActor
    -- local StartPos, EndPos, _ShotDir, pHitResult, bHit = pWeaponActor:CalculateHit()
    local StartPos, ShotDir = pWeaponActor:GetShootDir()
    ShotDir = RotateShotDir(self, ShotDir)
    TempTable[1] = WeaponAttack(self, StartPos, ShotDir)
    StartPos = VectorToTempTable1(StartPos)
    ShotDir = VectorToTempTable2(ShotDir)
    if(not self.bServer) then
        -- HumanWeaponHelper.SendGunAttackRoute(self.nInstanceId, StartPos, ShotDir, false)
        self:RequestGunAttackRoute(StartPos, ShotDir, false, TempTable)
    else 
        self:DecreaseAmmo(self:GetOwnerProperty(PropName.nBulletCostPerAttack))
    end
end


local function AttackMulti(self, tbProperty, nAttackCount)
    local pWeaponActor = self.pWeaponActor
    local StartPos = nil
    local tbDirs = {}
    local tbIndexes = {}
    for i=1, nAttackCount do
        pWeaponActor.CurrentBulletIndex = i - 1
        local ShotDir = nil
        StartPos, ShotDir = pWeaponActor:GetShootDir()
        table.insert(tbIndexes, WeaponAttack(self, StartPos, ShotDir))
        StartPos = VectorToTempTable1(StartPos)
        table.insert(tbDirs, VectorToTempTable2(ShotDir))

    end
    -- HumanWeaponHelper.SendGunAttackRoute(self.nInstanceId, StartPos, tbDirs, true)
    self:RequestGunAttackRoute(StartPos, tbDirs, true, tbIndexes)
end

function HumanWeaponProjectile_C:RequestGunAttackRoute(StartPose, ShotDir, bMultiEnd, tbIndexes)
    HumanWeaponHelper.SendGunAttackRoute(self.nInstanceId, StartPose, ShotDir, bMultiEnd, nil, tbIndexes)
end 

function HumanWeaponProjectile_C:AttackInClient(tbAttackInfo)
    self:FillBPAttackParams(tbAttackInfo)
    local tbProperty = self:GetProperty()
    local nAttackCount = self:GetOwnerProperty(PropName.nBulletCostPerAttack) * self:GetOwnerProperty(PropName.nBulletCountPerAttack)
    
    if(nAttackCount > 1) then
        AttackMulti(self, tbProperty, nAttackCount)
    else
        AttackOnce(self, tbProperty)
    end
    if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) ~= WeaponCategory.ThrowWeapon then  
        self:ShakeCamera()
    end
    HumanWeaponProjectile_C.super.AttackInClient(self, tbAttackInfo)
end

function HumanWeaponProjectile_C:OnRepGunAttackRoute(tbRepData)
    if(tbRepData == nil) then
        return
    end
    if(self.bSelf and not AutoBattleSystem:InAutoBattle() ) then
        return
    end
    local pWeaponActor = self.pWeaponActor
    if not pWeaponActor then
        return
    end
    self:PlayAttackMontage()
    pWeaponActor:PlayAttackEffect()
    self:FillBPAttackParams(nil)
    local StartPos = TableToVector(tbRepData.start)

    for k,v in pairs(tbRepData.ends) do
        local ShotDir = TableToVector2(v)
        pWeaponActor:AttackClient(StartPos, ShotDir, 0)
    end

    -- self:OnHitNotifies(tbRepData.start, tbRepData.ends)
end

function HumanWeaponProjectile_C:OnRepPorjectGunAttackRoute(tbRepData)
    if(tbRepData == nil) then
        return
    end
    self:OnHitNotifies(tbRepData.start, tbRepData.ends)
end

function HumanWeaponProjectile_C:OnHitActor(StartPos, EndPos, pHitResult, nProjectileIndex)
    local bHit = pHitResult.bBlockingHit
    local Taker
    if bHit and pHitResult.Actor then
        Taker = GameObjectSystem:FindByUEActor(pHitResult.Actor)
        bHit = Taker ~= nil
        if not HumanWeaponHelper.CanBeAttacked(Taker) or Taker and Taker:IsDead() then
            bHit = false
        end
    end
    StartPos = VectorToTempTable1(StartPos)
    -- local EndPos = VectorToTempTable2(pHitResult.ImpactPoint)
    EndPos = VectorToTempTable2(EndPos)
    if(bHit) then
        local nTakerId = Taker:GetServerInstanceId()
        local nHitBodyType = HumanWeaponHelper.GetHitBodyType(pHitResult)
        if(self.bServer) then
            -- 单机逻辑
            logdebug("lz attack once 2")
            self:AttackOnceInServer(nTakerId, StartPos, EndPos, nHitBodyType, nil, nProjectileIndex)
        else
            HumanWeaponHelper.SendGunAttackOnceRequest(self.nInstanceId, nTakerId, StartPos, EndPos, nHitBodyType, nProjectileIndex)
        end
    else
        -- TODO other 命中
        if(not self.bServer) then
            TempTable[1] = nProjectileIndex
            HumanWeaponHelper.SendProjectAttackRoute(self.nInstanceId, StartPos, EndPos, false, TempTable)
        end

        -- -- 本地播命中特效
        -- EndPos = VectorToTempTable2(HitDir)
        tbTempAttckOncePacket[1] = EndPos
        self:OnHitNotifies(StartPos, tbTempAttckOncePacket)
    end
end

function HumanWeaponProjectile_C:OnRepGunAttackOnceResult(tbRepData)
    if(tbRepData == nil) then
        return
    end
    -- Projectile的动画在OnRepGunAttackRoute里播
    TempTable[1] = tbRepData.end_pos
    if tbRepData.hit_type and tbRepData.hit_type > 0 then
        local tbTackers = {tbRepData.taker}
        local szDamageType = HumanWeaponHelper.GetHumanPartPropertyName(tbRepData.hit_type)
        local TempTable2 = {}
        TempTable2[1] = szDamageType
        self:OnHitNotifies(tbRepData.start, TempTable, tbTackers, TempTable2)
    else
        self:OnHitNotifies(tbRepData.start, TempTable)
    end
end

function HumanWeaponProjectile_C:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponProjectile_C.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)
    if self.bSelf then 
        self.OnWeaponHitActorHandler = CppDelegate:BindMethod(self.pWeaponActor.OnHitActor, self, self.OnHitActor)
    end
end
function HumanWeaponProjectile_C:OnDestroyed()
    if self.OnWeaponHitActorHandler then
        self.OnWeaponHitActorHandler:Unbind()
        self.OnWeaponHitActorHandler = nil
    end
    HumanWeaponProjectile_C.super.OnDestroyed(self)
    Timer.StopOwnerAllTimer(self, true)
end

local function DelayReloadClient(self)
    if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) ~= WeaponCategory.ThrowWeapon then  
        self.pWeaponActor:ReloadClient()
    end
end

function HumanWeaponProjectile_C:OnStateActivate(nState)
    HumanWeaponProjectile_C.super.OnStateActivate(self, nState)

    if(nState == HumanWeaponStateDef.RELOADING) then
        if(not self.bServer) then
            Timer.StartOwnerTimer(self, DELAY_RELOAD_CLIENT, DelayReloadClient, 0.1)
        end
    end
end

function HumanWeaponProjectile_C:OnStateDeactivate(nState, bCancel)
    HumanWeaponProjectile_C.super.OnStateDeactivate(self, nState, bCancel)

    -- 单机逻辑
    if(nState == HumanWeaponStateDef.RELOADING) then
        if(self.bAutoClearReload and not self.bServer) then
            local pWeaponActor = self.pWeaponActor
            pWeaponActor:ClearReload()
            Timer.StopOwnerTimer(self, DELAY_RELOAD_CLIENT)
        end
    end
end

return HumanWeaponProjectile_C