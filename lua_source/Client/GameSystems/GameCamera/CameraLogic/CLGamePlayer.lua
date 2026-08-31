
-----------------------------------------------------
--File Name    : CLGamePlayer.lua
--Description  : 跳伞及人物创建相关
-----------------------------------------------------
local luaclass = require("luaclass")
local CameraLogicBase = require("CameraLogicBase")
local CLGamePlayer = luaclass("CLGamePlayer", CameraLogicBase)

local DelayTimer = require("DelayTimer")
local CameraIni = require("CameraIni")
local ClientEventDef = require("ClientEventDef")
local GameCameraModeDef = require("GameCameraModeDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local TransporterDataTable = require("TransporterDataTable")
local CameraGroupDataTable = require("CameraGroupDataTable")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local TransporterCameraDataTable = require("TransporterCameraDataTable")
local HumanMovementStateType = require("HumanMovementStateType")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanCapsuleDataTable = require("HumanCapsuleDataTable")
local SettingSystemNew = require("SettingSystemNew")
local SettingKeyDef = require("SettingKeyDef")
local TutorialDungeonIni = require("TutorialDungeonIni")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local HumanCameraDataTable = require("HumanCameraDataTable")
local ShipCameraDataTable = require("ShipCameraDataTable")
local DamageTypeEx = require("DamageTypeEx")
local GameCameraShakeHelper = require("GameCameraShakeHelper")
local HumanWeaponCameraTimeDataTable = require("HumanWeaponCameraTimeDataTable")

local tbGroupDef = GameCameraModeGroupDef
local tbModeDef = GameCameraModeDef
local HumanState = GameCameraModeGroupDef.HumanState
local tbWatchBattleDef = GameCameraModeGroupDef.WatchBattleDef
local SETTING_BASIC_CLOSE = 0
local SETTING_BASIC_AIMOPEN = 1
local SETTING_AIMOPEN = 1

CLGamePlayer.pOnParabolaReachTopPoint = nil
CLGamePlayer.pOnHumanNearGround = nil
-- CLGamePlayer.pOnHumanGroundRoll = nil
CLGamePlayer.bStopParachuteCamera = false  --为了解决一个非寻常操作行为的bug，人在跳伞过程中gm自杀进结算
CLGamePlayer.tbGroundRollTimer = nil
CLGamePlayer.nPlayerTransporterId = -1
CLGamePlayer.pTransporter = nil
CLGamePlayer.bFirstInit = false
CLGamePlayer.tbTimerObject = nil
CLGamePlayer.pCameraManagerEndPlay = nil
CLGamePlayer.bWatchAim = false

local DAMAGE_TYPE_TO_SHAK_ID =
{
    [DamageTypeEx.HUMAN_GRENADE] = 3,
    [DamageTypeEx.HUMAN_MAGIC] = 4
}

local function LOG(...)
    log("[ParachuteCamera]:", ...)
end

local function IsTutorialDungeon()
    local nDungeonId = BattleGameModeSystem.nDungeonId
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return true
    end
    return false
end

local function ClearTimer(self)
    if self.tbTimerObject then
        DelayTimer:ClearTimer(self.tbTimerObject)
        self.tbTimerObject = nil
    end
end

local function LockInputInTime(self, nTime)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    GameCameraManager.LockMoveInput = true
    GameCameraManager.ForbiddenFreeView = true
    ClearTimer(self)
    self.tbTimerObject = DelayTimer:DelayRun(function()
        GameCameraManager.LockMoveInput = false
        GameCameraManager.ForbiddenFreeView = false
    end, nTime)
end

local function OnHumanGyroCheck(self, nGyroValue)
    local tbPlayer = PlayerSelfHelper:Get()
    local bIsHuman = tbPlayer:IsHuman()
    if not bIsHuman then
        return
    end

    local CameraManager = self.Owner.InnerHelper:GetCameraManager()

    if IsTutorialDungeon() then
        CameraManager.EnableGyro = false
        return
    end

    local nValue = nGyroValue
    if nValue == nil then
        nValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.HUMAN_GYRO)
    end
    if nValue == SETTING_BASIC_CLOSE then
        CameraManager.EnableGyro = false
    elseif nValue == SETTING_BASIC_AIMOPEN then
        CameraManager.EnableGyro = self.Owner.nCurrentGroupId == tbGroupDef.HumanAiming
    else
        CameraManager.EnableGyro = true
    end
end


local function ProcessParachuteBegin(self, tbParams)
    if self.Owner.nCurrentGroupId == tbGroupDef.NewParachuteShipping then
        return
    end
    self.bStopParachuteCamera = false
    
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    GameCameraManager:UnInitCameraActorParam()
    self.Owner:DeactiveMode(tbModeDef.ModeCameraTrack)
    self.nPlayerTransporterId = tbParams.nTransporterId
    self.pTransporter = tbParams.pTarget

    local tbTransporterCfg = nil  
    local tbTransporterData = TransporterDataTable:GetTemplate(tbParams.nTransporterId)
    if tbTransporterData then  
        tbTransporterCfg = TransporterCameraDataTable:GetTransporterCameraParams(tbTransporterData.nDummyId)
    end
    local tbDefaultCfg = CameraGroupDataTable:GetCameraGroupParam(tbGroupDef.NewParachuteShipping)
    local tbInitParams = tbTransporterCfg ~= nil and tbTransporterCfg or tbDefaultCfg
    self.Owner:ActiveCameraLogic(tbGroupDef.NewParachuteShipping, nil, {
        tbConfigInitParams = tbInitParams,
        tbTargetParams = {
            pFollowTarget = tbParams.pTarget,
            pFollowType = ECameraFollowType.NotAttachFollowLocationXY,
            bSetControlRot = true
        }
    })
    OnHumanGyroCheck(self)
    self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = tbParams.pTarget, bImmediatly = true})
end

local function ProcessParachuteLaunchFocus(self, tbParams)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    self.Owner:DeactiveMode(tbModeDef.ModeCameraTrack)
    GameCameraManager:UnInitCameraActorParam()
    LOG(" Detach before NewParachuteLaunchFocus")
    local tbTransporterCfg = nil
    if self.nPlayerTransporterId then
        local tbTransporterData = TransporterDataTable:GetTemplate(self.nPlayerTransporterId)
        if tbTransporterData then  
            tbTransporterCfg = TransporterCameraDataTable:GetTransporterCameraParams(tbTransporterData.nDummyId)
        end
    end
    local tbDefaultCfg = CameraGroupDataTable:GetCameraGroupParam(tbGroupDef.NewParachuteShipping)
    local tbInitParams = tbTransporterCfg ~= nil and tbTransporterCfg or tbDefaultCfg

    if self.pTransporter then
        self.Owner:ActiveCameraLogic(tbGroupDef.NewParachuteLaunchFocus, nil, {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = {
                pFollowTarget = self.pTransporter,
                pFollowType = ECameraFollowType.NotAttachFollowLocationXY,
                bSetControlRot = true
            }
        })
        self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = self.pTransporter, bImmediatly = true})
    else
        LOG("NewParachuteLaunchFocus")
        self.Owner:ActiveCameraLogic(tbGroupDef.NewParachuteLaunchFocus, { bKeepNoChange = true },  { bKeepNoChange = true })
    end
    local nFocusTime = CameraGroupDataTable:GetCameraGroupParam(tbGroupDef.NewParachuteLaunchFocus).nBlendTime

    self.tbTimerObject = DelayTimer:DelayRun(function()
        local pParamTarget = tbParams.pTarget
        if pParamTarget == nil then
            pParamTarget = PlayerSelfHelper:GetUEActor()
        end
        self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.NewParachuteLaunchPlayer, {pTarget = pParamTarget})
    end, nFocusTime)--给一个播放发射特效的时间
end

local function ProcessParachuteLaunchPlayer(self, tbParams)
    self.Owner:DeactiveMode(tbModeDef.ModeCameraTrack)
    local tbInitParams = CameraGroupDataTable:GetCameraGroupParam(tbGroupDef.NewParachuteLaunchPlayer)
    local tbTargetParams = { pFollowTarget = tbParams.pTarget, pFollowType = ECameraFollowType.Attach, bSetControlRot = true }
    local GCMgr = self.Owner.InnerHelper:GetCameraManager()
    GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)

    LOG("NewParachuteLaunchPlayer")
    self.Owner:ActiveCameraLogic(tbGroupDef.NewParachuteLaunchPlayer, nil, {
        tbConfigInitParams = tbInitParams,
        tbTargetParams = tbTargetParams,
    })

    --直接attach
    self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = tbParams.pTarget, bImmediatly = true})
    self.Owner:ActiveCameraMode(tbModeDef.ModeShake, {
        TargetAngle = Vector{X = 0, Y = 0, Z = 1},
        RecoverAngle = Vector{X = 0, Y = 0, Z = 0},
        PosOffset = Vector{X = 0, Y = 0 , Z = 0},
        TargetTime = 0.2,
        nFov = 0,
        nDecayParam = 0,
        nShakeCount = -1,
        bRecoil = false,
        bFollowPitch = false,
        bUseRecoverV = false })
end

local function ProcessParachuteReachTopPoint(self)
    LOG("ProcessParachuteReachTopPoint")
    self.Owner:ActiveCameraLogic(tbGroupDef.NewParachuteTopPoint, { bKeepNoChange = true }, { bKeepNoChange = true })
    local tbInitParams = CameraGroupDataTable:GetCameraGroupParam(tbGroupDef.NewParachuteTopPoint)
    self.Owner:ActiveCameraMode(tbModeDef.ModeArmRot, { nTargetRot = tbInitParams.ArmRotation, nBlendTime = tbInitParams.nBlendTime })

    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    local Arm = self.Owner.InnerHelper:GetArm()
    GameCameraManager:ResetBaseSocketOffset(Arm.SocketOffset)
    local OffsetMove = Vector{
        X = tbInitParams.SocketOffset.X - Arm.SocketOffset.X,
        Y = tbInitParams.SocketOffset.Y - Arm.SocketOffset.Y,
        Z = tbInitParams.SocketOffset.Z - Arm.SocketOffset.Z
    }
    self.Owner:ActiveCameraMode(tbModeDef.ModeOffsetMove, { MoveOffset = OffsetMove, nBlendTime = tbInitParams.nBlendTime, bNeedBlend = true })
    LockInputInTime(self, tbInitParams.nBlendTime)
end

local function ProcessParachuteOpenParachute(self)
    LOG("ProcessParachuteOpenParachute")
    self.Owner:DeactiveMode(tbModeDef.ModeCameraTrack)
    local tbInitParams = CameraGroupDataTable:GetCameraGroupParam(tbGroupDef.NewParachuteOpenParachute)
    self.Owner:ActiveCameraLogic(tbGroupDef.NewParachuteOpenParachute, { bKeepNoChange = true }, { bKeepNoChange = true })
    self.Owner:ActiveCameraMode(tbModeDef.ModeArmRot, { nTargetRot = tbInitParams.ArmRotation, nBlendTime = tbInitParams.nBlendTime })
    self.Owner:DeactiveMode(tbModeDef.ModeShake)
    LockInputInTime(self, tbInitParams.nBlendTime)
end

local function ProcessHumanNormal(self)
    local pUEActor = PlayerSelfHelper:GetUEActor()
    if self.Owner.nLastGroupId == tbGroupDef.NewParachuteOpenParachute then
        self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_FREE_VIEW, true)
    end
    self.Owner:DeactiveMode(tbModeDef.ModeCameraTrack)
    self.Owner:DeactiveMode(tbModeDef.ModeArmLen)
    self.Owner:DeactiveMode(tbModeDef.ModeOffsetMove)
    self.Owner:DeactiveMode(tbModeDef.ModeArmRot)

    local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.Normal)

    local GCMgr = self.Owner.InnerHelper:GetCameraManager()
    GCMgr:EnableAutoRot(false)
    GCMgr:CheckJoytickEventForAutoRot(false)
    GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)
    local pArm = self.Owner.InnerHelper:GetArm()
    pArm:UpdatePreArmLocationZ(tbInitParams.ArmLocation.Z)
    local tbTargetParams = { pFollowTarget = pUEActor, pFollowType = ECameraFollowType.Attach, bSetControlRot = true }
    LOG("ProcessHumanNormal")
    self.Owner:ActiveCameraLogic(tbGroupDef.HumanNormal, nil, { tbConfigInitParams = tbInitParams, tbTargetParams = tbTargetParams })
    self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = true })
end

local function OnActiveCameraGroup(self, nGroupId, tbParams)
    if self.bStopParachuteCamera then
        return
    end
    if nGroupId == tbGroupDef.NewParachuteLaunchFocus then
        ProcessParachuteLaunchFocus(self, tbParams)
    elseif nGroupId == tbGroupDef.NewParachuteLaunchPlayer then
        ProcessParachuteLaunchPlayer(self, tbParams)
    elseif nGroupId == tbGroupDef.NewParachuteShipping then
        ProcessParachuteBegin(self, tbParams)
    elseif nGroupId == tbGroupDef.NewParachuteOpenParachute then
        ProcessParachuteOpenParachute(self)
    elseif nGroupId == tbGroupDef.HumanNormal then  --跳伞结束落地 切回正常人
        ProcessHumanNormal(self)
    elseif nGroupId == tbGroupDef.HumanFreeView then
        local GCMgr = self.Owner.InnerHelper:GetCameraManager()
        GCMgr.FreeViewMove = true
        self.Owner:ActiveCameraLogic(tbGroupDef.HumanFreeView, { bKeepNoChange = true }, tbParams)
    end
end

local function OnParabolaReachTopPoint(self)
    if self.bStopParachuteCamera then
        return
    end
    ProcessParachuteReachTopPoint(self)
end

local function OnHumanNearGround(self)
    self.Owner:DeactiveMode(tbModeDef.ModeShake)
    self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.HumanNormal)
end

local function OnFFAResult(self, tbPacket)
    local nCurrentGroupId = self.Owner.nCurrentGroupId
    if nCurrentGroupId == tbGroupDef.NewParachuteShipping or nCurrentGroupId == tbGroupDef.NewParachuteLaunchFocus
        or nCurrentGroupId == tbGroupDef.NewParachuteLaunchPlayer or nCurrentGroupId == tbGroupDef.NewParachuteTopPoint
         or nCurrentGroupId == tbGroupDef.NewParachuteOpenParachute then
            --非常规操作结算
        self.bStopParachuteCamera = true
        self.Owner:DeactiveMode(tbModeDef.ModeShake)
        local GCMgr = self.Owner.InnerHelper:GetCameraManager()
        GCMgr:UnInitCameraForDead()
    end
end

local function OnForceGroundHumanView(self)
    LOG("On Force Ground Human", self.bStopParachuteCamera)
    -- if self.Owner.nCurrentGroupId == tbGroupDef.HumanNormal then
    --     return
    -- end
    -- OnActiveCameraGroup(self, tbGroupDef.HumanNormal)
    self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.HumanNormal)
end

local function OnWatchBattleCameraChanged(self, nWatchState, tbParam)
    if nWatchState == tbWatchBattleDef.ChangeAim then
        if not tbParam.bIsShip then
            self.bWatchAim = tbParam.bInAim
        end
    end
end

local function OnMovementCameraOffsetChange(self, nOffset, nBlendTime, bNeedBlend, nStatePitchMax, nStatePitchMin)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    GameCameraManager:ResetPitchView(nStatePitchMax, nStatePitchMin)

    if not self.Owner:IsCameraLogicActive(tbGroupDef.ViewTeammateHuman) then
        if not self.Owner:IsCameraLogicActive(tbGroupDef.HumanAiming) then
            self.Owner:ActiveCameraMode(tbModeDef.ModeOffsetMove, { MoveOffset = nOffset, nBlendTime = nBlendTime, bNeedBlend = bNeedBlend })
        end
    else
        if not self.bWatchAim then
            self.Owner:ActiveCameraMode(tbModeDef.ModeOffsetMove, { MoveOffset = nOffset, nBlendTime = nBlendTime, bNeedBlend = bNeedBlend })
        end
    end
end

local function OnFireCameraShake(self, InRecoilTargetAngle, InRecoilRecoverAngle, InRecoilPosOffset, InRecoilTargetTime, nFov, nDecayParam, nShakeCount, bRecoil, bFollowPitch, bUseRecoverV)
    self.Owner:ActiveCameraMode(tbModeDef.ModeShake, { TargetAngle = InRecoilTargetAngle, RecoverAngle = InRecoilRecoverAngle, PosOffset = InRecoilPosOffset, 
    TargetTime = InRecoilTargetTime, nFov = nFov, nDecayParam = nDecayParam, nShakeCount = nShakeCount, bRecoil = bRecoil, bFollowPitch = bFollowPitch, bUseRecoverV = bUseRecoverV })
end

--受到火球跟手雷的震屏伤害
local function OnTakeDamage(self, tbTaker, tbCauser, nDamage, nDamageType, nHp, nWeaponTempId, tbExtraData)
    local PlayerSelf = PlayerSelfHelper:Get()
    local bOwnerIsTaker = tbTaker and tbTaker.nServerInstanceId == PlayerSelf.nServerInstanceId 
    if bOwnerIsTaker then 
        local nShakeId = DAMAGE_TYPE_TO_SHAK_ID[nDamageType]
        if nShakeId ~= nil then  
            local HumanWeaponComponent = PlayerSelf.HumanWeaponComponent
            if not HumanWeaponComponent then  
                return
            end
            local bAiming = HumanWeaponComponent:IsAiming()
            if not bAiming then
                GameCameraShakeHelper.GameShake(nShakeId)
            end
        end
    end
end

local function CheckShipGyroEnable(self, bAim)
    local GCMgr = self.Owner.InnerHelper:GetCameraManager()
    if IsTutorialDungeon() then
        GCMgr.EnableGyro = false
        return
    end
    local nValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.SHIP_GYRO)
    if nValue == SETTING_AIMOPEN then
        GCMgr.EnableGyro = bAim
    end
end

local function OnShipGyroCheck(self, nGyroValue)
    local tbPlayer = PlayerSelfHelper:Get()
    local bIsShip = tbPlayer:IsShip()
    if not bIsShip then
        return
    end

    local CameraManager = self.Owner.InnerHelper:GetCameraManager()
    if IsTutorialDungeon() then
        CameraManager.EnableGyro = false
        return
    end

    local nValue = nGyroValue
    if nValue == nil then
        nValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.SHIP_GYRO)
    end

    if nValue == SETTING_BASIC_CLOSE then
        CameraManager.EnableGyro = false
    elseif nValue == SETTING_BASIC_AIMOPEN then
        CameraManager.EnableGyro = self.Owner.nCurrentGroupId == tbGroupDef.ShipAiming
    else
        CameraManager.EnableGyro = true
    end
end

local function OnHumanAimAssistCheck(self, nAisistValue)
    local tbPlayer = PlayerSelfHelper:Get()
    local bIsHuman = tbPlayer:IsHuman()
    if not bIsHuman then
        return
    end

    local nValue = nAisistValue
    if nValue == nil then
        nValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.AIM_ASSIST)
    end

    if nValue == SETTING_BASIC_CLOSE then
        tbPlayer.pUEActor.EnableNewAim = false
    elseif nValue == SETTING_BASIC_AIMOPEN then
        tbPlayer.pUEActor.EnableNewAim = self.Owner.nCurrentGroupId == tbGroupDef.HumanAiming
    else
        tbPlayer.pUEActor.EnableNewAim = true
    end
end

--因为ActiveCameraLogic里面会先把当前的Deactive,所以直接Active新的就行
local function OnDeactiveCameraGroup(self, nGroupId, tbParams)
    --小眼睛结束需要Active之前的，并且不需要重新Init
    if nGroupId == tbGroupDef.HumanFreeView then
        local GCMgr = self.Owner.InnerHelper:GetCameraManager()
        GCMgr.FreeViewMove = false
        local nLastId = self.Owner.nLastGroupId
        local nMoveScale_X, nMoveScale_Y
        if nLastId == tbGroupDef.NewParachuteOpenParachute then
            self.Owner:ActiveCameraLogic(tbGroupDef.NewParachuteOpenParachute, tbParams, { bKeepNoChange = true} )
        elseif nLastId == tbGroupDef.VehicleView then
            self.Owner:ActiveCameraLogic(tbGroupDef.VehicleView, tbParams, { bKeepNoChange = true} )
            nMoveScale_X, nMoveScale_Y = self.Owner:GetCameraMoveScale()
            GCMgr:SetHandleMoveParam(nMoveScale_X, nMoveScale_Y, EHandleInputType.UseArm)
        elseif nLastId == tbGroupDef.BotHuman then
            self.Owner:ActiveCameraLogic(tbGroupDef.BotHuman, tbParams, { bKeepNoChange = true} )
            nMoveScale_X, nMoveScale_Y = self.Owner:GetCameraMoveScale()
            GCMgr:SetHandleMoveParam(nMoveScale_X, nMoveScale_Y, EHandleInputType.UseArm)
        else
            self.Owner:ActiveCameraLogic(tbGroupDef.HumanNormal, tbParams, { bKeepNoChange = true} )
            local tbPlayer = PlayerSelfHelper:Get()
            local MovementComponent = tbPlayer.HumanMovementStateComponent
            nMoveScale_X, nMoveScale_Y = self.Owner:GetCameraMoveScale()
            if MovementComponent then
                if MovementComponent:IsInVehicle() then
                    GCMgr:SetHandleMoveParam(nMoveScale_X, nMoveScale_Y, EHandleInputType.UseArm)
                else
                    local nCurrentMovementState = MovementComponent:GetCurrentState()
                    if nCurrentMovementState == HumanMovementStateType.Crawl_State then
                        GCMgr:SetHandleMoveParam(nMoveScale_X, nMoveScale_Y, EHandleInputType.UseControllerArm)
                    else
                        GCMgr:SetHandleMoveParam(nMoveScale_X, nMoveScale_Y, EHandleInputType.UseControllerArmPitch)
                    end
                end
            else
                GCMgr:SetHandleMoveParam(nMoveScale_X, nMoveScale_Y, EHandleInputType.UseControllerArmPitch)
            end
        end
    end
end

--注册放到 player创建结束，是因为cameraManager在System init的时候还没有创建
local function UnregisterParachuteEvent(self)
    local EventHelper = self.EventHelper
    if(self.pOnParabolaReachTopPoint ~= nil)then
        EventHelper:UnregisterCppDelegate(self.pOnParabolaReachTopPoint)
        self.pOnParabolaReachTopPoint = nil
    end

    if(self.pOnHumanNearGround ~= nil)then
        EventHelper:UnregisterCppDelegate(self.pOnHumanNearGround)
        self.pOnHumanNearGround = nil
    end

    -- if(self.pOnHumanGroundRoll ~= nil)then
    --     EventHelper:UnregisterCppDelegate(self.pOnHumanGroundRoll)
    --     self.pOnHumanGroundRoll = nil
    -- end

    if(self.pCameraManagerEndPlay ~= nil)then
        EventHelper:UnregisterCppDelegate(self.pCameraManagerEndPlay)
        self.pCameraManagerEndPlay = nil
    end
end

local function OnPlayerManagerEndPlay(self)
    UnregisterParachuteEvent(self)
end

local function RegisterParachuteEvent(self)
    local EventHelper = self.EventHelper
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    self.pOnParabolaReachTopPoint = EventHelper:RegisterCppDelegate(GameCameraManager.OnParabolaReachTopPoint, self, OnParabolaReachTopPoint)
    self.pOnHumanNearGround = EventHelper:RegisterCppDelegate(GameCameraManager.OnHumanNearGround, self, OnHumanNearGround)
    -- self.pOnHumanGroundRoll = EventHelper:RegisterCppDelegate(GameCameraManager.OnHumanGroundRoll, self, OnHumanGroundRoll)
    self.pCameraManagerEndPlay = EventHelper:RegisterCppDelegate(GameCameraManager.OnEndPlay, self, OnPlayerManagerEndPlay)
end

local function RegistCameraEvent(self)
    --单机副本情况下不注册这些代理
    if(GlobalVariableSystem.bIsStandalone) then
        return
    end
    --重复绑定 会越滑越快！T_T
    UnregisterParachuteEvent(self)
    RegisterParachuteEvent(self)
end

--为断线重连进来 恢复相应应相机状态设置
local function ChangeCapsuleForCurrentState(self, tbCharacter, nState)
    local pUEActor = tbCharacter.pUEActor
    local nTemplateId = tbCharacter:GetHumanTemplateId()
    local CapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, nState)

    local nCapsuleRadius = pUEActor.CapsuleComponent:GetUnscaledCapsuleRadius()
    local nCapsuleHalfHeight = CapsuleData.nCapsuleHalfHeight
    if nCapsuleHalfHeight < nCapsuleRadius then
        nCapsuleHalfHeight = nCapsuleRadius
    end
    pUEActor.CapsuleComponent:SetCapsuleHalfHeight(nCapsuleHalfHeight)

    local LastCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.UpRight_State)
    local OffsetZ= nCapsuleHalfHeight - LastCapsuleData.nCapsuleHalfHeight

    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    local CameraActor = GameCameraManager:GetPlayerCameraActor()
    CameraActor:K2_DetachFromActor(EDetachmentRule.KeepWorld, EDetachmentRule.KeepWorld, EDetachmentRule.KeepWorld)
    local pLocation = CameraActor:K2_GetActorLocation()
    CameraActor:K2_SetActorLocation(Vector{X=pLocation.X, Y=pLocation.Y, Z=pLocation.Z - OffsetZ}, true, true)
    CameraActor:K2_AttachToActor(pUEActor, nil, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, false)

    pLocation = pUEActor:K2_GetActorLocation()
    pUEActor:K2_SetActorLocation(Vector{X=pLocation.X, Y=pLocation.Y, Z=pLocation.Z + OffsetZ}, true, true)

    local OffsetVector = Vector{X=0, Y=0, Z=nCapsuleHalfHeight * -1}
    pUEActor.BaseTranslationOffset = OffsetVector
    pUEActor.Mesh:K2_SetRelativeLocation(OffsetVector)

    ExtendBlueprintFunctions.ChangePlayerMeshTranslationOffset(pUEActor.CharacterMovement, OffsetZ * -1)
end

local function CorrectHumanState(self)
    local tbPlayer = PlayerSelfHelper:Get()
    local MovementComponent = tbPlayer.HumanMovementStateComponent
    if not MovementComponent then
        log("human movement state none")
        return
    end
    local nCurrentMovementState = MovementComponent:GetCurrentState()
    log("[HumanCamera] correct human camera crawl", nCurrentMovementState)

    local nStateType = HumanMovementStateType
    if nCurrentMovementState == nStateType.Crawl_State then
        log("[HumanCamera] correct human camera crawl")
        ChangeCapsuleForCurrentState(self, tbPlayer, nStateType.Crawl_State)
        local nBlendTime = HumanWeaponCameraTimeDataTable:GetMovementCameraTime(0, nStateType.UpRight_State, nStateType.Crawl_State)
        local Offset = HumanCameraDataTable:GetMovementCameraOffset(nStateType.Crawl_State)
        local nStatePitchMax, nStatePitchMin = HumanCameraDataTable:GetMovementCameraPitchLimit(nStateType.Crawl_State)

        OnMovementCameraOffsetChange(self, Offset, nBlendTime, false, nStatePitchMax, nStatePitchMin)
        self.EventHelper:FireEvent(CommonEventDef.EV_ACTIVE_CRAWL_CAMERA, tbPlayer, true)
    elseif nCurrentMovementState == nStateType.Crouch_State then

        ChangeCapsuleForCurrentState(self, tbPlayer, nStateType.Crouch_State)
        local nBlendTime = HumanWeaponCameraTimeDataTable:GetMovementCameraTime(0, nStateType.UpRight_State, nStateType.Crouch_State)
        local Offset = HumanCameraDataTable:GetMovementCameraOffset(nStateType.Crouch_State)
        local nStatePitchMax, nStatePitchMin = HumanCameraDataTable:GetMovementCameraPitchLimit(nStateType.Crouch_State)
        log("[HumanCamera] correct human camera crouch ::", Offset.X, Offset.Y, Offset.Z)
        OnMovementCameraOffsetChange(self, Offset, nBlendTime, false, nStatePitchMax, nStatePitchMin)
    elseif nCurrentMovementState == nStateType.Parachutine_State then
        log("[HumanCamera] correct human camera Parachutine_State")
        self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, tbGroupDef.NewParachuteOpenParachute)
    elseif nCurrentMovementState == nStateType.Swimming then
        log("[HumanCamera] correct human camera Swimming")
        OnActiveCameraGroup(self, tbGroupDef.HumanSwimming, {bImmediatly = true})
    elseif nCurrentMovementState == nStateType.Dying_State then
        log("[HumanCamera] correct human camera Dying_State")
        ChangeCapsuleForCurrentState(self, tbPlayer, nStateType.Dying_State)
        local nBlendTime = HumanWeaponCameraTimeDataTable:GetMovementCameraTime(0, nStateType.UpRight_State, nStateType.Dying_State)
        local Offset = HumanCameraDataTable:GetMovementCameraOffset(nStateType.Dying_State)
        local nStatePitchMax, nStatePitchMin = HumanCameraDataTable:GetMovementCameraPitchLimit(nStateType.Dying_State)
        OnMovementCameraOffsetChange(self, Offset, nBlendTime, false, nStatePitchMax, nStatePitchMin)
    end
end

local function OnPlayerSelfReady(self)
    --船形态进入跳伞就不应该再走一遍这里，因为此时看的是 运输船
    if self.bStopParachuteCamera then
        log("[HumanCamera] OnPlayerSelfReady, return for bStopParachuteCamera")
        return
    end

    if self.Owner.nCurrentGroupId == tbGroupDef.NewParachuteShipping  then
        log("[HumanCamera] OnPlayerSelfReady, return for groupid is NewParachuteShipping")
        return
    end

    local tbPlayer = PlayerSelfHelper:Get()
    local pUEActor = PlayerSelfHelper:GetUEActor()

    if self.Owner.nCurrentGroupId == tbGroupDef.VehicleView and tbPlayer:IsHuman() then
        log("[HumanCamera] OnPlayerSelfReady, return for groupid is VehicleView")
        return
    end

    RegistCameraEvent(self)
    local tbInitParams = nil
    self.Owner.InnerHelper:SafeSpawnCameraActor()
    local GCMgr = self.Owner.InnerHelper:GetCameraManager()
    local pArm = self.Owner.InnerHelper:GetArm()

    log("[HumanCamera] OnPlayerSelfReady")
    GCMgr:EnableAutoRot(false)
    GCMgr:CheckJoytickEventForAutoRot(false)
    if tbPlayer:IsShip() then
        if GCMgr:IsArmBackRotBack() then
            GCMgr:UnInitCacheArmParam(false, 0);
        end

        tbInitParams = ShipCameraDataTable:GetShipInitCameraParam(tbPlayer:GetShipTemplateId())
        GCMgr:ResetBaseSocketOffset(Vector{X = 0, Y = 0, Z = 0})
        local pVarFollowType = ECameraFollowType.NotAttachFollowLocationXY
        self.Owner:ActiveCameraLogic(tbGroupDef.ShipNormal, nil, {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = {
                pFollowTarget = pUEActor,
                pFollowType = pVarFollowType,
                bSetControlRot = true
            }
        })

        pArm:UpdatePreArmLocationZ(tbInitParams.ArmLocation.Z)
        --跳伞到海里  需要blend一下，加在这里不加到跳伞结束 是因为客户端OnParachuteEnd的时候 ，因为时序并不知道此时船是否创建成功
        if self.bFirstInit then
            self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = true})
            GCMgr.LockMoveInput = false
        else
            self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = false, nBlendTime = 1 })
            LockInputInTime(self, 1.5)
        end
        OnShipGyroCheck(self)
    elseif tbPlayer:IsHuman() then
        log("[HumanCamera] OnPlayerSelfReady Human")
        self.Owner:DeactiveMode(tbModeDef.ModeOffsetMove)
        self.Owner:DeactiveMode(tbModeDef.ModeArmLen)

        GCMgr:EnableCameraMoveCollisionCheck(false, false)
        tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.Normal)
        GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)
        self.Owner:ActiveCameraLogic(tbGroupDef.HumanNormal, nil, {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = {
                pFollowTarget = pUEActor,
                pFollowType = ECameraFollowType.Attach,
                bSetControlRot = true
            }
        })
        pArm:UpdatePreArmLocationZ(tbInitParams.ArmLocation.Z)
        if self.bFirstInit then

            self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = true})
            GCMgr.LockMoveInput = false
        else
            self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = false, nBlendTime = 1 })
            LockInputInTime(self, 1.5)
        end
        CorrectHumanState(self)
        OnHumanGyroCheck(self)
        OnHumanAimAssistCheck(self, nil)
    end
    self.Owner:DeactiveMode(tbModeDef.ModeShake)
    ExtendBlueprintFunctions.LoadLevelsImmediatelyByLocation(GWorld, pUEActor:K2_GetActorLocation())
    self.bFirstInit = false
    pArm.bDoCollisionTest = true

end

local function OnShipAimStateChanged(self, tbGameObject, bIsInAim)
    if tbGameObject and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        CheckShipGyroEnable(self, bIsInAim)
    end
end

local function OnPawnBeginPlay(self, tbGameObject)
    if tbGameObject and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        self.Owner.InnerHelper:SafeSpawnCameraActor()
    end
end

local function InitFovForOceanMesh()
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "pir.OceanMeshHumanFOV ".. CameraIni.nHumanOceanFov, nil)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "pir.OceanMeshShipFOV ".. CameraIni.nShipOceanFov, nil)
end

function CLGamePlayer:OnCreate()
    InitFovForOceanMesh()
    self.bFirstInit = true
end

function CLGamePlayer:OnDestroy()
    if self.tbGroundRollTimer then
        DelayTimer:ClearTimer(self.tbGroundRollTimer)
        self.tbGroundRollTimer = nil
    end
    self.pOnParabolaReachTopPoint = nil
    self.pOnHumanNearGround = nil
    -- self.pOnHumanGroundRoll = nil
    self.bStopParachuteCamera = false
    self.nPlayerTransporterId = -1
    self.pTransporter = nil

    self.bFirstInit = false
    self.pCameraManagerEndPlay = nil
    ClearTimer(self)
end

function CLGamePlayer:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, self, OnActiveCameraGroup)
    EventHelper:RegisterEvent(ClientEventDef.EV_FORCE_GROUND_HUMAN_VIEW, self, OnForceGroundHumanView)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_RESULT, self, OnFFAResult)

    EventHelper:RegisterEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, self, OnWatchBattleCameraChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    EventHelper:RegisterEvent(ClientEventDef.EV_MOVEMENT_CAMERE_OFFSET, self, OnMovementCameraOffsetChange)
    EventHelper:RegisterEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, self, OnDeactiveCameraGroup)
    EventHelper:RegisterEvent(ClientEventDef.EV_FIRE_CAMERA_SHAKE, self, OnFireCameraShake)
    
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_AIM_STATE_CHANGED, self, OnShipAimStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_OBJECT_BEGIN_PLAY, self, OnPawnBeginPlay)
    EventHelper:RegisterEvent(ClientEventDef.EV_SETTING_HUMAN_GYRO, self, OnHumanGyroCheck)
    EventHelper:RegisterEvent(ClientEventDef.EV_SETTING_SHIP_GYRO, self, OnShipGyroCheck)
    EventHelper:RegisterEvent(ClientEventDef.EV_SETTING_AIM_ASSIST, self, OnHumanAimAssistCheck)

    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
end

function CLGamePlayer:OnUnbindEvent(EventHelper)
end

return CLGamePlayer
