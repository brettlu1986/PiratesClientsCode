-----------------------------------------------------
--File Name    : HumanVehicleComponent.lua
--Description  : 人的HumanVehicleComponent，用于控制上下马过程中状态变化
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase") 
local HumanVehicleComponent = luaclass("HumanVehicleComponent", GameComponentBaseClass)

local VehicleDataTable = require("VehicleDataTable")
local HumanCapsuleDataTable = require("HumanCapsuleDataTable")
local PropName = require("PropName")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local HumanMovementStateType = require("HumanMovementStateType")
local CommonEventDef = require("CommonEventDef")
local DamageTypeEx = require("DamageTypeEx")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
-- local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")

local HumanVehicleHelper = require("HumanVehicleHelper")
local EventManager = require("EventManager")
local PropUtil = require("PropUtil")
local SelfEventHelper = require("SelfEventHelper")
-- local AIHelper = require("AIHelper")
local SelfAnimationHelper = require("SelfAnimationHelper")
local Timer = require("Timer")
local AnimDef = require("AnimDef")
-- local TeamWatchServerHelper = require("TeamWatchServerHelper")

HumanVehicleComponent.nLastState = nil
HumanVehicleComponent.DetachSpeed = 0
HumanVehicleComponent.rVehicleState = nil
HumanVehicleComponent.nRegionType = nil
HumanVehicleComponent.EventHelper = nil

local VEHICLE_TIMER = "VehicleTimer"
local tbTemp = {}
local TempVector = Vector()
local AI_TO_LAND_MAX_DISTANCE = 10000

local function LOG_REQUEST_VEHICLE_FAILED(...)
    log("[Vehicle] [HumanVehicleComponent] CheckCanRequestVehicleState falied because", ...)
end

local function LOG_VEHICLE_STATE(self, ...)
    local nState = self:GetVehicleState()
    local nVehicleId = self:GetVehicleInstanceId()
    log("[Vehicle] [HumanVehicleComponent] OnVehicleStateChanged", self.Owner:GetName(), nState, nVehicleId, ...)
end

-- luacheck: push ignore
local function GridRegionTypeToString(nRegionType)
    if nRegionType == EPiratesGridRegionType.Land then
        return "Land"
    elseif nRegionType == EPiratesGridRegionType.Ocean then
        return "Ocean"
    elseif nRegionType == EPiratesGridRegionType.Shore then
        return "Shore"
    elseif nRegionType == EPiratesGridRegionType.Port then
        return "Port"
    elseif nRegionType == EPiratesGridRegionType.Rock then
        return "Rock"
    elseif nRegionType == EPiratesGridRegionType.Lake then
        return "Lake"
    else
        return "Unknown"
    end
end

local function VectorToString(InVector)
    return InVector.X .. InVector.Y .. InVector.Z
end
-- luacheck: pop

local function CopyVector(Dest, From)
    Dest.X = From.X
    Dest.Y = From.Y
    Dest.Z = From.Z
end

local function ClearTempTable()
    tbTemp.X = 0
    tbTemp.Y = 0
    tbTemp.Z = 0
end

local function VectorToTempTable(Vector)
    CopyVector(tbTemp, Vector)
    return tbTemp
end

local function TableToTempVector(Table)
    CopyVector(TempVector, Table)
    return TempVector
end

local function IsValidVector(InVector)
    if not InVector then
        return false
    end
    if not (InVector.X and InVector.Y and InVector.Z) then
        return false
    end
    if InVector.X == 0 and InVector.Y == 0 and InVector.Z == 0 then
        return false
    end
    return true
end

local function RequestVehicleFailed(self)
    if not GlobalVariableSystem:IsServerLogic() then
        return
    end
    HumanVehicleHelper.RequestVehicleFailed(self.Owner, 1)
    local nVehicleInstanceId = self:GetVehicleInstanceId(true)
    self:SetVehicleState(HumanVehicleStateDef.None, nVehicleInstanceId, 1)
end

local function GetVehicleAnimTime(bAttach, nTriggerType, GamePlayer)
    local szAnimKey = nil
    if bAttach then
        szAnimKey = nTriggerType == 1 and SelfAnimationHelper.AnimDef.IN_VEHICLE_LEFT or SelfAnimationHelper.AnimDef.IN_VEHICLE_RIGHT
    else
        szAnimKey = AnimDef.LEAVE_VEHICLE
    end
    local szAnimation = SelfAnimationHelper:GetHumanAnimation(GamePlayer, szAnimKey)
    local pMontage = szAnimation:load()
    local nMontageTime = ExtendBlueprintFunctions.GetMontageLength(pMontage)
    nMontageTime = nMontageTime - ExtendBlueprintFunctions.GetMontageSectionLength(pMontage, AnimDef.SectionName.IN_VEHICLE_END)
    local nMountCoefficient = GamePlayer.HumanBattlePropertyComponent:GetMountCoefficient()
    return nMontageTime / nMountCoefficient
end

local function ResetHumanActorRotation(pUEActor)
    local pRot = pUEActor:K2_GetActorRotation()
    pRot.Yaw = pRot.Yaw
    pRot.Pitch = 0
    pRot.Roll = 0
    pUEActor:K2_SetActorRotation(pRot)
end

local function OnDyingStateChanged(self, tbDyingPlayer, bIsDying)
    if not bIsDying or tbDyingPlayer.nServerInstanceId ~= self.Owner.nServerInstanceId or self.nLastState ~= HumanVehicleStateDef.PreAttachToVehicle then
        return
    end

    if GlobalVariableSystem:IsServerLogic() then
        self:SetVehicleState(HumanVehicleStateDef.None, self:GetVehicleInstanceId())
    end
end

local function OnVehicleStateChanged(self, _Property, tbVehicleState, bForceAttach) 
    if not tbVehicleState then
        LOG_VEHICLE_STATE(self, "tbVehicleState is nil")
        return 
    end 
    local GamePlayer = self.Owner
    local pUEActor = self.Owner.pUEActor

    local nVehicleState = tbVehicleState.vehicle_state

    if self.nLastState == nVehicleState then
        if GlobalVariableSystem:IsServerLogic() or nVehicleState ~= HumanVehicleStateDef.None or (not pUEActor.bInVehicle) then
            LOG_VEHICLE_STATE(self, "Requesting changing same state")
            return 
        else
            -- 断线重连后Actor刚生成时self.nLastState是NONE，此时如果人被踢下马客户端会踢不下去
            LOG_VEHICLE_STATE(self, "Refreshing same state NONE")
        end
    end 

    LOG_VEHICLE_STATE(self)

    Timer.StopOwnerTimer(self, VEHICLE_TIMER)

    local nVehicleInstanceId = tbVehicleState.vehicle_id

    local bSuccess = false

    if nVehicleState == HumanVehicleStateDef.PreAttachToVehicle then  
        bSuccess = self:OnPreAttach(tbVehicleState, bForceAttach, GamePlayer, pUEActor, nVehicleInstanceId)

    elseif nVehicleState == HumanVehicleStateDef.AttachToVehicle then  
        bSuccess = self:OnAttach(tbVehicleState, bForceAttach, GamePlayer, pUEActor, nVehicleInstanceId)

    elseif nVehicleState == HumanVehicleStateDef.PreDetachFromVehicle then 
        bSuccess = self:OnPreDetach(tbVehicleState, bForceAttach, GamePlayer, pUEActor, nVehicleInstanceId)

    elseif nVehicleState == HumanVehicleStateDef.None then
        if self.nLastState ~= HumanVehicleStateDef.PreDetachFromVehicle then
            bForceAttach = true
        end
        bSuccess = self:OnNone(tbVehicleState, bForceAttach, GamePlayer, pUEActor, nVehicleInstanceId)
    end

    if not bSuccess then
        LOG_VEHICLE_STATE(self, nVehicleState)
        return 
    end

    EventManager:OnFireEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, GamePlayer, nVehicleState, nVehicleInstanceId) 
    self.nLastState =  nVehicleState
end 

local function OnGridTypeChanged(self, tbGameObject, nRegionType)  
    if tbGameObject ~= self.Owner then
        return 
    end

    local HumanMovementStateComponent = tbGameObject.HumanMovementStateComponent
    if HumanMovementStateComponent and HumanMovementStateComponent:IsInParachuting() or HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.Jumping_SpeelWall then  
        return 
    end 

    if not HumanVehicleHelper.IsSwimmingVolume(nRegionType) then
        return
    end

    local nVehicleInstanceId = self:GetVehicleInstanceId()
    if not nVehicleInstanceId then 
        return 
    end

    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    if not tbVehicle then 
        return 
    end

    tbVehicle.pUEActor.CharacterMovement.bInOcean = true
    self:SetVehicleState(HumanVehicleStateDef.None, nVehicleInstanceId)
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local VehicleLocation = tbVehicle:GetLocation()
    local nCurRegionType = GridTypeManager:GetRegionType(VehicleLocation.X, VehicleLocation.Y)
    if nCurRegionType == EPiratesGridRegionType.Shore then
        local bRet, SwimmingVolumeLocation = GridTypeManager:GetClosestPositionOfRegionType(VehicleLocation.X, VehicleLocation.Y, nRegionType)
        if bRet then
            VehicleLocation.X = SwimmingVolumeLocation.X
            VehicleLocation.Y = SwimmingVolumeLocation.Y
        end
    elseif nCurRegionType == EPiratesGridRegionType.Land then
        LOG_VEHICLE_STATE(self, "OnGridTypeChanged nCurRegionType is Land", VectorToString(VehicleLocation))
        return
    end

    local bRet, NewLoction = GridTypeManager:GetClosestPositionOfRegionType(VehicleLocation.X, VehicleLocation.Y, EPiratesGridRegionType.Shore)
    if bRet then 
        local TargetPosition = Vector{X=NewLoction.X, Y=NewLoction.Y, Z=VehicleLocation.Z}
        local nDistance = KismetMathLibrary.Vector_Distance(VehicleLocation, TargetPosition)
        if nDistance <= AI_TO_LAND_MAX_DISTANCE then
            local pVehicleController = tbVehicle.pUEActor:GetController()
            if pVehicleController and pVehicleController:IsPlayerController() then
                return
            end
            tbVehicle.pUEActor:AIToLand(TargetPosition)
        else
            LOG_VEHICLE_STATE(self, "OnGridTypeChanged TargetPosition is too far. CurLoc=", VectorToString(VehicleLocation), ",TargetLoc=", VectorToString(TargetPosition), ",nDistance=", nDistance)
        end
    end
end

-- 判断是否可以Attach
local function CheckCanAttach(tbVehicle, GamePlayer)
    if not (tbVehicle and tbVehicle:IsAlive() and tbVehicle.pUEActor) then
        return false
    end

    local pLoc = GamePlayer:GetLocation()
    local nCurrentRegionType = CommonShell.GetCommon(GWorld):GetGridTypeManager():GetRegionType(pLoc.X, pLoc.Y)
    if HumanVehicleHelper.IsSwimmingVolume(nCurrentRegionType) then
        return false
    end

    return true
end

local function CheckCanSetVehicleState(self, nVehicleInstanceId, nVehicleState)
    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    if not HumanMovementStateComponent then
        LOG_REQUEST_VEHICLE_FAILED("HumanMovementStateComponent is nil")
        return false
    end

    local HumanBattlePropertyComponent = self.Owner.HumanBattlePropertyComponent
    if not HumanBattlePropertyComponent then 
        LOG_REQUEST_VEHICLE_FAILED("HumanBattlePropertyComponent is nil")
        return false 
    end
    local nMountCoefficient = HumanBattlePropertyComponent:GetMountCoefficient()
    if not nMountCoefficient or nMountCoefficient <=0 then
        LOG_REQUEST_VEHICLE_FAILED("nMountCoefficient = ", nMountCoefficient)
        return false
    end

    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    if nVehicleState == HumanVehicleStateDef.PreAttachToVehicle then
        if not CheckCanAttach(tbVehicle, self.Owner) then
            return false
        end
        if not tbVehicle or not tbVehicle.pUEActor then
            LOG_REQUEST_VEHICLE_FAILED("tbVehicle or tbVehicle.pUEActor is nil, tbVehicle=", tbVehicle)
            return false
        end
    
        if not tbVehicle:IsAlive() then
            LOG_REQUEST_VEHICLE_FAILED("tbVehicle is not alive.")
            return false
        end
        
        if not tbVehicle.pUEActor:CanAttachToVehicle(true, self.Owner.pUEActor) then  
            LOG_REQUEST_VEHICLE_FAILED("vehicle cannot be attached")
            return false
        end

        local HumanWeaponComponent = self.Owner.HumanWeaponComponent
        if (not HumanWeaponComponent) or HumanWeaponComponent:IsAttacking() then
            LOG_REQUEST_VEHICLE_FAILED("human is attacking", HumanWeaponComponent)
            return false
        end

        if GlobalVariableSystem:IsServerLogic() and (not self.Owner.pUEActor.bReplicateMovement) then
            LOG_REQUEST_VEHICLE_FAILED("human ReplicateMovement is false")
            return false
        end
    elseif nVehicleState == HumanVehicleStateDef.PreDetachFromVehicle then
        if not tbVehicle or not tbVehicle.pUEActor then
            LOG_REQUEST_VEHICLE_FAILED("tbVehicle or tbVehicle.pUEActor is nil, tbVehicle=", tbVehicle)
            return false
        end

        if not tbVehicle.pUEActor:CanDetachFromVehicle() then
            LOG_REQUEST_VEHICLE_FAILED("Vehicle is in stop montage")
        end
    end

    return true
end

-- 判断是否可以请求上下马
local function CheckCanRequestVehicleState(self, nVehicleInstanceId, nRequestVehicleState)
    if not CheckCanSetVehicleState(self, nVehicleInstanceId, nRequestVehicleState) then
        return false
    end
    
    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    if nRequestVehicleState == HumanVehicleStateDef.PreAttachToVehicle then
        local nMovementState = HumanMovementStateComponent:GetCurrentState()
        if nMovementState == HumanMovementStateType.Vehicle then
            LOG_REQUEST_VEHICLE_FAILED("human is already in vehicle")
            return false
        end

        local nVehicleState = self:GetVehicleState()
        if nVehicleState ~= HumanVehicleStateDef.None then
            LOG_REQUEST_VEHICLE_FAILED("human is not completely detached from vehicle", nVehicleState, HumanVehicleStateDef.None, nVehicleState ~= HumanVehicleStateDef.None)
            return false
        end
    elseif nRequestVehicleState == HumanVehicleStateDef.PreDetachFromVehicle then
        local nMovementState = HumanMovementStateComponent:GetCurrentState()
        if nMovementState == HumanMovementStateType.UpRight_State then
            LOG_REQUEST_VEHICLE_FAILED("human is not in vehicle")
            return false
        end

        local nVehicleState = self:GetVehicleState()
        if nVehicleState ~= HumanVehicleStateDef.AttachToVehicle then
            LOG_REQUEST_VEHICLE_FAILED("human is not completely attached to vehicle", nVehicleState)
            return false
        end
    end

    return true
end

local function TakeDetachDamage(self, tbVehicle, GamePlayer)
    if tbVehicle then 
        if not self.DetachSpeed then
            self.DetachSpeed = tbVehicle.pUEActor.Speed
        end
        if self.DetachSpeed and self.DetachSpeed > 0 then
            local tbVehicleData = VehicleDataTable:GetTemplate(tbVehicle:GetTemplateId())
            if not HumanVehicleHelper.IsSwimmingVolume(self.nRegionType) and self.DetachSpeed > tbVehicleData.nIngoreLeaveDamageSpeed then  
                local nResistFallOffHorseCoefficient = self.Owner.HumanBattlePropertyComponent:GetResistFallOffHorseCoefficient()
                local nDamage = (self.DetachSpeed - tbVehicleData.nIngoreLeaveDamageSpeed) / (tbVehicleData.nLeaveDamageFactor * nResistFallOffHorseCoefficient)
                log("DetachVehicleDamage name ", GamePlayer.szName, "nDamage",nDamage, "nLeaveDamageFactor", tbVehicleData.nLeaveDamageFactor, 
                    "nResistFallOffHorseCoefficient", nResistFallOffHorseCoefficient, 
                    "nPlayerId", GamePlayer.nPlayerId,"Speed", self.DetachSpeed,
                    "nIngoreLeaveDamageSpeed", tbVehicleData.nIngoreLeaveDamageSpeed)
                if GlobalVariableSystem:IsServerLogic() then
                    PropUtil.ApplyDamage(GamePlayer, nil, DamageTypeEx.FALLING, nDamage, nil)
                end
            end 
        end
    end
    self.DetachSpeed = nil
end

local function OnFFATeamWin(self, nTeamId)
    if self:GetVehicleState() == HumanVehicleStateDef.AttachToVehicle then
        HumanVehicleHelper.ClearVehicle(self.Owner, false, true)
    end
end

---------------------------------------------------------------------

function HumanVehicleComponent:OnPreAttach(tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    if not CheckCanSetVehicleState(self, nVehicleInstanceId, HumanVehicleStateDef.PreAttachToVehicle) then
        RequestVehicleFailed(self)
        return false
    end

    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    local nMovementState = HumanMovementStateComponent:GetCurrentState()
    if nMovementState ~= HumanMovementStateType.Vehicle then
        HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.Vehicle)
    end
    
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    tbVehicle:SetDriver(GamePlayer, true)

    if GlobalVariableSystem:IsServerLogic() then
        pUEActor:SetReplicateMovement(false)
        LOG_VEHICLE_STATE(self, "Disable replication movement.")
        local nTime = GetVehicleAnimTime(true, tbVehicleState.vehicle_trigger_type, GamePlayer)
        Timer.StartOwnerTimer(self, VEHICLE_TIMER, function()
            self:SetVehicleState(HumanVehicleStateDef.AttachToVehicle, nVehicleInstanceId, tbVehicleState.vehicle_trigger_type)
        end, nTime - 0.25)
    end

    return true
end

function HumanVehicleComponent:OnAttach(tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    local bSuccess = true
    
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    
    -- 判断是否可以Attach
    if CheckCanAttach(tbVehicle, GamePlayer) then
        -- 实际Attach
        pUEActor.CharacterMovement:SetComponentTickEnabled(false)
        pUEActor.CharacterMovement:DisableMovement()
        pUEActor:SetAttachVehicle(true, tbVehicle.pUEActor)
        self:SetOnVehicleCapsule(true)

        tbVehicle:SetDriver(GamePlayer, true)

        if GlobalVariableSystem:IsServerLogic() then
            local pController = pUEActor:GetController()
            if pController then
                pController:Possess(tbVehicle.pUEActor)
            end
            -- PiratesReplicationBPHelpers.AddDependentActor(tbVehicle.pUEActor, GamePlayer.pUEActor)
        end

        -- 必须要在Possess controller之后设置Owner, 否则Owner在UnPossess时会被置空
        pUEActor:SetOwner(tbVehicle.pUEActor)

        local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
        local nMovementState = HumanMovementStateComponent:GetCurrentState()
        if nMovementState ~= HumanMovementStateType.Vehicle then 
            HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.Vehicle)
        end
    else
        RequestVehicleFailed(self)
        bSuccess = false
    end

    -- 还原PreAttach状态
    --[[
        此时服务器设置人的骑马位置之后, BasedMovement不一定更新, 导致打开同步时Rep的一帧ReplicatedBasedMovement出错. 
        强制更新一下BasedMovement以解决此问题. 
    ]]
    pUEActor.CharacterMovement:ForceUpdateBasedMovement()

    if GlobalVariableSystem:IsServerLogic() then
        pUEActor:SetReplicateMovement(true)
        LOG_VEHICLE_STATE(self, "Enable replication movement.")
    end

    return bSuccess
end

function HumanVehicleComponent:OnPreDetach(tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    if not CheckCanSetVehicleState(self, nVehicleInstanceId, HumanVehicleStateDef.PreDetachFromVehicle) then
        RequestVehicleFailed(self)
        return false
    end

    pUEActor.CharacterMovement:ForceUpdateBasedMovement()
    pUEActor.CharacterMovement:SetComponentTickEnabled(true)
    
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    self.DetachSpeed = tbVehicle.pUEActor.Speed

    if GlobalVariableSystem:IsServerLogic() then
        pUEActor:SetReplicateMovement(false)
        LOG_VEHICLE_STATE(self, "Disable replication movement.")

        -- 避免下马卡进阻挡里，服务器也播一下
        pUEActor.CharacterMovement:SetMovementMode(EMovementMode.MOVE_Flying, 0)
        if IsValidVector(tbVehicleState.end_pos) and tbVehicle and tbVehicle.pUEActor then
            local pLocation = TableToTempVector(tbVehicleState.end_pos)
            LOG_VEHICLE_STATE(self, t2s(tbVehicleState.end_pos))
            tbVehicle.pUEActor:K2_SetActorLocation(pLocation)
            LOG_VEHICLE_STATE(self, "Server setting vehicle to client location:", t2s(tbVehicleState.end_pos))
        end
        local nMountCoefficient = GamePlayer.HumanBattlePropertyComponent:GetMountCoefficient()
        local _bRet, nTime, pMontage = SelfAnimationHelper:PlayHumanAnimation(GamePlayer, AnimDef.LEAVE_VEHICLE, nMountCoefficient)
        nTime = nTime - ExtendBlueprintFunctions.GetMontageSectionLength(pMontage, AnimDef.SectionName.IN_VEHICLE_END)
        nTime = nTime / nMountCoefficient
        
        Timer.StartOwnerTimer(self, VEHICLE_TIMER, function()
            self:SetVehicleState(HumanVehicleStateDef.None, nVehicleInstanceId, tbVehicleState.vehicle_trigger_type)
        end, nTime)
    end

    return true
end

function HumanVehicleComponent:OnNone(tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    pUEActor:SetAttachVehicle(false, nil)
    pUEActor:SetOwner(nil)
    ResetHumanActorRotation(pUEActor)
    -- pUEActor.CharacterMovement:SetActorRotationAndUpdateBasedMovement(pRot)
    self:SetOnVehicleCapsule(false)

    pUEActor.CharacterMovement:SetComponentTickEnabled(true)

    if pUEActor.PlayerInputComponent then
        pUEActor.PlayerInputComponent:RebindEventForLeftRight()
    end

    -- 马相关
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    TakeDetachDamage(self, tbVehicle, GamePlayer)
    if tbVehicle and tbVehicle.pUEActor then
        tbVehicle:SetDriver(GamePlayer, false)
        if bForce then
            local location = tbVehicle.pUEActor:GetAttachLocation(1)
            pUEActor:K2_SetActorLocation(location, false, true)
            LOG_VEHICLE_STATE(self, "Force detach from vehicle, setting human location to", location.X, location.Y, location.Z)
            destroyUserData(location)
        end
        -- tbVehicle.pUEActor.CharacterMovement:ClearDriverBase(pUEActor)
    end
    
    if GlobalVariableSystem:IsServerLogic() then
        pUEActor.CharacterMovement:SetMovementMode(EMovementMode.MOVE_Walking, 0)
        pUEActor:StopAnimMontage(nil)
        pUEActor:SetReplicateMovement(true)
        LOG_VEHICLE_STATE(self, "Enable replication movement.")
        if tbVehicle and tbVehicle.pUEActor then
            local pController = tbVehicle.pUEActor:GetController()
            if pController then
                pController:Possess(pUEActor)
            end
        end
    end

    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    local nMovementState = HumanMovementStateComponent:GetCurrentState()
    if nMovementState == HumanMovementStateType.Vehicle then 
        HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.UpRight_State)
    end

    return true
end

-----------------------------------------------------------------------------------

function HumanVehicleComponent:SetOnVehicleCapsule(bSet)
    local pUEActor = self.Owner.pUEActor
    local pCapsuleComponent = pUEActor.CapsuleComponent
    local nCapsuleRadius = pCapsuleComponent:GetUnscaledCapsuleRadius()
    local nCapsuleHalfHeight = nCapsuleRadius

    
    if not bSet then  
        local nMovementState = self.Owner.HumanMovementStateComponent:GetCurrentState()
        if nMovementState == HumanMovementStateType.Vehicle then 
            nMovementState = HumanMovementStateType.UpRight_State
        end
        local tbCapsuleData = HumanCapsuleDataTable:GetTemplate(self.Owner:GetHumanTemplateId(), nMovementState)
        if tbCapsuleData then
            nCapsuleHalfHeight = tbCapsuleData.nCapsuleHalfHeight
        else
            return
        end
        pUEActor.CharacterMovement:AdjustHeightAccordingToCapsuleHalfHeight(nCapsuleHalfHeight)
    end 
    pCapsuleComponent:SetCapsuleHalfHeight(nCapsuleHalfHeight)
end 

function HumanVehicleComponent:OnActorCreated(pUEActor)
    local rComponent = self.Owner.CustomReplicationComponent
    self.rVehicleState = rComponent:BindMethod(PropName.rHumanVehicleStateNew,
        nil, self, OnVehicleStateChanged, true)

    self.nLastState = HumanVehicleStateDef.None

    if self.Owner.HumanBattlePropertyComponent:GetIsDying() then  
        self:OnDyingChanged(true)
    end 
    self.EventHelper = SelfEventHelper()

    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED,  self, OnDyingStateChanged)
    if GlobalVariableSystem:IsServerLogic() then
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GRID_TYPE_CHANGED, self, OnGridTypeChanged)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_FFA_TEAM_WIN, self, OnFFATeamWin)
    end
    OnVehicleStateChanged(self, nil, self.rVehicleState:Get(), true)
end 

function HumanVehicleComponent:OnActorDestroyed(_pUEActor)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED, self, OnDyingStateChanged)
    HumanVehicleHelper.ClearVehicle(self.Owner, true, true)
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
    end
    Timer.StopOwnerAllTimer(self, true)
    self.rVehicleState = nil
end 

function HumanVehicleComponent:OnDyingChanged(bIsDying)
    if bIsDying then 
        HumanVehicleHelper.ClearVehicle(self.Owner, false, true)
    end
end


function HumanVehicleComponent:GetVehicleState()
    if not self.rVehicleState or not self.rVehicleState:Get() then  
        return HumanVehicleStateDef.None
    end 
    return self.rVehicleState:Get().vehicle_state
end 
 
function HumanVehicleComponent:GetVehicleInstanceId(bIgnoreVehicleState)
    if not self.rVehicleState then  
        return 0
    end
    local tbVehicleState = self.rVehicleState:Get()

    if not tbVehicleState or tbVehicleState.vehicle_state == HumanVehicleStateDef.None and not bIgnoreVehicleState then  
        return 0
    end

    return tbVehicleState.vehicle_id
end 

function HumanVehicleComponent:SetVehicleState(nVehicleState, nVehicleId, nVehicleTriggerType, end_pos)
    if not GlobalVariableSystem:IsServerLogic() or not self.rVehicleState then
        return 
    end 
    if self:GetVehicleState() == nVehicleState then  
        return 
    end

    if IsValidVector(end_pos) then
        VectorToTempTable(end_pos)
    else
        ClearTempTable()
        local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleId)
        if tbVehicle then
            local Location = tbVehicle:GetLocation()
            if Location then
                VectorToTempTable(Location)
            end
        end
    end
    local tbVehicleState = {
        vehicle_state = nVehicleState,
        vehicle_id = nVehicleId,
        vehicle_trigger_type = nVehicleTriggerType,
        end_pos = tbTemp,
    }
    self.rVehicleState:Set(tbVehicleState)
end

function HumanVehicleComponent:RequestVehicleState(nState, nVehicleInstanceId, end_pos, nVehicleTriggerType)
    if nState == HumanVehicleStateDef.PreAttachToVehicle and CheckCanRequestVehicleState(self, nVehicleInstanceId, nState) then
        self:SetVehicleState(HumanVehicleStateDef.PreAttachToVehicle, nVehicleInstanceId, nVehicleTriggerType)
    elseif nState == HumanVehicleStateDef.PreDetachFromVehicle and CheckCanRequestVehicleState(self, nVehicleInstanceId, nState) then  
        self:SetVehicleState(HumanVehicleStateDef.PreDetachFromVehicle, nVehicleInstanceId)
    else 
        self:SetVehicleState(nState, nVehicleInstanceId)
    end 
end

function HumanVehicleComponent:IsInVehicle()
    local nVehicleState = self:GetVehicleState()
    if (nVehicleState == HumanVehicleStateDef.PreAttachToVehicle 
        or nVehicleState == HumanVehicleStateDef.AttachToVehicle) 
        or nVehicleState == HumanVehicleStateDef.PreDetachFromVehicle then  
        return true
    end
    return false
end

function HumanVehicleComponent:IsInPlane()
    local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
    if not HumanMovementStateComponent then
        return false
    end
    return HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.InPlane_State
end

function HumanVehicleComponent:CancelAttachment()

end


-------------------------------------------------------------------------------
-- AI用
-------------------------------------------------------------------------------

function HumanVehicleComponent:AIRequestGetInVehicle(nVehicleInstanceId, bIsLeft)

    if not CheckCanRequestVehicleState(self, nVehicleInstanceId, HumanVehicleStateDef.PreAttachToVehicle) then
        return false
    end
    
    local nVehicleTriggerType = bIsLeft and 1 or 2

    self:SetVehicleState(HumanVehicleStateDef.PreAttachToVehicle, nVehicleInstanceId, nVehicleTriggerType)

    return true
end

function HumanVehicleComponent:AIRequestGetOffVehicle()

    local nVehicleInstanceId = self:GetVehicleInstanceId(true)
    if not CheckCanRequestVehicleState(self, nVehicleInstanceId, HumanVehicleStateDef.PreDetachFromVehicle) then
        return false
    end

    self:SetVehicleState(HumanVehicleStateDef.PreDetachFromVehicle, nVehicleInstanceId, 1)
    return true
end

function HumanVehicleComponent:GetVehicle()
    local nVehicleInstanceId = self:GetVehicleInstanceId()
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    return tbVehicle
end

function HumanVehicleComponent:OnRequestVehicleFailed(nReason)

end

return HumanVehicleComponent