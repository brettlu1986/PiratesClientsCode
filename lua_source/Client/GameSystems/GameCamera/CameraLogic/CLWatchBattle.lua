local luaclass = require("luaclass")
local CameraLogicBase = require("CameraLogicBase")
local CLWatchBattle = luaclass("CLWatchBattle", CameraLogicBase)

local DelayTimer  = require("DelayTimer")
local UIManager = require("UIManager")
local UIStateDef = require("UIStateDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local GameCameraModeDef = require("GameCameraModeDef")
local ClientEventDef = require("ClientEventDef")
local HumanCameraDataTable = require("HumanCameraDataTable")
local ShipCameraDataTable = require("ShipCameraDataTable")
local CameraGroupDataTable = require("CameraGroupDataTable")
local Proto = require("DungeonCommonProtoNames")
local GameObjectSystem = require("GameObjectSystem_C")
local HumanMovementStateType = require("HumanMovementStateType")
local VehicleCameraDataTable = require("VehicleCameraDataTable")
local CameraIni = require("CameraIni")

CLWatchBattle.bWatchShipAim = false
CLWatchBattle.tbTimerObject = nil
CLWatchBattle.bWatchAim = false

local tbWatchBattleDef = GameCameraModeGroupDef.WatchBattleDef
local tbGroupDef = GameCameraModeGroupDef
local tbModeDef = GameCameraModeDef
local HumanState = tbGroupDef.HumanState
local EState = Proto.TeamInfo_EState

local SYNC_ROT_SPEED = 4
local VIEW_SHIP_OFFSET = 3700
local VIEW_HUMAN_OFFSET = 400
local VIEW_DETACH_SHIP = 7200
local nAimBlendTime = 0.4
-- watch battle config var
local nWBCfgHumanNewAimArmLen = 5
local HUMAN_AIM_SOCKET = "AimSocket"
local DEFAULT_VEHICLE_CAMERA = 1

local function IsAlreadyBattleResultOrWatchBattle()
    local ActiveUIState = UIManager:GetActiveState()

    if not ActiveUIState then
        return false
    end

    if ActiveUIState.szName == UIStateDef.StateName.UI_FFA_RESULT_STATE
        or ActiveUIState.szName == UIStateDef.StateName.UI_WATCH_BATTLE_STATE then
        return true
    end
    return false
end

local function IsTeamLastDeadOrSingleDead()
    local tbPlayer = PlayerSelfHelper:Get()
    local tbBattleTeamInfo = tbPlayer.BattleTeamComponent.tbBattleTeamInfo
    if tbBattleTeamInfo then
        local nPlayerId = tbPlayer:GetServerInstanceId()
        local tbTeamInfo = tbBattleTeamInfo.TeamInfos

        for k, v in ipairs(tbTeamInfo) do
            if v.nInstanceId ~= nPlayerId and v.nState ~= EState.DEAD and v.nState ~= EState.ADDITIONALSUCCESS then
                return false
            end
        end
    end
    return true
end

local function GetIsOcean(tbTransform)
    local GRID_TYPE_OCEAN = EPiratesGridRegionType.Ocean
    local GRID_TYPE_PORT = EPiratesGridRegionType.Port
    local GRID_TYPE_SHORE = EPiratesGridRegionType.Shore
    local PORT_TO_LAND_MINDISTANCE = 2500

    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRegionType = GridTypeManager:GetRegionType(tbTransform.X, tbTransform.Y)
    local bIsOcean = nRegionType == GRID_TYPE_OCEAN

    if nRegionType == GRID_TYPE_PORT then
        local bRet, NewLoction = GridTypeManager:GetClosestPositionOfRegionType(tbTransform.X, tbTransform.Y, GRID_TYPE_SHORE)
        if bRet then
            local fnDistance = function(v1, v2)
                local dx = v1.X - v2.X
                local dy = v1.Y - v2.Y
                return math.sqrt(dx * dx + dy * dy)
            end
            bIsOcean = fnDistance(tbTransform, NewLoction) > PORT_TO_LAND_MINDISTANCE
        else
            error("player dead, change dead camera, but the dead ueactor position not right")
            bIsOcean = true
        end
    end
    return bIsOcean, nRegionType
end

local function OnActiveCameraGroup(self, nGroupId, tbParams)
    local tbInitParams, tbTargetParams = nil, nil
    if nGroupId == tbGroupDef.ViewTeammateHuman or nGroupId == tbGroupDef.ViewTeammateShip then
        local tbWatchTarget =  GameObjectSystem:FindByInstanceId(tbParams.nWatchInsId)
        if not tbWatchTarget or not tbWatchTarget.pUEActor then  
            logerror("[ClientWatch] target is nil:", tbWatchTarget, tbWatchTarget.pUEActor)
        end
        self.Owner:DeactiveMode(tbModeDef.ModeArmLen)
        local pArm = self.Owner.InnerHelper:GetArm()
        pArm.bDoCollisionTest = true

        local nTemplateId, pVarFollowType, bSycYaw
        local szFollowSocket = ""
        local pComponent = nil
        if nGroupId == tbGroupDef.ViewTeammateHuman then
            tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.WatchBattle)
            pVarFollowType = ECameraFollowType.AttachToSocket
            bSycYaw = false
            pComponent = tbWatchTarget.pUEActor.Mesh
        else
            nTemplateId = tbWatchTarget:GetShipTemplateId()
            tbInitParams = ShipCameraDataTable:GetShipInitCameraParam(nTemplateId)
            pVarFollowType = ECameraFollowType.NotAttachFollowLocationXY
            bSycYaw = true
        end
        pArm:UpdatePreArmLocationZ(tbInitParams.ArmLocation.Z)

        local GCMgr = self.Owner.InnerHelper:GetCameraManager()
        GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)
        local pTarget = tbWatchTarget.pUEActor
        self.Owner:ActiveCameraLogic(nGroupId, nil, {
                tbConfigInitParams = tbInitParams,
                tbTargetParams = {
                    pFollowTarget = pTarget,
                    pFollowType = pVarFollowType,
                    bSetControlRot = true,
                    FollowSocket = szFollowSocket,
                    FollowParentComponent = pComponent
                }
            })
        self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pTarget, bImmediatly = true })
        self.Owner:ActiveCameraMode(tbModeDef.ModeSyncArmRot, { bSyncYaw = bSycYaw, pPawn = pTarget, nOffsetYaw = tbParams.nOffsetYaw, nInterpSpeed = SYNC_ROT_SPEED })
    elseif nGroupId == tbGroupDef.ViewDeadBoxHuman or nGroupId == tbGroupDef.ViewDeadBoxShip then
        --成盒子之后 的镜头需要有不同的处理，如果是人状态直接成盒，摄像机就不用detach 直接原地blend过来
        --如果是死亡之后直接先切了 击杀者，这时从击杀者回到盒子 就需要detach了
        tbInitParams = CameraGroupDataTable:GetCameraGroupParam(nGroupId)

        self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_FREE_VIEW, true)
        local GCMgr = self.Owner.InnerHelper:GetCameraManager()
        GCMgr:UnInitCameraActorParam()
        local pArm = self.Owner.InnerHelper:GetArm()
        pArm.bDoCollisionTest = true

        GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)
        local tbDeactiveParam = nil

        local TargetLocation = tbParams.pTarget:K2_GetActorLocation()
        local tbTransform =  {
            X = TargetLocation.X,
            Y = TargetLocation.Y,
            Z = TargetLocation.Z,
            Yaw = 0,
        }
        local bIsOcean, _ = GetIsOcean(tbTransform)

        local pFollowType , nBlendTime , nArmLenOffset
        if nGroupId == tbGroupDef.ViewDeadBoxHuman then
            pFollowType = ECameraFollowType.Attach
            nBlendTime = tbParams.nHumanBoxTime
            nArmLenOffset = VIEW_HUMAN_OFFSET
        else
            pFollowType = ECameraFollowType.NotAttachFollowLocationXY
            nBlendTime = tbParams.nShipBoxTime
            nArmLenOffset = VIEW_SHIP_OFFSET
        end

        if bIsOcean then
            nArmLenOffset = VIEW_SHIP_OFFSET
        end

        if tbParams.bDetach then
            tbDeactiveParam = nil
            tbTargetParams = { pFollowTarget = tbParams.pTarget , pFollowType = pFollowType, bSetControlRot = true }
        else
            tbDeactiveParam = { bKeepNoChange = true }
            tbTargetParams = nil
        end

        self.Owner:ActiveCameraLogic(nGroupId, tbDeactiveParam, {
                tbConfigInitParams = tbInitParams,
                tbTargetParams = tbTargetParams,
             })
        --先硬切成盒子
        self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = nil, bImmediatly = true})
        --先过渡 摇臂长度，达到向后拉镜头的效果
        self.Owner:ActiveCameraMode(tbModeDef.ModeArmLen, { nArmLenToGo = nArmLenOffset, nBlendTime = nBlendTime})
        self.tbTimerObject = DelayTimer:DelayRun(function()
            if IsTeamLastDeadOrSingleDead() and not IsAlreadyBattleResultOrWatchBattle() then
                self.EventHelper:FireEvent(ClientEventDef.EV_DEAD_CAMERA_OVER)
            end
        end, nBlendTime)

    elseif nGroupId == tbGroupDef.ViewShipKiller or nGroupId == tbGroupDef.ViewHumanKiller then

        self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_FREE_VIEW, true)
        local GCMgr = self.Owner.InnerHelper:GetCameraManager()
        GCMgr:UnInitCameraActorParam()

        tbInitParams = CameraGroupDataTable:GetCameraGroupParam(nGroupId)

        GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)
        local pFollowType
        if nGroupId == tbGroupDef.ViewHumanKiller then
            pFollowType = ECameraFollowType.Attach
        else
            pFollowType = ECameraFollowType.NotAttachFollowLocationXY
        end
        tbTargetParams = { pFollowTarget = tbParams.pTarget , pFollowType = pFollowType, bSetControlRot = true }
        self.Owner:ActiveCameraLogic(nGroupId, nil, {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = tbTargetParams,
         })
        self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, {
            pTarget = nil, bImmediatly = false, nBlendTime = tbParams.nViewKillerTime,
            nBlendExp = tbParams.nToKillerParam, BlendFunc =  EViewTargetBlendFunction.VTBlend_EaseIn
        })
    end

end

local function OnDeadViewInstantly(self, nGroupId, pTarget)
    --成盒子之后 的镜头需要有不同的处理，如果是人状态直接成盒，摄像机就不用detach 直接原地blend过来
        --如果是死亡之后直接先切了 击杀者，这时从击杀者回到盒子 就需要detach了
    local tbInitParams = CameraGroupDataTable:GetCameraGroupParam(nGroupId)

    local GCMgr = self.Owner.InnerHelper:GetCameraManager()
    GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)

    local pFollowType
    if nGroupId == tbGroupDef.ViewDeadBoxHuman then
        pFollowType = ECameraFollowType.Attach
        tbInitParams.nArmLength = tbInitParams.nArmLength + VIEW_HUMAN_OFFSET
    else
        pFollowType = ECameraFollowType.NotAttachFollowLocationXY
        tbInitParams.nArmLength = tbInitParams.nArmLength + VIEW_SHIP_OFFSET
    end
    local tbTargetParams = { pFollowTarget = pTarget , pFollowType = pFollowType, bSetControlRot = true }
    self.Owner:ActiveCameraLogic(nGroupId, nil, {
                tbConfigInitParams = tbInitParams,
                tbTargetParams = tbTargetParams,
             })
    self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = nil, bImmediatly = true})
end

local function OnDeactiveCameraGroup(self, nGroupId, tbParams)
end

--同步观战船aim
local function WatchBattleChangeShipAim(self, nAimRate, bInAim, bBlend, nShipTemplateId)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    if self.bWatchShipAim == bInAim then
        return
    end

    local pArm = self.Owner.InnerHelper:GetArm()
    local tbInitParams = ShipCameraDataTable:GetShipInitCameraParam(nShipTemplateId)
    
    if bInAim then
        GameCameraManager:InitAimParam(CameraIni.nShipAimArmLen, nAimRate)
        local nTime = 0
        if bBlend then
            nTime = nAimBlendTime
        end
        if tbInitParams.AimArmLoc then 
            pArm:K2_SetRelativeLocation(tbInitParams.AimArmLoc)
        end
        self.Owner:ActiveCameraMode(tbModeDef.ModeFov, { nTargetFovRate = nAimRate, nBlendTime = nTime })
    else
        GameCameraManager:UnInitAimParam()
        if tbInitParams.ArmLocation then 
            pArm:K2_SetRelativeLocation(tbInitParams.ArmLocation)
        end
        self.Owner:ActiveCameraMode(tbModeDef.ModeFov, { nTargetFovRate = 0, nBlendTime = nAimBlendTime })
    end
    self.bWatchShipAim = bInAim
end

local function HideSightForAim(tbCurWeapon, bHide)
    if tbCurWeapon and isvalidhandle(tbCurWeapon.pWeaponActor) and tbCurWeapon.pWeaponActor.SetHideSight then
        local pWeaponActor = tbCurWeapon.pWeaponActor
        pWeaponActor:SetHideSight(bHide)
        local szHoldSocket = tbCurWeapon:GetHoldSocketName()
        local tbOwner = tbCurWeapon:GetOwner()
        if tbOwner and tbOwner.pUEActor and tbOwner.pUEActor.Mesh then 
            pWeaponActor:ChangeSightMeshNew(bHide, szHoldSocket, tbOwner.pUEActor.Mesh)
        end
    end
end

--同步观战人aim
local function WatchBattleChangeHumanAim(self, nAimRate, bInAim, pTarget, CameraOffset, bBlend, bSniperAim)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    self.bWatchAim = bInAim
    local pArm = self.Owner.InnerHelper:GetArm()
    if bInAim then
        --人瞄准切成第一视角 就不能同步 yaw和pitch了 因为是硬绑定的 跟着人动就可以了
        local tbCurrentWeapon = pTarget.HumanWeaponComponent:GetCurrentWeapon()
        if tbCurrentWeapon then
            local pSightTransform = tbCurrentWeapon.pWeaponActor:GetSightTransform()
            -- logdebug("tbCurrentWeapon:GetProperty().nOffsetToAim:", tbCurrentWeapon:GetProperty().nOffsetToAim)
            self.Owner:ActiveCameraMode(tbModeDef.ModeCameraTrack, {
                pTargetMesh = pTarget.pUEActor.Mesh, 
                szTargetSocket = CameraIni.szAimSocket, 
                pRefMesh = tbCurrentWeapon.pWeaponActor.Mesh, 
                pSightRelativeTransform = pSightTransform,
                nTrackSpeed = CameraIni.nTrackSpeed, 
                nDelayBeginTime = CameraIni.nDelayBeginTime, 
                nDelayTraceOnceTime = CameraIni.nDelayTraceOnceTime, 
                nOffsetForward = tbCurrentWeapon:GetProperty().nOffsetToAim
            })
            HideSightForAim(tbCurrentWeapon, true)
           
        end

        pArm.bDoCollisionTest = false
        self.Owner:DeactiveMode(tbModeDef.ModeSyncArmRot)
        GameCameraManager:UnInitCameraActorParam()
        local pUEActor = pTarget.pUEActor
        pUEActor.bBlendAim = true
        GameCameraManager:InitAttachAimParam(nWBCfgHumanNewAimArmLen, CameraOffset,
            nAimRate, HUMAN_AIM_SOCKET, pUEActor.Mesh)

        local nBlendTime = 0
        if bBlend then
            nBlendTime = nAimBlendTime
        end
        self.Owner:ActiveCameraMode(tbModeDef.ModeFov, { nTargetFovRate = nAimRate, nBlendTime = nBlendTime })
    else

        self.Owner:DeactiveMode(tbModeDef.ModeCameraTrack)
        -- if bSniperAim then
            local tbCurrentWeapon = pTarget.HumanWeaponComponent:GetCurrentWeapon()
            HideSightForAim(tbCurrentWeapon, false)
        -- end
        --设置站立时候 人的base offset 方便蹲下 站立的时候镜头移动
        local pUEActor = pTarget.pUEActor
        pUEActor.bBlendAim = false

        local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.WatchBattle)
        GameCameraManager:ResetBaseSocketOffset(tbInitParams.SocketOffset)
        tbInitParams.nPitchViewMax = GameCameraManager.ViewPitchMax
        tbInitParams.nPitchViewMin = GameCameraManager.ViewPitchMin

        local nActorPitch = pUEActor:GetAimPitchValue()
        tbInitParams.ArmRotation = Rotator{ Pitch = nActorPitch, Yaw = 0, Roll = 0 }

        --恢复成当前人的状态对应的的 相机offset
        local nCurrentMovementState = pTarget.HumanMovementStateComponent:GetCurrentState()
        if nCurrentMovementState == HumanMovementStateType.Crouch_State then
            tbInitParams.SocketOffset = HumanCameraDataTable:GetCrouchSocketOffset()
        elseif nCurrentMovementState == HumanMovementStateType.Crawl_State then
            tbInitParams.SocketOffset = HumanCameraDataTable:GetCrawlSocketOffset()
        end
        pArm.bDoCollisionTest = true

        GameCameraManager:UnInitAttachAimParam()
        self.Owner:InitCameraActor( {},  {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = {
                pFollowTarget = pUEActor,
                pFollowType = ECameraFollowType.AttachToSocket,
                bSetControlRot = false,
                FollowSocket = "",
                FollowParentComponent = pUEActor.Mesh
            }
        })
        self.Owner:ActiveCameraMode(tbModeDef.ModeSyncArmRot, { bSyncYaw = false, pPawn = pUEActor, nOffsetYaw = 0, nInterpSpeed = SYNC_ROT_SPEED })

        self.Owner:ActiveCameraMode(tbModeDef.ModeFov, { nTargetFovRate = 0, nBlendTime = nAimBlendTime })
    end
end

local function WatchBattleChangeVehicleState(self, pTarget, bGetIn)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    local pArm = self.Owner.InnerHelper:GetArm()
    if bGetIn then
        GameCameraManager:UnInitCameraActorParam()
        pArm.FixOffset = -70
        local tbInitParams = VehicleCameraDataTable:GetVehicleInitCameraParam( DEFAULT_VEHICLE_CAMERA * 10 )
        self.Owner:InitCameraActor( {},  {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = {
                pFollowTarget = pTarget,
                pFollowType = ECameraFollowType.NotAttachFollowMeshLocation,
                bSetControlRot = false,
                FollowSocket = "",
                FollowParentComponent = pTarget.Mesh
            }
        })
        local nOffsetYaw = -pTarget:K2_GetActorRotation().Yaw
        self.Owner:ActiveCameraMode(tbModeDef.ModeSyncArmRot, { bSyncYaw = true, pPawn = pTarget, nOffsetYaw = nOffsetYaw, nInterpSpeed = SYNC_ROT_SPEED })
    else
        pArm.FixOffset = -14
        self.Owner:DeactiveMode(tbModeDef.ModeArmLen)
        GameCameraManager:UnInitCameraActorParam()
        local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.WatchBattle)
        GameCameraManager:ResetBaseSocketOffset(tbInitParams.SocketOffset)

        self.Owner:InitCameraActor( {},  {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = {
                pFollowTarget = pTarget,
                pFollowType = ECameraFollowType.AttachToSocket,
                bSetControlRot = true,
                FollowSocket = "",
                FollowParentComponent = pTarget.Mesh
            }
        })
        self.Owner:ActiveCameraMode(tbModeDef.ModeSyncArmRot, { bSyncYaw = false, pPawn = pTarget, nOffsetYaw = 0, nInterpSpeed = SYNC_ROT_SPEED })
    end

    self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pTarget, bImmediatly = true })
end

local function WatchBattleChangeSwimState(self, bSwim, bBlend)
    local pArm = self.Owner.InnerHelper:GetArm()
    local tbInitParams = nil
    if bSwim then
        tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.WatchSwim)
        pArm:K2_SetRelativeLocation(tbInitParams.ArmLocation)
    else
        tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.WatchBattle)
        pArm:K2_SetRelativeLocation(tbInitParams.ArmLocation)
    end

    if bBlend then
        self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = nil, bImmediatly = false, nBlendTime = 0.3 })
    end
end

local function OnWatchBattleCameraChanged(self, nWatchState, tbParam)
    if nWatchState == tbWatchBattleDef.ChangeAim then
        if tbParam.bIsShip then
            WatchBattleChangeShipAim(self, tbParam.nAimRate, tbParam.bInAim, tbParam.bBlend, tbParam.nShipTemplateId )
        else
            WatchBattleChangeHumanAim(self, tbParam.nAimRate, tbParam.bInAim, tbParam.pTarget, tbParam.CameraOffset, tbParam.bBlend, tbParam.bSniperAim)
        end
    elseif nWatchState == tbWatchBattleDef.ChangeMovement then
        self.EventHelper:FireEvent(ClientEventDef.EV_MOVEMENT_CAMERE_OFFSET, tbParam.Offset, tbParam.nBlendTime, tbParam.bNeedBlend, tbParam.nStatePitchMax, tbParam.nStatePitchMin)
    elseif nWatchState == tbWatchBattleDef.ChangeVehicle then
        WatchBattleChangeVehicleState(self, tbParam.pTarget, tbParam.bGetIn)
    elseif nWatchState == tbWatchBattleDef.ChangeSwimState then
        WatchBattleChangeSwimState(self, tbParam.bSwim, tbParam.bNeedBlend)
    end
end

local function OnSetBotTargetCamera(self, bHuman, tbGameObject)
    local GCMgr = self.Owner.InnerHelper:GetCameraManager()
    local pTarget = tbGameObject.pUEActor
    GCMgr:SetWatchTarget(pTarget)
    if bHuman then
        local nVehicleId = tbGameObject.HumanMovementStateComponent:GetVehicleInstanceId()
        -- logdebug("vehicle id is ::", nVehicleId)
        if nVehicleId > 0 then 
            local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleId)
            local pRealTarget =  tbVehicle.pUEActor or pTarget
            local tbInitParams = VehicleCameraDataTable:GetVehicleInitCameraParam( DEFAULT_VEHICLE_CAMERA * 10 )
            self.Owner:ActiveCameraLogic(tbGroupDef.BotHuman, nil, {
                tbConfigInitParams = tbInitParams,
                tbTargetParams = {
                    pFollowTarget = pRealTarget,
                    pFollowType = ECameraFollowType.NotAttachFollowMeshLocation,
                    bSetControlRot = false,
                    FollowSocket = "",
                    FollowParentComponent = pRealTarget.Mesh
                }
            })
        else  
            self.Owner:ActiveCameraLogic(tbGroupDef.BotHuman, nil, {
                tbConfigInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.WatchBattle),
                tbTargetParams = {
                    pFollowTarget = pTarget,
                    pFollowType = ECameraFollowType.AttachToSocket,
                    bSetControlRot = false,
                    FollowSocket = "",
                    FollowParentComponent = pTarget.Mesh
                }
            })
        end
        
        GCMgr:ResetBaseSocketOffset(Vector{X = 0, Y = 30, Z = 0})
        self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pTarget, bImmediatly = true })
        self.Owner:ActiveCameraMode(tbModeDef.ModeSyncArmRot, { bSyncYaw = false, pPawn = pTarget, nOffsetYaw = 0, nInterpSpeed = SYNC_ROT_SPEED })
    else
        GCMgr.LockMoveInput = true
        local RotYaw = pTarget:K2_GetActorRotation().Yaw
        self.Owner:ActiveCameraMode(tbModeDef.ModeSyncArmRot, { bSyncYaw = true, pPawn = pTarget, nOffsetYaw = -RotYaw, nInterpSpeed = SYNC_ROT_SPEED })
        self.Owner:ActiveCameraLogic(tbGroupDef.BotShip, nil, {
            tbConfigInitParams = nil,
            tbTargetParams = {
                pFollowTarget = pTarget,
                pFollowType = ECameraFollowType.NotAttachFollowLocationXY,
                bSetControlRot = false
            }
        })
        self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pTarget, bImmediatly = false, nBlendTime = 0.5 })
    end
end

local function OnSetBotTargetCameraBack(self, bHuman, pTarget)
    local tbPlayer = PlayerSelfHelper:Get()
    local tbInitParams = nil
    self.Owner:DeactiveMode(tbModeDef.ModeSyncArmRot)
    local GCMgr = self.Owner.InnerHelper:GetCameraManager()
    GCMgr.LockMoveInput = false
    GCMgr:SetWatchTarget(pTarget)
    if bHuman then
        tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.Normal)
        GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)

        self.Owner:ActiveCameraLogic(tbGroupDef.HumanNormal, nil, {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = {
                pFollowTarget = pTarget,
                pFollowType = ECameraFollowType.Attach,
                bSetControlRot = true
            }
        })
    else
        tbInitParams = ShipCameraDataTable:GetShipInitCameraParam(tbPlayer:GetShipTemplateId())
        self.Owner:ActiveCameraLogic(tbGroupDef.ShipNormal, nil, {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = {
                pFollowTarget = pTarget,
                pFollowType = ECameraFollowType.NotAttachFollowLocationXY,
                bSetControlRot = true
            }
        })
    end
    self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pTarget, bImmediatly = true })
end

local function DetachCameraForWatch(self, bResetCameraRot)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    local CameraActor = GameCameraManager:GetPlayerCameraActor()
    self.Owner:DeactiveMode(tbModeDef.ModeSyncArmRot)
    CameraActor:K2_DetachFromActor(EDetachmentRule.KeepWorld, EDetachmentRule.KeepWorld, EDetachmentRule.KeepWorld)
    if bResetCameraRot then
        local CameraActorLoc = CameraActor:K2_GetActorLocation()
        local tbTransform =  {
            X = CameraActorLoc.X,
            Y = CameraActorLoc.Y,
            Z = CameraActorLoc.Z,
            Yaw = 0,
        }

        local bIsOcean, _ = GetIsOcean(tbTransform)
        local nArmLenOffset = VIEW_HUMAN_OFFSET
        if bIsOcean then
            nArmLenOffset = VIEW_DETACH_SHIP
        end

        local pArm = self.Owner.InnerHelper:GetArm()
        pArm.TargetArmLength = nArmLenOffset
        pArm:K2_SetRelativeRotation(Rotator{Pitch = -75, Yaw = 0, Roll = 0})
    end
end

function CLWatchBattle:OnCreate()
end

function CLWatchBattle:OnDestroy()
    if self.tbTimerObject then
        DelayTimer:ClearTimer(self.tbTimerObject)
        self.tbTimerObject = nil
    end
end

function CLWatchBattle:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, self, OnActiveCameraGroup)
    EventHelper:RegisterEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, self, OnDeactiveCameraGroup)
    EventHelper:RegisterEvent(ClientEventDef.EV_TO_DEAD_VIEW_INSTANT, self, OnDeadViewInstantly)

    EventHelper:RegisterEvent(ClientEventDef.EV_SET_CAMERA_FORBOT, self, OnSetBotTargetCamera)
    EventHelper:RegisterEvent(ClientEventDef.EV_SET_BOT_CAMERA_BACK, self, OnSetBotTargetCameraBack)
    EventHelper:RegisterEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, self, OnWatchBattleCameraChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_OVER_CAMERA_DETACH, self, DetachCameraForWatch)
end

function CLWatchBattle:OnUnbindEvent(EventHelper)
end

return CLWatchBattle