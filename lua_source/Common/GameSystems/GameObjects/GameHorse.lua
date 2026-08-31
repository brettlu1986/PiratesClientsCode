local luaclass = require("luaclass")
local GameObjectClass = dynamic_require("GameVehicle")
local GameHorse = luaclass("GameHorse", GameObjectClass)
local GameObjectTypeDef = require("GameObjectTypeDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local PropName = require("PropName")
local Timer = require("Timer")
local AIHelper = require("AIHelper")
local DamageTypeEx = require("DamageTypeEx")
local CommonEventDef = require("CommonEventDef")
local SelfEventHelper = require("SelfEventHelper")
local VehicleDataTable = require("VehicleDataTable")
local AnimationResDataTable = require("AnimationResDataTableNew")

GameHorse.EventHelper = nil
GameHorse.bDriving = false

local FRIGHTENED_ANIM_KEY = "HorseFrightened"
local FRIGHTENED_TIMER = "FRIGHTENED_TIMER"
local FRIGHTENED_ANIM_TIMER = "FRIGHTENED_ANIM_TIMER"

local ENUM_RotDirection = {
    None = 0,
    Left = 1,
    Right = 2,
}

local TempVector = Vector()

local function ResetRotationSpeed(self)
    local tbVehicleData = VehicleDataTable:GetTemplate(self:GetTemplateId())
    local pVehicleActor = self.pUEActor
    pVehicleActor:InitMoveRightValue(
        tbVehicleData.nForwardRotVel,
        tbVehicleData.nBackRotVel,
        tbVehicleData.nStandRotVel,
        tbVehicleData.nRotAccelaration,
        tbVehicleData.nRotDeceleration,
        tbVehicleData.nRotDecelerationMinVel
    )
end

local function  LOG(self, ...)
    log("[Vehicle] [GameHorse]", self:GetServerInstanceId(), ...)
end

local function IsSwimmingVolume(nRegionType)
    if nRegionType ==EPiratesGridRegionType.Ocean or nRegionType ==EPiratesGridRegionType.Port or nRegionType ==EPiratesGridRegionType.Lake then
        return true
    end
    return false
end

local function OnTakeDamage(self, tbTaker, tbCauser, nDamage, nDamageType, nHp)
    if (not tbTaker) or self:GetServerInstanceId() ~= tbTaker:GetServerInstanceId() then
        return
    end

    if (not self:IsAlive()) or nDamage > nHp then
        -- 要死啦!
        return
    end

    if nDamageType == DamageTypeEx.POISON_CIRCLE then
        return
    end

    if GlobalVariableSystem:IsServerLogic() then
        self.pUEActor:SetIsFrightened(true)
    end
end

local function CheckFrightenedLocGridType(self)
    local Location = self:GetLocation()
    local Rotation = self:GetRotation()
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nCurRegionType = GridTypeManager:GetRegionType(Location.X, Location.Y)
    if IsSwimmingVolume(nCurRegionType) then
        if nCurRegionType ~= EPiratesGridRegionType.Shore then
            local bRet, NewLocation = GridTypeManager:GetClosestPositionOfRegionType(Location.X, Location.Y, EPiratesGridRegionType.Shore)
            if bRet then
                TempVector.X = NewLocation.X - Location.X
                TempVector.Y = NewLocation.Y - Location.Y
                TempVector.Z = 0
                local NewRotation = KismetMathLibrary.Conv_VectorToRotator(TempVector)
                NewRotation.Pitch = Rotation.Pitch
                NewRotation.Roll = Rotation.Roll
                LOG(self, "OnHorseFrightened CheckFrightenedLocGridType setting vehicle rotation old yaw=", Rotation.Yaw, " new yaw=", NewRotation.Yaw)
                self.pUEActor:K2_SetActorRotation(NewRotation)
            end
        end
    end
end

-- 被打到
local function OnHorseFrightened(self, bIsFrightened)
    if not bIsFrightened then
        return
    end
    if Timer.IsOwnerTimerAlived(self, FRIGHTENED_TIMER) then
        return
    end
    CheckFrightenedLocGridType(self)
    local pUEActor = self.pUEActor
    pUEActor:SetActorTickEnabled(true)
    pUEActor.CharacterMovement:SetComponentTickEnabled(true)
    LOG(self, "OnHorseFrightened start tick.")

    local tbVehicleData = VehicleDataTable:GetTemplate(self:GetTemplateId())
    local tbParams = {}
    tbParams.nTemplateId = tbVehicleData.nVehicleId
    tbParams.szAnimKey = FRIGHTENED_ANIM_KEY
    local tbAnimTemplate = AnimationResDataTable:GetTemplate(tbParams)
    local pAnimInstance = self.pUEActor.Mesh:GetAnimInstance()
    local pMontage = tbAnimTemplate.szAnimation:load()
    local nTime = pAnimInstance:Montage_Play(pMontage, 1.0, EMontagePlayReturnType.MontageLength, 0.0, false)
    local nMoveTime = tbVehicleData.nRunAwayTime

    local nDriverId = self.VehiclePropertyComponent:GetProp(PropName.nVehicleOwnerId)
    if GlobalVariableSystem:IsServerLogic() then
        if (not nDriverId) or nDriverId <= 0 then
            local nMinDuration = tbVehicleData.nRunAwayRotationTimeMin * 100
            local nMaxDuration = tbVehicleData.nRunAwayRotationTimeMax * 100
            local nDuration = math.random(nMinDuration, nMaxDuration) / 100
            local nDirection = math.random(0, 1) > 0.5 and ENUM_RotDirection.Right or ENUM_RotDirection.Left
            self.pUEActor.CharacterMovement.AnalogInputModifier = 1.0
            Timer.StartOwnerTimer(self, FRIGHTENED_ANIM_TIMER, function()
                self.pUEActor:FrightenedMove(nDuration, nDirection)
                LOG(self, "OnHorseFrightened FrightenedMove", nDuration, nDirection)
            end, nTime)
        else
            nMoveTime = tbVehicleData.nRunAwayTimeWithDriver
        end
        LOG(self, "OnHorseFrightened Start FRIGHTENED_TIMER", nTime + nMoveTime)
        Timer.StartOwnerTimer(self, FRIGHTENED_TIMER, function()
            pUEActor:OnFrightenedMoveEnd()
            LOG(self, "OnHorseFrightened OnFrightenedMoveEnd")
        end, nTime + nMoveTime)
    end
end

function GameHorse:ClearDriver(tbPlayer)
    self.bDriving = false
    if tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf and GlobalVariableSystem:IsServerLogic() then
        local Controller = self.pUEActor:GetController()
        if Controller then
            Controller:Possess(tbPlayer.pUEActor)
        end
    end
    self.pUEActor:SetOwner(nil)
    if tbPlayer and tbPlayer.pUEActor then
        tbPlayer.pUEActor:SetOwner(nil)
    end
    self.VehiclePropertyComponent:SetOwnerId(0)

    if GlobalVariableSystem:IsServerLogic() then
        PiratesReplicationBPHelpers.RemoveDependentActor( self.pUEActor, tbPlayer.pUEActor )
    end
end

function GameHorse:AttachToVehicle(tbPlayer, bAttach, bForceAttach)
    -- logdebug("AttachToVehicle", bAttach, debug.traceback())
    if GlobalVariableSystem:IsServerLogic() then
        if bAttach then
            PiratesReplicationBPHelpers.AddDependentActor( self.pUEActor, tbPlayer.pUEActor)
        else
            PiratesReplicationBPHelpers.RemoveDependentActor( self.pUEActor, tbPlayer.pUEActor)
        end
    end
    self.pUEActor.CharacterMovement:ResetNetworkSmoothingComplete()
    if bAttach then
        self.VehiclePropertyComponent:SetOwnerId(tbPlayer:GetServerInstanceId())
        local bForceAttachToVehicle = false
        if bForceAttach then
            bForceAttachToVehicle = true
        end
        local _bRet = self.pUEActor:AttachToVehicle(tbPlayer.pUEActor, true, bForceAttachToVehicle)
        self.bDriving = tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf
        if self.bDriving then
            if GlobalVariableSystem:IsServerLogic() then
                local Controller = tbPlayer.pUEActor:GetController()
                if Controller then
                    Controller:Possess(self.pUEActor)
                    self.pUEActor.CharacterMovement:ResetLastVelocity()
                end
            else
                --[[
                    上马前, 马的Role是Simulated, 此时bNetworkSmoothingComplete可能还为false
                    上马后, 马的Role变为Autonomous, bNetworkSmoothingComplete不再更新, 可能保持为false, 同时同步数据也不再变化
                    下马时, 马的Role变回Simulated, 在新的同步数据下来之前走了SmoothClientPosition, 会导致下马过程中马的位置/方向出错
                    所以需要上马后将这个变量设置为true, 保证下马时在正确的数据下来之前不走SmoothClientPosition
                ]]
                self.pUEActor.CharacterMovement:ResetNetworkSmoothingComplete()
            end
        end
        local pHumanLoc = tbPlayer:GetLocation()
        log("[VehicleDebugLog]", tbPlayer:GetName(), "GameHorse:AttachToVehicle human loc after attachment", pHumanLoc.X, pHumanLoc.Y, pHumanLoc.Z)

        tbPlayer.pUEActor:SetOwner(self.pUEActor)
    else
        self:ClearDriver(tbPlayer)
        if tbPlayer.pUEActor then
            log("[VehicleDebugLog] GameVehicle:AttachToVehicle Detaching from vehicle")
            self.pUEActor:DetachFromVehicle(tbPlayer.pUEActor)
        end
        -- self.pUEActor.CharacterMovement.Driver = nil
    end
end

function GameHorse:SetDriver(tbPlayer, bAttach, bForce)
    local pUEActor = self.pUEActor
    local nServerInstanceId = self:GetServerInstanceId()
    LOG(self, "SetDriver, bAttach=", bAttach, "PlayerId=", (tbPlayer and tbPlayer:GetServerInstanceId()))
    if bAttach then        -- Attach
        if not (tbPlayer and tbPlayer:IsAlive() and tbPlayer.pUEActor) then
            LOG(self, "SetDriver failed, PlayerId=", (tbPlayer and tbPlayer:GetServerInstanceId()))
            return false
        end
        pUEActor.CharacterMovement.bInOcean = false
        pUEActor:AttachToVehicle(tbPlayer.pUEActor, true)
        pUEActor:SetDriver(tbPlayer.pUEActor)
        ResetRotationSpeed(self)
        self.VehiclePropertyComponent:SetOwnerId(tbPlayer:GetServerInstanceId())

        if GlobalVariableSystem:IsServerLogic() then
            pUEActor.CharacterMovement:ResetLastVelocity()

            --用于燃烧弹的触发，服务器不开overlap的话触发不了燃烧弹
            pUEActor.CapsuleComponent:SetGenerateOverlapEvents(true)
            pUEActor.bInDriving = true

            local bIsAIControlled = AIHelper.IsAIControlled(tbPlayer)
            pUEActor.bIsAIControlled = bIsAIControlled
            pUEActor.bUseControllerRotationYaw = not bIsAIControlled

            PiratesReplicationBPHelpers.AddDependentActor(pUEActor, tbPlayer.pUEActor)

            if not self.bDriving then
                local AIVehicleManager = CommonShell.GetCommon(GWorld):GetAIVehicleManager()
                --上马后将马的信息从格子中移除，不需要被AI感知， AI会感知马上的人
                AIVehicleManager:RemoveVehicle(nServerInstanceId)
                log("ai:remove vehicle ", nServerInstanceId)
            end
        end

        self.bDriving = tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf
    else                    -- Detach
        pUEActor.bUseControllerRotationYaw = false
        pUEActor.bIsAIControlled = false
        self.VehiclePropertyComponent:SetOwnerId(0)

        if GlobalVariableSystem:IsServerLogic() then
            pUEActor.bInDriving = false
            pUEActor.CapsuleComponent:SetGenerateOverlapEvents(false)

            if self.bDriving then
                local AIVehicleManager = CommonShell.GetCommon(GWorld):GetAIVehicleManager()
                local Location = self:GetLocation()
                --下马后将马的信息重新加入
                AIVehicleManager:SetVehicleLocation(nServerInstanceId, Location)
                log("ai:add vehicle ",nServerInstanceId)
            end
        end

        if tbPlayer and tbPlayer.pUEActor then
            if GlobalVariableSystem:IsServerLogic() then
                local VehicleRotator = pUEActor:K2_GetActorRotation()
                pUEActor:K2_SetActorRotation(Rotator{Pitch=0, Yaw=VehicleRotator.Yaw+0.01, Roll=0}, false)
                destroyUserData(VehicleRotator)
            end
            pUEActor:DetachFromVehicle(tbPlayer.pUEActor)
            PiratesReplicationBPHelpers.RemoveDependentActor(pUEActor, tbPlayer.pUEActor)
        end

        pUEActor:SetDriver(nil)
        self.bDriving = false
    end

    return true
end

function GameHorse:OnDead()
    GameHorse.super.OnDead(self)
end

function GameHorse:IsFalling()
    local pUEActor = self.pUEActor
    if not pUEActor then
        return false
    end

    if not pUEActor.CharacterMovement then
        return false
    end

    return pUEActor.CharacterMovement.MovementMode == EMovementMode.MOVE_Falling
end

local function OnBindEvent(self, EventHelper, pUEActor)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)

    EventHelper:RegisterCppDelegate(pUEActor.OnFrightened, self, OnHorseFrightened)
end

function GameHorse:OnCreate()
    self.EventHelper = SelfEventHelper()
    return GameHorse.super.OnCreate(self)
end

function GameHorse:OnActorCreated(pUEActor)
    GameHorse.super.OnActorCreated(self, pUEActor)
    OnBindEvent(self, self.EventHelper, pUEActor)
    ResetRotationSpeed(self)
end

function GameHorse:UnbindUEActor()
    self.EventHelper:UnregisterAll()
    Timer.StopOwnerAllTimer(self, true)
    GameHorse.super.UnbindUEActor(self)
end

return GameHorse