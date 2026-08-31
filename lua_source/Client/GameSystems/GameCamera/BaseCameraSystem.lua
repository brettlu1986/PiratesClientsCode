local luaclass = require("luaclass")
local BaseCameraSystem = luaclass("BaseCameraSystem")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local GameCameraModeDef = require("GameCameraModeDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfEventHelper = require("SelfEventHelper")

local CameraInnerHelper = require("CameraInnerHelper")

BaseCameraSystem.tbCameraGroups = nil

BaseCameraSystem.nLastGroupId = nil
BaseCameraSystem.nCurrentGroupId = nil
BaseCameraSystem.SelfEventHelper = nil
BaseCameraSystem.Helper = nil
BaseCameraSystem.clCameraSetting = nil

local tbGroupDef = GameCameraModeGroupDef
local tbModeDef = GameCameraModeDef
local ZERO_VECTOR = Vector{X = 0, Y = 0, Z = 0}
local ZERO_ROTATOR = Rotator{Pitch = 0, Yaw = 0, Roll = 0}
local FREE_VIEW_INTERPSPEED = 11

------------------------Camera Group---------------------------
function BaseCameraSystem:GetCameraMoveScale()
    return self.clCameraSetting.nCurMoveXScale, self.clCameraSetting.nCurMoveYScale
end

--tbCustomParam 也可以传入表中读入的参数
--tbCustomParam.tbConfigInitParams
--tbCustomParam.tbTargetParams 穿入是否需要follow的target,不放到 CameraMode里面是因为
--cameraMode的ModifyCamera里面执行镜头 follow target 位移会有抖动，暂时原因未知 所以先放到 CameraManager的Tick里
function BaseCameraSystem:InitCameraActor(tbCameraGroup, tbCustomParam)

    if tbCustomParam and tbCustomParam.bKeepNoChange then
        return
    end

    local tbParams = {}
    tbParams.tbCameraInit = tbCameraGroup.tbCameraParams
    if tbCustomParam then
        if tbCustomParam.tbConfigInitParams then
            tbParams.tbCameraInit = tbCustomParam.tbConfigInitParams
        end
        if tbCustomParam.tbTargetParams then
            tbParams.tbTargetInit = tbCustomParam.tbTargetParams
        end
    end
    --camera init
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local tbInit = tbParams.tbCameraInit
    if tbInit then
        local InitCameraInfo = InitCameraInfo()
        InitCameraInfo.SpringArmLength = tbInit.nArmLength and tbInit.nArmLength or 0
        InitCameraInfo.SpringArmRotation = tbInit.ArmRotation and tbInit.ArmRotation or ZERO_ROTATOR
        InitCameraInfo.SpringArmLocation = tbInit.ArmLocation and tbInit.ArmLocation or ZERO_VECTOR
        InitCameraInfo.SocketOffset = tbInit.SocketOffset and tbInit.SocketOffset or ZERO_VECTOR
        InitCameraInfo.CameraRotation = tbInit.CameraRotation and tbInit.CameraRotation or ZERO_ROTATOR
        InitCameraInfo.PitchViewMax = tbInit.nPitchViewMax and tbInit.nPitchViewMax or 0
        InitCameraInfo.PitchViewMin = tbInit.nPitchViewMin and tbInit.nPitchViewMin or 0
        InitCameraInfo.LookUpLimit = tbInit.nLookUpLimit and tbInit.nLookUpLimit or 30
        InitCameraInfo.LookDownLimit = tbInit.nLookDownLimit and tbInit.nLookDownLimit or -30
        InitCameraInfo.InitFov = tbInit.nFov or 90
        GameCameraManager:InitCameraActorParam(InitCameraInfo)
    end
    --如果不想改变之前设置的target, 就不设置
    local tbTargetInit = tbParams.tbTargetInit
    if tbTargetInit.pFollowTarget == nil then  
        logerror("camera follow target cannot be nil")
    end
    if tbTargetInit and tbTargetInit.pFollowTarget and isvalidhandle(tbTargetInit.pFollowTarget) then
        local LocOffset = tbTargetInit.FollowLocOffset and tbTargetInit.FollowLocOffset or ZERO_VECTOR
        if tbTargetInit.FollowSocket == nil then
            tbTargetInit.FollowSocket = ""
        end
        GameCameraManager:InitFollowTarget(tbTargetInit.pFollowTarget, tbTargetInit.pFollowType, tbTargetInit.bSetControlRot,
            tbTargetInit.FollowParentComponent, LocOffset, tbTargetInit.FollowSocket)
    end
end

local function UninitCameraActor(self, tbCameraGroup, tbCustomParam)
    local tbParams = tbCustomParam
    if tbParams and tbParams.bKeepNoChange then
        return
    end
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    GameCameraManager:UnInitCameraActorParam()
end

local function InitCacheArmParam(self, tbCameraGroup, tbCustomParam)
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    GameCameraManager:InitCacheArmParam()
    if tbCustomParam then
        self.clCameraSetting.nMoveScaleX = tbCustomParam.nMoveScaleX and tbCustomParam.nMoveScaleX or 1
        self.clCameraSetting.nMoveScaleY = tbCustomParam.nMoveScaleY and tbCustomParam.nMoveScaleY or 1
    end
end

local function UnInitCacheArmParam(self, tbCameraGroup, tbCustomParam)
    local bWithAnim =  false
    if tbCustomParam then
        bWithAnim = tbCustomParam.bWithAnim and tbCustomParam.bWithAnim or false
    end
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    GameCameraManager:UnInitCacheArmParam(bWithAnim, FREE_VIEW_INTERPSPEED)
end

local function InitShipCameraAim(self, tbCameraGroup, tbCustomParam)
    if tbCustomParam then
        local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        GameCameraManager:InitAimParam(tbCustomParam.nTargetArmLen, tbCustomParam.nAimRate)
        self.clCameraSetting.nMoveScaleX = tbCustomParam.nMoveXScale and tbCustomParam.nMoveScaleX or 1
        self.clCameraSetting.nMoveScaleY = tbCustomParam.nMoveYScale and tbCustomParam.nMoveYScale or 1
        self.clCameraSetting.nAimRate = tbCustomParam.nAimRate
    end
end

local function UinitShipCameraAim(self, tbCameraGroup, tbCustomParam)
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    GameCameraManager:UnInitAimParam()
end

local function InitHumanCameraAim(self, tbCameraGroup, tbCustomParam)
    if tbCustomParam then
        if tbCustomParam.bKeepNoChange then
            return
        end

        local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        local pUEActor = PlayerSelfHelper:GetUEActor()

        GameCameraManager:InitAttachAimParam(tbCustomParam.nTargetArmLen, tbCustomParam.CameraOffset,
            tbCustomParam.nAimRate, tbCustomParam.szAimSocket, pUEActor.Mesh)
        self.clCameraSetting.nAimRate = tbCustomParam.nAimRate
        self.clCameraSetting.nMoveScaleX = tbCustomParam.nMoveXScale and tbCustomParam.nMoveXScale or 1
        self.clCameraSetting.nMoveScaleY = tbCustomParam.nMoveYScale and tbCustomParam.nMoveYScale or 1
    end
end

local function UinitHumanCameraAim(self, tbCameraGroup, tbCustomParam)
    if tbCustomParam and tbCustomParam.bKeepNoChange then
        return
    end
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    GameCameraManager:UnInitAttachAimParam()
end

local function InitCameraGroup(self, tbCameraGroup, tbCustomParam)
    if tbCameraGroup.nGroupId == tbGroupDef.HumanFreeView then
        InitCacheArmParam(self, tbCameraGroup, tbCustomParam)
    elseif tbCameraGroup.nGroupId == tbGroupDef.HumanAiming then
        InitHumanCameraAim(self, tbCameraGroup, tbCustomParam)
    elseif tbCameraGroup.nGroupId == tbGroupDef.ShipAiming then
        InitShipCameraAim(self, tbCameraGroup, tbCustomParam)
    else
        self:InitCameraActor(tbCameraGroup, tbCustomParam)
    end

    self.clCameraSetting:InitHandleParam()
end

local function UninitCameraGroup(self, tbCameraGroup, tbCustomParam)
    if tbCameraGroup.nGroupId == tbGroupDef.HumanFreeView then
        UnInitCacheArmParam(self, tbCameraGroup, tbCustomParam)
    elseif tbCameraGroup.nGroupId == tbGroupDef.HumanAiming then
        UinitHumanCameraAim(self, tbCameraGroup, tbCustomParam)
    elseif tbCameraGroup.nGroupId == tbGroupDef.ShipAiming then
        UinitShipCameraAim(self, tbCameraGroup, tbCustomParam)
    else
        UninitCameraActor(self, tbCameraGroup, tbCustomParam)
    end
end

local function CreateCameraGroup(self, nGroupId, tbCameraParams, tbCameraModesParams)
    local tbGroup = {}
    tbGroup.bActive = false
    tbGroup.nGroupId = nGroupId
    tbGroup.tbCameraParams = tbCameraParams
    tbGroup.tbCameraModesParams = tbCameraModesParams
    tbGroup.Activate = function(SelfGroup, tbParams)
        SelfGroup.bActive = true
        InitCameraGroup(self, SelfGroup, tbParams)
    end
    tbGroup.Deactivate = function(SelfGroup, tbParams)
        SelfGroup.bActive = false
        UninitCameraGroup(self, SelfGroup, tbParams)
    end
    return tbGroup
end

function BaseCameraSystem:DeactiveMode(nModeId)
    self.InnerHelper:DeactiveCameraMode(nModeId)
end

function BaseCameraSystem:ActiveCameraMode(nModeId, tbParams)
    local tbRealParams = nil
    if tbParams then
        tbRealParams = tbParams
    else
        local tbCameraGroup = self.tbCameraGroups[self.nCurrentGroupId]
        local tbGroupModeParams = tbCameraGroup.tbCameraModesParams       --find mode params
        local szParamKey = tbModeDef.ModeParamKey[nModeId]        --find default param key
        local tbModeParam = tbGroupModeParams[szParamKey]
        tbRealParams = tbModeParam
    end
    
    self.InnerHelper:ActiveCameraMode(nModeId, tbRealParams)
end

function BaseCameraSystem:Register(nGroupId, tbCameraParams, tbCameraModesParams)
    local tbCameraGroup = CreateCameraGroup(self, nGroupId, tbCameraParams, tbCameraModesParams)
    self.tbCameraGroups[nGroupId] = tbCameraGroup
end

function BaseCameraSystem:ActiveCameraLogic(nGroupId, tbLastDeactiveParam, tbActiveParams)
    local nLastGroupId = self.nCurrentGroupId
    local tbLastGroup = self.tbCameraGroups[nLastGroupId]
    if tbLastGroup and tbLastGroup.bActive then
        tbLastGroup:Deactivate(tbLastDeactiveParam)
    end

    self.nLastGroupId = nLastGroupId
    self.nCurrentGroupId = nGroupId
    local tbCurrentGroup = self.tbCameraGroups[nGroupId]
    if tbCurrentGroup then
        tbCurrentGroup:Activate(tbActiveParams)
    end
end

function BaseCameraSystem:IsCameraLogicActive(nGroupId)
    if not self.tbCameraGroups then
        return false
    end

    if self.nCurrentGroupId == nGroupId then
        local tbGroup = self.tbCameraGroups[nGroupId]
        if tbGroup and tbGroup.bActive then
            return true
        end
    end
    return false
end

function BaseCameraSystem:IsCameraLockInput()
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    if GameCameraManager.LockMoveInput then
        return GameCameraManager.LockMoveInput
    end
    return false
end

--child must implement it
function BaseCameraSystem:OnCreateLogics()
    local LogicDef = tbGroupDef.LogicDef
    self.clCameraSetting = self.InnerHelper:CreateCameraLogic(LogicDef.CL_COMMON_SETTING)
end

function BaseCameraSystem:Init()
    self.tbCameraGroups = {}
    self.nCurrentGroupId = 0
    self.nLastGroupId = 0
    self.SelfEventHelper = SelfEventHelper()

    self.InnerHelper = CameraInnerHelper()
    self.InnerHelper:SetOwner(self)
    self:OnCreateLogics()
    self.InnerHelper:BindEvent()
end

function BaseCameraSystem:Uninit()
    self.tbCameraGroups = nil
    self.SelfEventHelper:UnregisterAll()

    self.InnerHelper:UnbindEvent()
    self.InnerHelper:DestroyAllCameraLogic()
end

return BaseCameraSystem()



