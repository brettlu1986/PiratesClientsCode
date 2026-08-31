
local luaclass = require("luaclass")
local CameraInnerHelper = luaclass("CameraInnerHelper")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
--
local GameCameraModeDef = require("GameCameraModeDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")

CameraInnerHelper.tbCameraLogic = {}
CameraInnerHelper.Owner = nil

local ClassDef = GameCameraModeGroupDef.LogicDef
local LOGIC_DEF_CLASS = 
{
    [ClassDef.CL_CARRONADE]         = "CLCarronadeView",
    [ClassDef.CL_GAME_PLAYER]       = "CLGamePlayer",
    [ClassDef.CL_AIMING]            = "CLAiming",
    [ClassDef.CL_MOVEMENT]          = "CLMovement",
    [ClassDef.CL_WATCHBATTLE]       = "CLWatchBattle",
    [ClassDef.CL_COMMON_SETTING]    = "CLCommonSetting",
}

local VECTOR_ZERO = Vector{X = 0, Y = 0, Z = 0}
local tbInterpValue = 
{
    Lerp = 1,
    SinIn = 2,
    SinOut = 3,
}

local CameraModeIdToEnum = 
{
    [GameCameraModeDef.ModeChangeTarget] = ECameraModeType.ModeChangeTarget,
    [GameCameraModeDef.ModeHandleMove] = ECameraModeType.ModeHandleMove,
    [GameCameraModeDef.ModeOffsetMove] = ECameraModeType.ModeOffsetMove,
    [GameCameraModeDef.ModeShake] = ECameraModeType.ModeShake,
    [GameCameraModeDef.ModeFov] = ECameraModeType.ModeFov,
    [GameCameraModeDef.ModeArmLen] = ECameraModeType.ModeArmLen,
    [GameCameraModeDef.ModeSyncArmRot] = ECameraModeType.ModeSyncArmRot,
    [GameCameraModeDef.ModeArmRot] = ECameraModeType.ModeArmRot,
    [GameCameraModeDef.ModeCameraTrack] = ECameraModeType.ModeCameraTrack
}

function CameraInnerHelper:SetOwner(Owner)
    self.Owner = Owner
end

function CameraInnerHelper:CreateCameraLogic(nLogicId)
    local tbClass = require(LOGIC_DEF_CLASS[nLogicId])
    local tbUILogic = tbClass()
    tbUILogic:Create(self.Owner)
    table.insert(self.tbCameraLogic, tbUILogic)
    return tbUILogic
end

function CameraInnerHelper:DestroyAllCameraLogic()
    for k,v in pairs(self.tbCameraLogic) do
        if v then
            v:Destroy()
        end
    end
    self.tbCameraLogic = {}
end

function CameraInnerHelper:BindEvent()
    for k,v in pairs(self.tbCameraLogic) do
        if v then
            v:BindEvent()
        end
    end
end

function CameraInnerHelper:UnbindEvent()
    for k,v in pairs(self.tbCameraLogic) do
        if v then
            v:UnbindEvent()
        end
    end
end

---------------------------construct camera move mode ---------------------
local function GetModeInfoObject(pClass)
    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    local pModeInfo = ExtendBlueprintFunctions.CreateObject(pClass, pGameInstance)
    return pModeInfo
end

local function Consturct_ChangeTarget(tbParams)
    local pModeInfo = GetModeInfoObject(ChangeTargetInfo)
    pModeInfo.Target = tbParams.pTarget or nil
    pModeInfo.bChangeImmediatly = tbParams.bImmediatly or false
    pModeInfo.BlendTime = tbParams.nBlendTime or 0
    pModeInfo.BlendExp = tbParams.nBlendExp or 0
    pModeInfo.BlendFunc = tbParams.BlendFunc or EViewTargetBlendFunction.VTBlend_Linear
    return pModeInfo
end  

local function Consturct_HandleMove(tbParams)
    local pModeInfo = GetModeInfoObject(HandleMoveInfo)
    pModeInfo.MoveX = tbParams.nMoveX  or 0
    pModeInfo.MoveY = tbParams.nMoveY  or 0
    pModeInfo.MoveType = tbParams.MoveType  or EHandleInputType.UseNone
    pModeInfo.bWithAnim = tbParams.WithAnim or false
    pModeInfo.AnimTime = tbParams.AnimTime  or 0
    return pModeInfo
end

local function Consturct_OffsetMove(tbParams)
    local pModeInfo = GetModeInfoObject(OffsetMoveInfo)
    pModeInfo.MoveOffset = tbParams.MoveOffset or VECTOR_ZERO
    pModeInfo.BlendTime = tbParams.nBlendTime or 0
    pModeInfo.bNeedBlend = tbParams.bNeedBlend or false
    pModeInfo.InterpMode = tbParams.nInterpMode or tbInterpValue.Lerp
    return pModeInfo
end

local function Construct_Shake(tbParams)
    local pModeInfo = GetModeInfoObject(CameraShakeInfo)
    pModeInfo.TargetAngle = tbParams.TargetAngle or VECTOR_ZERO
    pModeInfo.RecoverAngle = tbParams.RecoverAngle or VECTOR_ZERO
    pModeInfo.PosOffset = tbParams.PosOffset or VECTOR_ZERO
    pModeInfo.Duration = tbParams.TargetTime or 0
    pModeInfo.FovChange = tbParams.nFov or 0
    pModeInfo.DecayParam = tbParams.nDecayParam or 0
    pModeInfo.ShakeCount = tbParams.nShakeCount or 1
    pModeInfo.bRecoil = tbParams.bRecoil
    pModeInfo.bFollowPitch = tbParams.bFollowPitch 
    pModeInfo.bUseRecoverV = tbParams.bUseRecoverV 
    return pModeInfo
end

local function Construct_Fov(tbParams)
    local pModeInfo = GetModeInfoObject(FovInfo)
    pModeInfo.TargetFovRate = tbParams.nTargetFovRate  or 0
    pModeInfo.BlendTime = tbParams.nBlendTime  or 0
    return pModeInfo
end

local function Construct_ArmLen(tbParams)
    local pModeInfo = GetModeInfoObject(MoveArmLenInfo)
    pModeInfo.ArmLenToGo = tbParams.nArmLenToGo or 0
    pModeInfo.BlendTime = tbParams.nBlendTime or 0
    return pModeInfo
end

local function Construct_SyncArmRot(tbParams)
    local pModeInfo = GetModeInfoObject(SyncArmRotInfo)
    pModeInfo.bSyncYaw = tbParams.bSyncYaw or false
    pModeInfo.SyncPawn = tbParams.pPawn or nil
    pModeInfo.OffsetYaw = tbParams.nOffsetYaw or 0
    pModeInfo.InterpSpeed = tbParams.nInterpSpeed or 1
    return pModeInfo
end

local function Construct_ArmRot(tbParams)
    local pModeInfo = GetModeInfoObject(ArmRotInfo)
    pModeInfo.TargetRot = tbParams.nTargetRot or 0
    pModeInfo.BlendTime = tbParams.nBlendTime or 0
    return pModeInfo
end

local function Construct_CameraTrack(tbParams)
    local pModeInfo = GetModeInfoObject(CameraTrackInfo)
    pModeInfo.TargetMeshComponent = tbParams.pTargetMesh
    pModeInfo.TargetSocket = tbParams.szTargetSocket
    pModeInfo.RefMeshComponent = tbParams.pRefMesh
    pModeInfo.SightRelativaTransform = tbParams.pSightRelativeTransform
    pModeInfo.TrackParam = tbParams.nTrackSpeed
    pModeInfo.DelayBeginTime = tbParams.nDelayBeginTime
    pModeInfo.DelayTrackOnceTime = tbParams.nDelayTraceOnceTime
    pModeInfo.OffsetForward = tbParams.nOffsetForward
    return pModeInfo
end

function CameraInnerHelper:GetCameraManager()
    return GameplayStatics.GetPlayerCameraManager(GWorld, 0)
end

function CameraInnerHelper:GetArm()
    local GameCameraManager = self:GetCameraManager()
    local CameraActor = GameCameraManager:GetPlayerCameraActor()
    return CameraActor:GetSpringArm()
end

function CameraInnerHelper:SafeSpawnCameraActor()
    local CameraManager = self:GetCameraManager()
    if CameraManager and CameraManager.SpawnCameraActor then
        CameraManager:SpawnCameraActor()
    end
end

function CameraInnerHelper:ActiveCameraMode(nModeId, tbParam)
    local Def = GameCameraModeDef
    local pModeInfo = nil
    if nModeId == Def.ModeChangeTarget then  
        pModeInfo = Consturct_ChangeTarget(tbParam)
    elseif nModeId == Def.ModeHandleMove then
        pModeInfo = Consturct_HandleMove(tbParam)
    elseif nModeId == Def.ModeOffsetMove then 
        pModeInfo = Consturct_OffsetMove(tbParam)
    elseif nModeId == Def.ModeShake then 
        pModeInfo = Construct_Shake(tbParam)
    elseif nModeId == Def.ModeFov then 
        pModeInfo = Construct_Fov(tbParam)
    elseif nModeId == Def.ModeArmLen then 
        pModeInfo = Construct_ArmLen(tbParam)
    elseif nModeId == Def.ModeSyncArmRot then 
        pModeInfo = Construct_SyncArmRot(tbParam)
    elseif nModeId == Def.ModeArmRot then 
        pModeInfo = Construct_ArmRot(tbParam)
    elseif nModeId == Def.ModeCameraTrack then 
        pModeInfo = Construct_CameraTrack(tbParam)
    end
    local CameraManager = self:GetCameraManager()
    if CameraManager and CameraManager.ActiveCameraMode then
        CameraManager:ActiveCameraMode(CameraModeIdToEnum[nModeId], pModeInfo)
    end
end

function CameraInnerHelper:DeactiveCameraMode(nModeId)
    local CameraManager = self:GetCameraManager()
    CameraManager:DeactiveCameraMode(CameraModeIdToEnum[nModeId])
end

function CameraInnerHelper:UpdateFreeViewCacheRotation(Rot)
    local CameraManager = self:GetCameraManager()
    CameraManager:InitCacheArmParam()
    local pUEActor = PlayerSelfHelper:GetUEActor()
    if pUEActor then
        pUEActor.PlayerProperty:EnableFreeView(true, Rot)
        local tbPacket = {
            IsEnter = true,
        }
        NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_EnterFreeView, tbPacket)
    end
end

return CameraInnerHelper
