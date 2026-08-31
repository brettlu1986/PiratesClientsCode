
local luaclass = require("luaclass")
local BaseCameraSystem = require("BaseCameraSystem")
local HomeLandCameraSystem = luaclass("HomeLandCameraSystem", BaseCameraSystem)
local GameCameraModeGroupRegister = require("GameCameraModeGroupRegister")
local ClientEventDef = require("ClientEventDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local GameCameraModeDef = require("GameCameraModeDef")
local CameraGroupDataTable = require("CameraGroupDataTable")
local HumanCameraDataTable = require("HumanCameraDataTable")

local tbGroupDef = GameCameraModeGroupDef
local tbModeDef = GameCameraModeDef
local HumanState = tbGroupDef.HumanState

local function GetCameraActor()
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0) 
    local CameraActor = GameCameraManager:GetPlayerCameraActor()
    return CameraActor
end

local function GetSpringArm()
    local CameraActor = GetCameraActor()
    local Arm = CameraActor:GetSpringArm()
    return Arm
end

local function OnPlayerSelfReady(self)
    local tbPlayer = PlayerSelfHelper:Get()
    local pUEActor = PlayerSelfHelper:GetUEActor()
    if tbPlayer:IsHuman() then
        local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.Normal)
        local GCMgr = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)
        self:ActiveCameraLogic(tbGroupDef.HumanNormal, nil, { 
            tbConfigInitParams = tbInitParams,
            tbTargetParams = { 
                pFollowTarget = pUEActor, 
                pFollowType = ECameraFollowType.Attach,
                bSetControlRot = true 
            } 
        })
        self:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = true })
    end
end 

local function OnActiveCameraGroup(self, nGroupId, tbParams)
    if nGroupId == tbGroupDef.BuildingView then 
        local pArm = GetSpringArm()
        pArm.bDoCollisionTest = false
        local tbInitParams = CameraGroupDataTable:GetCameraGroupParam(tbGroupDef.BuildingView)
        self:ActiveCameraLogic(tbGroupDef.BuildingView, nil, { 
            tbConfigInitParams = tbInitParams,
            tbTargetParams = { 
                pFollowTarget = tbParams.pTarget, 
                pFollowType = ECameraFollowType.Attach,
                bSetControlRot = true 
            } 
        })
        self:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = tbParams.pTarget, bImmediatly = false, nBlendTime = 1 })
    end
end

local function OnDeactiveCameraGroup(self, nGroupId, tbParams)
    if nGroupId == tbGroupDef.BuildingView then  
        local pArm = GetSpringArm()
        pArm.bDoCollisionTest = true

        local pUEActor = PlayerSelfHelper:GetUEActor()
        local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.Normal)
        local GCMgr = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)

        local tbTargetParams = { pFollowTarget = pUEActor, pFollowType = ECameraFollowType.Attach, bSetControlRot = true }
        self:ActiveCameraLogic(tbGroupDef.HumanNormal, nil, { tbConfigInitParams = tbInitParams, tbTargetParams = tbTargetParams })
        self:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = false, nBlendTime = 1 })
    end
end

function HomeLandCameraSystem:OnCreateLogics()
    HomeLandCameraSystem.super.OnCreateLogics(self)
end

function HomeLandCameraSystem:Init()
    HomeLandCameraSystem.super.Init(self)
    
    GameCameraModeGroupRegister:RegisterHomelandCameraModeGroup(self)
    local EventHelper = self.SelfEventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, self, OnActiveCameraGroup)
    EventHelper:RegisterEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, self, OnDeactiveCameraGroup)
    return true
end

function HomeLandCameraSystem:Uninit()
    
    HomeLandCameraSystem.super.Uninit(self)
end

return HomeLandCameraSystem()
