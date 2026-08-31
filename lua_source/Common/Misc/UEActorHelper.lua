-- NPC角色

local UEActorHelper = {}

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local MakeTransform = KismetMathLibrary.MakeTransform
local SpawnActorForScript = EngineExtActorShell.SpawnActorForScript
local GetActorUniqueId = EngineExtActorShell.GetActorUniqueId
local DestroyActor = EngineExtActorShell.DestroyActor
local SetActorLocation = EngineExtActorShell.SetActorLocation
local SetActorLocationXYZ = EngineExtActorShell.SetActorLocationXYZ
local GetActorLocation = EngineExtActorShell.GetActorLocation
local GetActorLocationXYZ = EngineExtActorShell.GetActorLocationXYZ
local SetActorRotation = EngineExtActorShell.SetActorRotation
local SetActorRotationYawPitchRoll = EngineExtActorShell.SetActorRotationYawPitchRoll
local GetActorRotation = EngineExtActorShell.GetActorRotation
local GetActorRotationYawPitchRoll = EngineExtActorShell.GetActorRotationYawPitchRoll
local SetActorScale = EngineExtActorShell.SetActorScale
local SetActorScale3D = EngineExtActorShell.SetActorScale3D
local GetActorScale3D = EngineExtActorShell.GetActorScale3D

local pDefualtLocation = Vector()
local pDefualtRotation = Rotator()
local pDefualtScale = Vector{X=1,Y=1,Z=1}
local pCommonActorShell = nil

local tbWildComponentTags = {"Common", "Wild"}
local tbBattleComponentTags = {"Common", "Battle"}
UEActorHelper.tbWildComponentTags = tbWildComponentTags
UEActorHelper.tbBattleComponentTags = tbBattleComponentTags

function UEActorHelper.TryCreateTemplateComponents(pActor, tbComponentTags, bCreateNativeComponentAsyn, bBeginPlay)
    if(pActor and GlobalVariableSystem.bEnableComponentDataSerializer) then
        local pComponentDataSerializer = pActor.ComponentDataSerializer
        if(pComponentDataSerializer) then
            if(tbComponentTags == nil) then
                tbComponentTags = GlobalVariableSystem:IsInDungeon() and tbBattleComponentTags or tbWildComponentTags
            end

            if(GlobalVariableSystem:IsDedicatedServer() or not bCreateNativeComponentAsyn) then
                pComponentDataSerializer:LoadSyn(tbComponentTags, bBeginPlay)
            else
                pComponentDataSerializer:LoadAsyn(tbComponentTags, 0, true, true)
            end
        elseif(bBeginPlay and pActor.BeginPlayManually) then
            pActor:BeginPlayManually()
        end
    end
end

function UEActorHelper:CreateActor(szActorClass,
    pInLocation, pInRotation, pInScale,
    szActorInitProtoName, tbInitProtoData,
    nInstanceId,
    tbComponentTags,
    bCreateNativeComponentAsyn)

    local pLocation = (pInLocation == nil) and pDefualtLocation or pInLocation
    local pRotation = (pInRotation == nil) and pDefualtRotation or pInRotation
    local pScale = (pInScale == nil) and pDefualtScale or pInScale

    local pTransform = MakeTransform(pLocation, pRotation, pScale)
    local ActorClass = szActorClass:load()
    if(ActorClass == nil) then
        logerror("UEActorHelper:LoadBlueprintClass failed: "..szActorClass)
        return nil
    end

    local pProtoDataTableRef = nil
    if(tbInitProtoData) then
        pProtoDataTableRef = exposetable(tbInitProtoData)
    end
    if(pCommonActorShell == nil) then
        pCommonActorShell = CommonShell.GetCommon(GWorld):GetCommonActorShell()
    end

    pCommonActorShell:SetActorSpawnInitData(szActorInitProtoName or "",
        pProtoDataTableRef,
        nInstanceId or 0,
        GlobalVariableSystem.bEnableComponentDataSerializer)

    --log("UEActorHelper:CreateActor", szActorClass, pLocation.X, pLocation.Y, pLocation.Z, pInRotation.Yaw)
    local RetActor = SpawnActorForScript(GWorld, ActorClass, pTransform, nil)
    local nUniqueId = GetActorUniqueId(RetActor)

    pCommonActorShell:ResetActorSpawnInitData()

    -- 走一遍component创建流程
    UEActorHelper.TryCreateTemplateComponents(RetActor, tbComponentTags, bCreateNativeComponentAsyn, true)
    return nUniqueId, RetActor
end

function UEActorHelper:CreateActorByClass(pClass, pTransform, tbComponentTags)
    if not pClass or not pTransform then
        return nil
    end

    pCommonActorShell:SetActorSpawnInitData("",
    nil,
    0,
    GlobalVariableSystem.bEnableComponentDataSerializer)

    local RetActor = SpawnActorForScript(GWorld, pClass, pTransform, nil)
    pCommonActorShell:ResetActorSpawnInitData()
    UEActorHelper.TryCreateTemplateComponents(RetActor, tbComponentTags, false, true)
    return RetActor
end

function UEActorHelper:GetActorUniqueId(pActor)
    return GetActorUniqueId(pActor)
end

function UEActorHelper:DestroyActor(Actor, bNetForce)
    if(Actor) then
        DestroyActor(GWorld, Actor, (bNetForce == nil or bNetForce == true))
    end
end

-- function UEActorHelper:Possess(Actor)
--     log("Possess actor")
--     local PC = GameplayStatics.GetPlayerController(GWorld, 0)
--     PC:Possess(Actor)
-- end

-- 因为Actor基类里没有把底下这些函数加上UFUNCTION,所以这里开出来给lua用
function UEActorHelper:SetActorLocation(pActor, pLocation)
    if(not pActor) then
        logerror("UEActorHelper:SetActorLocation nil")
        return
    end
    SetActorLocation(pActor, pLocation)
end

function UEActorHelper:SetActorLocationXYZ(pActor, nX, nY, nZ)
    if(not pActor) then
        logerror("UEActorHelper:SetActorLocationXYZ nil")
        return
    end
    SetActorLocationXYZ(pActor, nX, nY, nZ)
end

function UEActorHelper:GetActorLocation(pActor)
    if(not pActor) then
        logerror("UEActorHelper:GetActorLocation nil")
        return Vector()
    end
    return GetActorLocation(pActor)
end

function UEActorHelper:GetActorLocationXYZ(pActor)
    if(not pActor) then
        logerror("UEActorHelper:GetActorLocationXYZ nil")
        return 0, 0, 0
    end
    return GetActorLocationXYZ(pActor)
end

function UEActorHelper:SetActorRotation(pActor, pLocation)
    if(not pActor) then
        logerror("UEActorHelper:SetActorRotation nil")
        return
    end
    SetActorRotation(pActor, pLocation)
end

function UEActorHelper:SetActorRotationYawPitchRoll(pActor, nYaw, nPitch, nRoll)
    if(not pActor) then
        logerror("UEActorHelper:SetActorRotationYawPitchRoll nil")
        return
    end
    SetActorRotationYawPitchRoll(pActor, nYaw, nPitch, nRoll)
end

function UEActorHelper:GetActorRotation(pActor)
    if(not pActor) then
        logerror("UEActorHelper:GetActorRotation nil")
        return Rotator()
    end
    return GetActorRotation(pActor)
end

function UEActorHelper:GetActorRotationYawPitchRoll(pActor)
    if(not pActor) then
        logerror("UEActorHelper:GetActorRotationYawPitchRoll nil")
        return 0, 0, 0
    end
    return GetActorRotationYawPitchRoll(pActor)
end

-- 在DS模式Server上使用此方法，不要使用SetActorRotation
function UEActorHelper:TeleportShip(pActor, pLocation, nYaw, bResetMovement)
    if isvalidhandle(pActor) then
        local pMovementComponent = pActor.ShipMovementComponent
        if pMovementComponent ~= nil then
            pMovementComponent:TeleportShip(pLocation, nYaw, bResetMovement)
            return true
        end
    end
    return false
end

function UEActorHelper:SetActorScale(pActor, nScale)
    if(not pActor) then
        logerror("UEActorHelper:SetActorScale nil")
        return
    end
    SetActorScale(pActor, nScale)
end

function UEActorHelper:SetActorScale3D(pActor, pScale)
    if(not pActor) then
        logerror("UEActorHelper:SetActorScale3D nil")
        return
    end
    SetActorScale3D(pActor, pScale)
end

function UEActorHelper:GetActorScale3D(pActor)
    if(not pActor) then
        logerror("UEActorHelper:GetActorRotation3D nil")
        return Vector()
    end
    return GetActorScale3D(pActor)
end

function UEActorHelper:SetOnlyRelevantToOwner(pActor, pOwner)
    if (not pActor or not pOwner) then
        logerror("UEActorHelper:SetOnlyRelevantToOwner nil")
        return
    end

    pActor:SetOwner(pOwner)
    pActor.bOnlyRelevantToOwner = true
end

function UEActorHelper.StopMove(pActor, bImmediately)
    if isvalidhandle(pActor) then
        local MovementComponent = pActor.ShipMovementComponent
        if MovementComponent then
            if bImmediately then -- 立即停下
                MovementComponent:StopMovementImmediately()
            else -- 有惯性，档位归0停下
                MovementComponent:StopMove()
            end
            return
        end

        MovementComponent = pActor.CharacterMovement
        if not MovementComponent then
            error("Cannot find actor movementcomponent!"..KismetSystemLibrary.GetDisplayName(pActor))
        end
        -- 人都是立即停下，没有惯性
        MovementComponent:StopHumanMovementImmediately()
    end
end

return UEActorHelper
