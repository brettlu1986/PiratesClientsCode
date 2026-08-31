local luaclass = require("luaclass")
local HumanWeaponBow = dynamic_require("HumanWeaponBow")
local HumanWeaponWand = luaclass("HumanWeaponWand", HumanWeaponBow)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local HumanBodyDef = require("HumanBodyDef")
local TakeDamage = require("HDC_HumanBulletNew")
local GameCurveHelper = require("GameCurveHelper")
local CurveDef = require("CurveDef")
local PropName = require("PropName")
local HumanWeaponHelper = require("HumanWeaponHelper")
local Timer = require("Timer")
local GetVectorToVectorDistance = ExtendBlueprintFunctions.GetVectorToVectorDistance
local DOOR_PATH = "Blueprint'/Game/Game/OtherObject/DestructibleObject/BP_DoorBase.BP_DoorBase_C'"
local WINDOW_PATH = "Blueprint'/Game/Game/OtherObject/DestructibleObject/BP_WindowBase.BP_WindowBase_C'"
local ATTACK_RANGE_ADDTO_DOOR = 100
local CHEAT_ATTACK_TIMER = "CheatAttackTimer"


local pStartPos = Vector()
local tbTemp1 = {}
local tbTemp2 = {}

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

function HumanWeaponWand:AttackMultiInServer(tbTakers, StartPos, tbAttackEnds, tbHitBodyTypes, tbMissEnds, tbOriginalHitTypes, tbIndexes)
    local tbProperty = self:GetProperty()

    local nDamage = self:GetOwnerProperty(PropName.nDamagePerAttack)
    local Owner = self.Owner
    local nInstanceId = self.nInstanceId
    local Taker
    local tbResult = {}
    tbResult.weapon_id = nInstanceId
    tbResult.start = StartPos
    tbResult.miss_ends = tbMissEnds
    tbResult.hit_ends = tbAttackEnds

    pStartPos.X = StartPos.X
    pStartPos.Y = StartPos.Y
    pStartPos.Z = StartPos.Z
    self:TriggerTorpedoBySphere(StartPos)
    local nFireballExplosiveOutsideRadius = self:GetOwnerProperty(PropName.nFireballExplosiveOutsideRadius)
    local nFireballExplosiveInnerRadius = self:GetOwnerProperty(PropName.nFireballExplosiveInnerRadius)
    local tbHitTakers

    if not self:CheckAttackFrequency() then
        return
    end

    local DamageRatio = 0
    local RealDamage = nDamage
    local alpha = 0
    for i,v in ipairs(tbTakers) do
        Taker = GameObjectSystem:FindByInstanceId(v)
        if Taker then 
            local TakerLocation = Taker:GetLocation()

            local Distance = GetVectorToVectorDistance(pStartPos, TakerLocation)
            local nIndex = 0
            if tbIndexes and tbIndexes[1] then
                nIndex = tbIndexes[1]
            end
            local StartAttackPos = self.tbStartAttackPoses[nIndex]
            log("Wand Damage Distance", Distance, nFireballExplosiveOutsideRadius)
            if(Distance < nFireballExplosiveOutsideRadius and self:CheckAttackHit(StartAttackPos, StartPos, Taker, HumanBodyDef.HUMAN_BODY)) then
                RealDamage = nDamage
                DamageRatio = 0
                alpha = 0
                if Distance > nFireballExplosiveInnerRadius then 
                    alpha = Distance / nFireballExplosiveOutsideRadius

                    DamageRatio = GameCurveHelper.GetValue(CurveDef.CurveIds.CURVE_LOCATION_TORADIUS_DAMAGE, alpha)
                    RealDamage = nDamage * DamageRatio
                end
                log("Wand Damage DamageRatio", DamageRatio, "nDamage", nDamage, "Distance", Distance, "RealDamage", RealDamage, "alpha", alpha)
                TakeDamage(Taker, RealDamage, Owner, tbProperty, HumanBodyDef.HUMAN_BODY)
                if(tbHitTakers == nil) then
                    tbHitTakers = {}
                    tbResult.takers = tbHitTakers
                end            
                table.insert(tbHitTakers, Taker:GetServerInstanceId())
            end
        end
    end
    self.OwnerComponent:OnDamageEnd()
    self:RepAttack(self.rHumanGunAttackMultiResult, tbResult)
end

-- function HumanWeaponWand:CheckAttackHit(StartPos, EndPos, Taker, nHitBodyType)
--     if( not HumanWeaponHelper.CanBeAttacked(Taker) or (GameObjectSystem:IsCharacter(Taker) and Taker:IsHuman() and nHitBodyType == 0)) then
--         return false
--     end
--     return true
-- end 

local GetActorsInSectorRange  = ExtendBlueprintFunctions.GetActorsInSectorRange
function HumanWeaponWand:GetTakerIdsAndHitEnds(StartPos, Dir)
    if not StartPos then
        return 
    end
    local pUEActor = self.pOwnerActor
    local pLocation = StartPos 
    local pRotation = self.Owner:GetRotation()
    local pDoorClass = DOOR_PATH:load()
    local nFireballExplosiveOutsideRadius = self:GetOwnerProperty(PropName.nFireballExplosiveOutsideRadius)
    local OutDoors = GetActorsInSectorRange(GWorld, pDoorClass, pLocation, pRotation, nFireballExplosiveOutsideRadius + ATTACK_RANGE_ADDTO_DOOR, 360)
    local pWindowClass = WINDOW_PATH:load()
    local OutWindows = GetActorsInSectorRange(GWorld, pWindowClass, pLocation, pRotation, nFireballExplosiveOutsideRadius, 360)
    local OutActors = GetActorsInSectorRange(GWorld, Pawn, pLocation,  pRotation, nFireballExplosiveOutsideRadius, 360)
    for i, v in ipairs(OutDoors) do
        table.insert(OutActors, v)
    end
    for i, v in ipairs(OutWindows) do
        table.insert(OutActors, v)
    end    
    -- logdebug("nFireballExplosiveOutsideRadius", nFireballExplosiveOutsideRadius, pLocation.X, pLocation.Y, pLocation.Z)

    local tbTakerIds, tbTaker
    local tbHitEnds = {}
    table.insert(tbHitEnds, Dir)
    for _, v in ipairs(OutActors) do
        if v ~= pUEActor then
            tbTaker = GameObjectSystem:FindByUEActor(v)
            if tbTaker and HumanWeaponHelper.CanBeAttacked(tbTaker) and not tbTaker:IsDead() then
                if(tbTakerIds == nil) then
                    tbTakerIds = {}
                end
                table.insert(tbTakerIds, tbTaker:GetServerInstanceId())
            else  
                if not tbTaker then 
                    log("Can't Find Hit Player ")
                else  
                    log("Player is Dead ", tbTaker.szName)
                end 
            end
        end
    end

    return tbTakerIds, tbHitEnds
end

function HumanWeaponWand:ApplyCheatAttack()
    if not self.tbCheatAttackList or #self.tbCheatAttackList == 0 then
        return
    end

    local CheatAttackTimer = Timer.GetOwnerTimer(self, CHEAT_ATTACK_TIMER)
    if CheatAttackTimer then
        return
    end

    local nCurrentTime = ExtendBlueprintFunctions:GetPlatformMilliseconds()
    local tbCheatAttackInfo = table.remove(self.tbCheatAttackList)
    local nTime =  0.5
    local StartPos = tbCheatAttackInfo.StartPos
    local EndPos = tbCheatAttackInfo.EndPos
    local tbDir = tbCheatAttackInfo.tbRepData.ends[1]
    local Direction = KismetMathLibrary.MakeVector(tbDir.X, tbDir.Y, tbDir.Z)
    local BulletRange = self:GetOwnerProperty(PropName.nAttackRegion) * 100
    if not EndPos or not EndPos.X then
        EndPos = KismetMathLibrary.MakeVector(
            StartPos.X + Direction.X * BulletRange,
            StartPos.Y + Direction.Y * BulletRange,
            StartPos.Z + Direction.Z * BulletRange
        )
    end

    if tbCheatAttackInfo.szDamageType and tbCheatAttackInfo.nTargetUniqueId then
        local Distance = KismetMathLibrary.VSize(Direction)

        nTime = Distance / (tbCheatAttackInfo.nInitialSpeed / 1000)   -- ms
        nTime = nTime - (nCurrentTime - tbCheatAttackInfo.nStartTime) -- ms
        nTime = nTime / 1000
    else
        nTime = nTime - (nCurrentTime - tbCheatAttackInfo.nStartTime) / 1000
    end

    Timer.StartOwnerTimer(self, CHEAT_ATTACK_TIMER, function()
        local bBlocked = self.pOwnerActor:CheckAttackBlocked(StartPos, EndPos)
        local tbTakerIds, tbHitEnds = self:GetTakerIdsAndHitEnds(EndPos, tbDir)

        if tbTakerIds and (not bBlocked) then
            self:AttackMultiInServer(tbTakerIds, VectorToTempTable1(EndPos), tbHitEnds, nil, {})
        else
            local tbRepData = tbCheatAttackInfo.tbRepData
            tbRepData.start = VectorToTempTable1(StartPos)
            tbRepData.ends[1] = VectorToTempTable2(EndPos)
            self:RouteProjectAttack(tbCheatAttackInfo.tbRepData)
        end
        Timer.StopOwnerTimer(self, CHEAT_ATTACK_TIMER)
        self:ApplyCheatAttack(self)
    end, nTime)
end

function HumanWeaponWand:GetAmmoInfo()
    local nRemainAmmo = self.nRemainAmmo
    if(nRemainAmmo == nil) then
        nRemainAmmo, self.nMaxAmmo = HumanWeaponHelper.GetAmmoInfo(self.nInstanceId)
        self.nRemainAmmo = nRemainAmmo
    end
    return 1, 1
end

function HumanWeaponWand:DecreaseAmmo(nCount)
    return true
end

function HumanWeaponWand:RouteAttack(tbRepData)
    local nFireballExplosiveOutsideRadius = self:GetOwnerProperty(PropName.nFireballExplosiveOutsideRadius)
    self.nBulletRadiusForTorpedo = nFireballExplosiveOutsideRadius
    HumanWeaponWand.super.RouteAttack(self, tbRepData)
end

return HumanWeaponWand