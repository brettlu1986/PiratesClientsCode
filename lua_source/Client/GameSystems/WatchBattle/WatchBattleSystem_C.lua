local luaclass = require("luaclass")
local WatchBattleSystem = require("WatchBattleSystem")
local WatchBattleSystem_C = luaclass("WatchBattleSystem_C", WatchBattleSystem)

local PropName                      = require("PropName")
local DelayTimer                    = require("DelayTimer")
local UIManager                     = require("UIManager")
local UIDef                         = require("UIDef")
local CameraGameHelper              = require("CameraGameHelper")
local DamageTypeEx                  = require("DamageTypeEx")
local ClientEventDef                = require("ClientEventDef")
local CommonEventDef                = require("CommonEventDef")
local Proto                         = require("DungeonCommonProtoNames")
local HumanWeaponDef                = require("HumanWeaponDef")
local GameObjectSystem              = require("GameObjectSystem_C")
local PlayerSelfHelper              = require("GamePlayerSelfHelper")
local NetworkManager                = dynamic_require("NetworkManager")
local GameCameraModeGroupDef        = require("GameCameraModeGroupDef")
local HumanWeaponItemPropertyHelper = require("HumanWeaponItemPropertyHelper")
local GameCameraSystem              = require("GameCameraSystem")
local GlobalVariableSystem          = require("GlobalVariableSystem_C")
local HumanMovementStateType        = require("HumanMovementStateType")
local UIStateDef                    = require("UIStateDef")
local BattleItemDataTable           = require("BattleItemDataTable")
local BattleItemCategoryDef         = require("BattleItemCategoryDef")
local BattleResultIni               = require("BattleResultIni")
local ResourceCacheSystem           = require("ResourceCacheSystem")
local TeamWatchClientHelper         = require("TeamWatchClientHelper")
local WatchBattleDef                = require("WatchBattleDef")
local HumanCameraDataTable          = require("HumanCameraDataTable")
local DeadCameraDataTable           = require("DeadCameraDataTable")
local HumanVehicleStateDef          = require("HumanVehicleStateDef")
local HumanWeaponCameraTimeDataTable = require("HumanWeaponCameraTimeDataTable")

local EStopType = Proto.c2d_StopWatchTeammateBattle_EStopType

WatchBattleSystem_C.tbTimerObject = nil
WatchBattleSystem_C.tbDeadCameraParam = nil
WatchBattleSystem_C.nCurrentWatchOffsetYaw = 0
WatchBattleSystem_C.tbWatchMateInfo = nil --切换到队友时候 队友的一些相关信息
WatchBattleSystem_C.bWaitForCreate = false
WatchBattleSystem_C.nCurrentVehicleId = -1
WatchBattleSystem_C.bNeedWaitVehicle = false

WatchBattleSystem_C.bReLoginShowWatchWnd = false
WatchBattleSystem_C.bReLoginTeamDead     = false

WatchBattleSystem_C.tbOtherInstanceId = -1
WatchBattleSystem_C.tbTeamDeadReason = nil
WatchBattleSystem_C.bInitOriginalTeam = false

WatchBattleSystem_C.nWatchTeamId = -1
WatchBattleSystem_C.bWatchForTeamInfo = false
WatchBattleSystem_C.bBattleGameEnd = false
WatchBattleSystem_C.bSelfExitWatch = false
WatchBattleSystem_C.nWatchState = nil

WatchBattleSystem_C.tbLastWatchTarget = nil
WatchBattleSystem_C.tbCurrentWatchTarget = nil

local DEAD_CAMERA = 1
local CLOSEWNDS = {
    UIDef.UI_WORLD_MAP,
    UIDef.UI_SETTING,
    UIDef.UI_PICKUP_ITEM,
    UIDef.UI_BUILD_ITEM,
    UIDef.UI_FFABACKPACK,
    UIDef.UI_PICKUP_BOX,
}

local function LOG(...)
    log("[ClientWatch]:", ...)
end

local function SetWatchState(self, nState)
    self.nWatchState = nState
end

local function IsValidStartWatchState(self)
    return self.nWatchState == WatchBattleDef.NONE or
        self.nWatchState == WatchBattleDef.SUCCESS or
        self.nWatchState == WatchBattleDef.FAIL
end

local function IsDeadByOtherKiller(self, nDeadInstanceId, nCauserInstanceId, nLastDamageType)
    local bSuicide = nCauserInstanceId > 0 and nDeadInstanceId == nCauserInstanceId
    local bNotKillByOther = bSuicide or nLastDamageType == DamageTypeEx.POISON_CIRCLE or nLastDamageType == DamageTypeEx.FALLING or
        nLastDamageType == DamageTypeEx.KILL_SELF or nLastDamageType == DamageTypeEx.DROWN
    return not bNotKillByOther
end

--当前 是否是多人模式
local function IsTeamBattle()
    return TeamWatchClientHelper.GetTeamCount() ~= 1
end

--判断当前副本是否结束：吃鸡，或者其他原因
function WatchBattleSystem_C:IsBattleEnd()
    return self.bBattleGameEnd
end

------------------------------------------------------------------------------------------------------------
--击杀视角相关处理
local function OnChangePlayerDeadBoxView(self, tbDeader, bDetach, nShipBoxTime, nHumanBoxTime)
    local bIsShip = tbDeader:IsShip()
    local nGroupId = GameCameraModeGroupDef.ViewDeadBoxHuman
    if bIsShip then
        nGroupId = GameCameraModeGroupDef.ViewDeadBoxShip
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, nGroupId, {
        pTarget = tbDeader.pUEActor, bDetach = bDetach,
        nShipBoxTime = nShipBoxTime, nHumanBoxTime = nHumanBoxTime
    })
end

--击杀者前置 视角
local function OnChangeKillerFrontView(self, tbCauser, nLastDamageType, nViewKillerTime, nToKillerParam)
    if not tbCauser then
        return
    end
    local nGroupId = GameCameraModeGroupDef.ViewHumanKiller
    if tbCauser:IsShip() then
        nGroupId = GameCameraModeGroupDef.ViewShipKiller
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, nGroupId,
    {
        pTarget = tbCauser.pUEActor, nViewKillerTime = nViewKillerTime, nToKillerParam = nToKillerParam
    })
end

local function ToDeadViewImmediately(self, tbDeader)

    local bIsShip = tbDeader:IsShip()
    local nGroupId = GameCameraModeGroupDef.ViewDeadBoxHuman
    if bIsShip then
        nGroupId = GameCameraModeGroupDef.ViewDeadBoxShip
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_TO_DEAD_VIEW_INSTANT, nGroupId, tbDeader.pUEActor )
end

local function ToDeadView(self, tbDeader, bDetach)
    local tbParam = self.tbDeadCameraParam
    OnChangePlayerDeadBoxView(self, tbDeader, bDetach, tbParam.nViewShipBoxTime, tbParam.nViewHumanBoxTime)
end

local function ToKillerView(self, tbDeader, tbCauser, nLastDamageType)
    local tbParam = self.tbDeadCameraParam
    OnChangeKillerFrontView(self, tbCauser, nLastDamageType, tbParam.nDeadToKillerTime, tbParam.nToKillerParam)
    self.tbTimerObject = DelayTimer:DelayRun(function()
        -- ToDeadViewImmediately(self, tbDeader)
       OnChangePlayerDeadBoxView(self, tbDeader, true, tbParam.nKillerToDeadTime, tbParam.nKillerToDeadTime)
    end, tbParam.nDeadToKillerTime + tbParam.nViewKillerTime) --显示killer2秒
end

-------------------------------------------------------------------------------------------------------
--观战切换逻辑状态处理

local function StopWatchTeammateBattle(self)
    --TODO 跳转结算界面  切回死亡对象盒视角
end

local function CheckWatchMateValid(self)
    local nCurrentWatchId = TeamWatchClientHelper.GetCurrentWatchId()
    if nCurrentWatchId == -1 then
        log("[WatchMate] viewer change aim state, but client watch id is not valid")
        return false
    end

    local tbWatchObj = GameObjectSystem:FindByInstanceId(nCurrentWatchId)
    if not tbWatchObj then
        log("[WatchMate] current watch id not -1, but client find watch object is nil")
        return false
    end
    return true
end

local function CheckWatchMateStateValid(self, bIsShip)
    local bValid = CheckWatchMateValid(self)
    if not bValid then
        return false
    end
    local tbWatchObj = TeamWatchClientHelper.GetCurrentWatchPlayer()
    if tbWatchObj and tbWatchObj:IsShip() ~= bIsShip then
        log("[WatchMate] the watch object state should be same as client")
        bValid = false
    end

    if tbWatchObj.pUEActor == nil then
        log("[WatchMate] the watch object ueactor state should be exist")
        bValid = false
    end
    return bValid
end

local function CheckWatchHumanWeaponValid(self, WeaponComponent)
    if not WeaponComponent then
        log("[WatchMate] viewer not human or human weapon component nil")
        return false
    end

    local nTemplateId = WeaponComponent:GetCurrentWeaponTemplateId()
    if nTemplateId == 0 then
        return false
    end

    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if tbTemplate.nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM then
        return false
    end

    local tbProperty = HumanWeaponItemPropertyHelper.CreateProperty(nTemplateId)
    if not tbProperty then
        log("[WatchMate] viewer weapon property not valid", nTemplateId)
        return false
    end

    if tbProperty.nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
        log("[WatchMate] viewer weapon category should not be melee")
        return false
    end

    return true
end

local function ChangeViewerAimState(self, bIsShip, bInAim, bBlend)
    if CheckWatchMateStateValid(self, bIsShip) then

        local tbWatchObj = TeamWatchClientHelper.GetCurrentWatchPlayer()
        local nAimRate = 0
        local CameraOffset = Vector{X = 0, Y = 0, Z = 0}
        local bWillChangeAim = true
        local bSniperAim = false
        local nShipTemplateId = 0
        if bIsShip then
            tbWatchObj.pUEActor:SetActorHiddenInGame(bInAim)
            local nTelescopeScale = tbWatchObj.ShipBattlePropertyComponent:GetProp(PropName.nTelescopeScale)
            nAimRate = bInAim and nTelescopeScale or 0
            nShipTemplateId = tbWatchObj:GetShipTemplateId()
        else
            local WeaponComponent = tbWatchObj.HumanWeaponComponent
            local bValid = CheckWatchHumanWeaponValid(self, WeaponComponent)
            if bValid then

                local nTemplateId = WeaponComponent:GetCurrentWeaponTemplateId()
                log("[WatchMate] viewer weapon change aim ", nTemplateId, bInAim)
                local tbProperty = HumanWeaponItemPropertyHelper.CreateProperty(nTemplateId)
                nAimRate = tbProperty.nOpenAimCameraRate

                local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
                bSniperAim = tbTemplate.bUseSniperUi
                WeaponComponent:ChangeUEActorStateForAim(bInAim, true)
            else
                bWillChangeAim = false
                log("[WatchMate] viewer weapon change aim fail")
            end
        end

        if bWillChangeAim then
            --处理相机相关
            self.EventHelper:FireEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, GameCameraModeGroupDef.WatchBattleDef.ChangeAim, {
                bIsShip = bIsShip, bInAim = bInAim, nAimRate = nAimRate,
                pTarget = tbWatchObj, CameraOffset = CameraOffset, bBlend = bBlend, bSniperAim = bSniperAim, nShipTemplateId = nShipTemplateId
            })
        end
    end
end

local function ChangeViewerMovementStateCamera(self, nLastMoveState, nCurrentState, bNeedBlend)
    -- logdebug("nLastMovementState , currentState ", nLastMoveState, nCurrentState)
    if CheckWatchMateValid(self) then
        local tbWatchObj = TeamWatchClientHelper.GetCurrentWatchPlayer()

        self.EventHelper:FireEvent(ClientEventDef.EV_WATCH_BATTLE_MOVEMENT_STATE_CHANGE, nCurrentState)
        if CameraGameHelper.IsNeedMovementBlend(nLastMoveState, nCurrentState) then
            local WeaponComponent = tbWatchObj.HumanWeaponComponent
            if WeaponComponent then
                local nWeaponID = WeaponComponent:GetCurrentWeaponTemplateId()
                nWeaponID = nWeaponID and nWeaponID or 0
                local nBlendTime = HumanWeaponCameraTimeDataTable:GetMovementCameraTime(nWeaponID, nLastMoveState, nCurrentState)
                local Offset = HumanCameraDataTable:GetMovementCameraOffset(nCurrentState)
                local nStatePitchMax, nStatePitchMin = HumanCameraDataTable:GetMovementCameraPitchLimit(nCurrentState)
                self.EventHelper:FireEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, GameCameraModeGroupDef.WatchBattleDef.ChangeMovement, {
                    Offset = Offset, nBlendTime = nBlendTime, bNeedBlend = bNeedBlend, nStatePitchMax = nStatePitchMax, nStatePitchMin = nStatePitchMin
                })
                --self.EventHelper:FireEvent(ClientEventDef.EV_MOVEMENT_CAMERE_OFFSET, Offset, nBlendTime, true, nStatePitchMax, nStatePitchMin)
            end
        -- end


        -- if nCurrentState == HumanMovementStateType.Crawl_State then
        --     logdebug("watch mate change to crawl state")
        --     self.EventHelper:FireEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, GameCameraModeGroupDef.WatchBattleDef.ChangeCrawlState, { pTarget = tbWatchObj.pUEActor, bToCrawl = true})
        -- elseif nLastMoveState == HumanMovementStateType.Crawl_State then
        --     self.EventHelper:FireEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, GameCameraModeGroupDef.WatchBattleDef.ChangeCrawlState, { pTarget = tbWatchObj.pUEActor, bToCrawl = false})
        --     logdebug("watch mate back from crawl state")
        elseif nLastMoveState == HumanMovementStateType.UpRight_State and nCurrentState == HumanMovementStateType.Swimming then
            self.EventHelper:FireEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, GameCameraModeGroupDef.WatchBattleDef.ChangeSwimState, { bSwim = true, bNeedBlend = bNeedBlend})
        elseif nLastMoveState == HumanMovementStateType.Swimming and nCurrentState == HumanMovementStateType.UpRight_State then
            self.EventHelper:FireEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, GameCameraModeGroupDef.WatchBattleDef.ChangeSwimState, { bSwim = false, bNeedBlend = bNeedBlend})
        end
    end
end

local function OnWatchMateOnVehicle(self, nVehicleId, bGetIn)
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleId)
    if tbVehicle and tbVehicle.pUEActor then
        local tbWatchObj = TeamWatchClientHelper.GetCurrentWatchPlayer()
        local pRealTarget = bGetIn and tbVehicle.pUEActor or tbWatchObj.pUEActor
        if pRealTarget then
            local pArm = CameraGameHelper.GetArm()
            pArm:AddArmCollisionIgnoreActor(pRealTarget)
            self.EventHelper:FireEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, GameCameraModeGroupDef.WatchBattleDef.ChangeVehicle, {
                    pTarget = pRealTarget, bGetIn = bGetIn
            })
        end
    else  
        LOG("OnWatchMateOnVehicle : try to get in vehicle but object not exist:", nVehicleId, bGetIn)
    end
end

local function ToWatchMateCorrectViewState(self, tbTeamMateObj)
    local HumanMovementComponent = tbTeamMateObj.HumanMovementStateComponent
    local WeaponComponent = tbTeamMateObj.HumanWeaponComponent
    local nMovementState = HumanMovementComponent:GetCurrentState()
    LOG(" ToWatchMateCorrectViewState: movementstate is:", nMovementState)
    if nMovementState == HumanMovementStateType.Crouch_State
        or nMovementState == HumanMovementStateType.Crawl_State
            or nMovementState == HumanMovementStateType.Dying_State
             or nMovementState == HumanMovementStateType.Swimming then
        ChangeViewerMovementStateCamera(self, HumanMovementStateType.UpRight_State, nMovementState, false)
    else
        LOG(" ToWatchMateCorrectViewState, check vehicle :", HumanMovementComponent:IsInVehicle(), nMovementState, self.nCurrentVehicleId)
        if HumanMovementComponent:IsInVehicle()  then
            local nVehicleId = self.nCurrentVehicleId--HumanMovementComponent.nVehicleInstanceId
            OnWatchMateOnVehicle(self, nVehicleId, true)
            return
        end
    end

    ChangeViewerAimState(self, false, WeaponComponent:IsAiming(), false)
end

local function RequestWatchTarget(self, nWatchId)
    if not IsValidStartWatchState(self) or self.bBattleGameEnd or self:IsSelfExitWatch()then
        LOG("RequestWatchTarget----------> not valid watch state or battle end:", self.bBattleGameEnd, self:IsSelfExitWatch())
        return
    end
    SetWatchState(self, WatchBattleDef.START)

    GlobalVariableSystem.bCancelMerge = true
    local bOtherTeamWatch = TeamWatchClientHelper.IsOtherTeamWatch()

    --这里存在一个人船切换的问题，当前的和 pre的都是同一个 那就是人船切换或者船船切换，此时不Reset
    local nCurrentWatchId = TeamWatchClientHelper.GetCurrentWatchId()

    local bValidOtherTeam = bOtherTeamWatch and nWatchId ~= nCurrentWatchId
    local bValidOtherRelogin = bOtherTeamWatch and nWatchId == -1 and nCurrentWatchId == -1
    LOG("RequestWatchTarget------------>begin watch other :", bValidOtherTeam, nWatchId, nCurrentWatchId)
    if bValidOtherTeam or bValidOtherRelogin then
        TeamWatchClientHelper.ResetClientWatchTeamRepInfo()
        LOG("RequestWatchTarget--->begin watch other : reset team now")
    end
    local tbPacket = {
        pre_watch_mate = nCurrentWatchId,
        new_watch_mate = nWatchId,
        is_other_team = bOtherTeamWatch,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_WatchTeammateBattle, tbPacket)
end

local function RequestWatchOther(self)
    LOG(" --> Find killer, request to watch other ", self.tbOtherInstanceId)
    RequestWatchTarget(self, self.tbOtherInstanceId)
end

local function CheckCurrentWatchDead(self, tbNewTeammate)
    if tbNewTeammate and tbNewTeammate:IsDead() then
        LOG("WatchTeammateBattle CheckCurrentWatchDead but new watch target is dead, ", tbNewTeammate.nServerInstanceId)
        self.tbOtherInstanceId = -1
        RequestWatchOther(self)
    end
end

local function ReinitShipSound(self, tbTeamMateObj)
    self.tbLastWatchTarget = self.tbCurrentWatchTarget
    self.tbCurrentWatchTarget = tbTeamMateObj

    if self.tbLastWatchTarget and self.tbLastWatchTarget:IsShip() and self.tbLastWatchTarget.BattleShipMovementComponent then
        self.tbLastWatchTarget.BattleShipMovementComponent:UninitSoundLogic()
    end
    if self.tbCurrentWatchTarget and self.tbCurrentWatchTarget:IsShip() and self.tbCurrentWatchTarget.BattleShipMovementComponent then
        self.tbCurrentWatchTarget.BattleShipMovementComponent:InitSoundLogic()
    end
end

local function OnWatchMateActorDestroy(self, tbGameObject)
    if self.tbCurrentWatchTarget and self.tbCurrentWatchTarget.nServerInstanceId == tbGameObject.nServerInstanceId and
        self.tbCurrentWatchTarget:IsShip() then
        if self.tbCurrentWatchTarget.BattleShipMovementComponent then
            self.tbCurrentWatchTarget.BattleShipMovementComponent:UninitSoundLogic()
        end
    end
end

local function OnVehicleStateChange(self, tbPlayer, nState, nVehicleId)
    if self.tbCurrentWatchTarget and tbPlayer:GetServerInstanceId() == self.tbCurrentWatchTarget:GetServerInstanceId() then  
        local HumanMovementComponent = self.tbCurrentWatchTarget.HumanMovementStateComponent
        local bInVehicle = HumanMovementComponent:IsInVehicle()
        LOG("OnVehicleStateChange: ", bInVehicle, nState)
        if not bInVehicle and (nState == HumanVehicleStateDef.PreAttachToVehicle or nState == HumanVehicleStateDef.AttachToVehicle) then 
            OnWatchMateOnVehicle(self, nVehicleId, true)
        end
    end
end

local function WatchTeammateBattle(self, tbTeamMateObj, nOffsetYaw)
    local nGroupId = GameCameraModeGroupDef.ViewTeammateHuman
    SetWatchState(self, WatchBattleDef.SUCCESS)
    local bShip = false
    if tbTeamMateObj:IsShip() then
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "xsj.usepawnlocforwc 1", nil)
        nGroupId = GameCameraModeGroupDef.ViewTeammateShip
        bShip = true
    else
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "xsj.usepawnlocforwc 0", nil)
    end

    --进入观战需要把 死的这个人的Movement给打开，不然相机的位置不更新了，会导致观战跑着跑着就看不到要观战人了，因为Movement的tick里设置了相机的刷新
    --见 c++ MarkForClientCameraUpdate
    local PlayerSelf = PlayerSelfHelper:Get()
    local pUEActor = PlayerSelf.pUEActor
    if pUEActor then
        if PlayerSelf:IsHuman() then
            LOG("WatchTeammateBattle : open human movement tick ")
            pUEActor.CharacterMovement:SetComponentTickEnabled(true)
        else
            LOG("WatchTeammateBattle : open ship movement tick ")
            pUEActor.ShipMovementComponent:SetComponentTickEnabled(true)
            pUEActor.ShipMovementComponent:SetMoveEnable(false)
        end
    end

    -- if tbTeamMateObj:IsHuman() then
        -- if not self.bWaitForCreate then
        -- --    tbTeamMateObj.pUEActor.HumanAvatarComponent:SetMergeSkeletalMeshWithRefresh(false)
        -- end
    -- end

    ExtendBlueprintFunctions.LoadLevelsImmediatelyByLocation(GWorld, tbTeamMateObj.pUEActor:K2_GetActorLocation())

    self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, nGroupId, {
        nWatchInsId = tbTeamMateObj.nServerInstanceId, 
        nOffsetYaw = nOffsetYaw,
    })

    LOG("WatchTeammateBattle :", tbTeamMateObj:IsShip(), tbTeamMateObj.nServerInstanceId, nGroupId)

    ReinitShipSound(self, tbTeamMateObj)
    self.EventHelper:FireEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, tbTeamMateObj)
    self.EventHelper:FireEvent(ClientEventDef.EV_SET_WATCH_BOT_SOUND_TARGET, true, tbTeamMateObj)

    -- AOceanSystem::SetCustomActor
    local tbOceanSystems = GameplayStatics.GetAllActorsOfClass(GWorld, OceanSystem)
    local pOceanSystem = tbOceanSystems[1]
    if pOceanSystem then
        pOceanSystem:SetCustomActor(tbTeamMateObj.pUEActor)
    end

    if ResourceCacheSystem.pBPChangeState ~= nil then
        if bShip then
            ResourceCacheSystem.pBPChangeState.SetPlayerStateShip(GWorld)
        else
            ResourceCacheSystem.pBPChangeState.SetPlayerStateHuman(GWorld)
        end
    end

    local CameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    CameraManager:CheckOverlapFogTrigger(tbTeamMateObj.pUEActor)

    if tbTeamMateObj:IsHuman() then
        ToWatchMateCorrectViewState(self, tbTeamMateObj)
    else
        if self.tbWatchMateInfo and self.tbWatchMateInfo.is_ship_aim then
            ChangeViewerAimState(self, true, true, false)
        end
    end

    CheckCurrentWatchDead(self, tbTeamMateObj)
end

local function OnWatchMateActorCreate(self, tbGameObject)
    local nInsId = tbGameObject:GetServerInstanceId()
    if self.bWaitForCreate then
        local nCurrentWatchId = TeamWatchClientHelper.GetCurrentWatchId()
        if self.bNeedWaitVehicle then
            if nInsId == nCurrentWatchId or nInsId == self.nCurrentVehicleId then
                local tbWatchObj = TeamWatchClientHelper.GetCurrentWatchPlayer()
                local tbWatchVehicle = GameObjectSystem:FindByInstanceId(self.nCurrentVehicleId)
                local bHasObjActor = tbWatchObj and tbWatchObj.pUEActor ~= nil
                local bHasVehicleActor = tbWatchVehicle and tbWatchVehicle.pUEActor ~= nil

                if bHasObjActor and bHasVehicleActor then
                    LOG("WatchActorCreate 1: :", bHasObjActor, bHasVehicleActor)
                    WatchTeammateBattle(self, tbWatchObj, self.nCurrentWatchOffsetYaw)
                    self.bWaitForCreate = false
                    self.bNeedWaitVehicle = false
                end
            end
        else
            if nInsId == nCurrentWatchId then
                LOG("WatchActorCreate 2: :", nCurrentWatchId)
                WatchTeammateBattle(self, tbGameObject, self.nCurrentWatchOffsetYaw)
                self.bWaitForCreate = false
            end
        end
    end
end

local function TryWatchTeammate(self)
    local tbTeamMateObj = TeamWatchClientHelper.GetCurrentWatchPlayer()
    local nCurrentWatchId = TeamWatchClientHelper.GetCurrentWatchId()
    LOG("TryWatchTeammate try watch teammate :", nCurrentWatchId)
    if tbTeamMateObj == nil  then
        LOG("TryWatchTeammate try watch teammate but nil")
    end
    if tbTeamMateObj then
        local pUEActor = tbTeamMateObj.pUEActor
        if pUEActor then
            LOG("TryWatchTeammate has mate ueactor")
            WatchTeammateBattle(self, tbTeamMateObj, self.nCurrentWatchOffsetYaw)
        else
            LOG("TryWatchTeammate wait for create ueactor")
            self.bWaitForCreate = true
            if self.nCurrentVehicleId ~= -1 then
                self.bNeedWaitVehicle = true
            end
        end
    else
        self.bWaitForCreate = true
    end
end

local function CheckOtherTeamInfoChanged(self)
    local nCurrentOtherTeamId = TeamWatchClientHelper.GetOtherWatchTeamId()
    if self.bWatchForTeamInfo and nCurrentOtherTeamId ~= -1 and self.nWatchTeamId == nCurrentOtherTeamId then
        LOG("TeamInfoChanged try watch other team 2:", self.nWatchTeamId)
        TryWatchTeammate(self)
        self.bWatchForTeamInfo = false
    end
end

local function TeamInfoChanged(self, tbBattleTeamInfo)
    CheckOtherTeamInfoChanged(self)
end

local function OnTeamModeInfo(self, tbPacket)
    local nTeamModeId = tbPacket.nTeamModeId
    TeamWatchClientHelper.SetTeamCount(nTeamModeId)
end

local function TryWatchTeammateBattle(self, nWatchInsId, nVehicleId, nOffsetYaw, tbInfo, nWatchTeamId, bSuccess)
    if self.bBattleGameEnd then
        LOG("can not set watch , because battle end")
        return
    end

    local bOtherTeamWatch = TeamWatchClientHelper.IsOtherTeamWatch()
    SetWatchState(self, WatchBattleDef.INPROGRESS)
    if bSuccess then
        self.bSelfExitWatch = false
        TeamWatchClientHelper.SetCurrentWatchId(nWatchInsId)
        self.nCurrentVehicleId = nVehicleId
        self.nCurrentWatchOffsetYaw = nOffsetYaw
        self.tbWatchMateInfo = tbInfo

        if bOtherTeamWatch then
            if self.nWatchTeamId == -1 then
                self.nWatchTeamId = TeamWatchClientHelper.GetOriginalTeamId()
            end
            if self.nWatchTeamId ~= nWatchTeamId then
                LOG("TryWatchTeammateBattle try watch other team 1 ::",self.nWatchTeamId, nWatchTeamId, nWatchInsId)
                self.bWatchForTeamInfo = true
                self.nWatchTeamId = nWatchTeamId
                --WatchBattleComponent的Team可能先于 d2c_WatchBattle下来，所以先检查一下，不然可能会切不过去，因为TeamInfoChanged的人可能因为不动而不rep
                CheckOtherTeamInfoChanged(self)
            else
                LOG("TryWatchTeammateBattle try watch other team ,other team already rep now! ::",self.nWatchTeamId, nWatchTeamId)
                --当前Rep新的Team已经下来了，所以可以直接切
                TryWatchTeammate(self)
            end
        else
            LOG("TryWatchTeammateBattle try to watch original team")
            TryWatchTeammate(self)
        end
    else
        SetWatchState(self, WatchBattleDef.FAIL)
    end
end

------------------------------------------------------------------------
--部分发包

function WatchBattleSystem_C:RequestStopWatchTeammate(nStopType)
    local nCurrentWatchId = TeamWatchClientHelper.GetCurrentWatchId()
    local tbPacket = {
        watch_mate_id = nCurrentWatchId,
        stop_type = nStopType,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_StopWatchTeammateBattle, tbPacket)
end

function WatchBattleSystem_C:RequestWatchTeammateStatistics(nMateInsId)
    local tbPacket = {
        nInstanceId = nMateInsId
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_FFAWatchMateTips, tbPacket)
end

-----------------------------------------------------------------------
--处理死亡相关

local function IsAlreadyBattleResult()
    local ActiveUIState = UIManager:GetActiveState()
    if ActiveUIState ~= nil and ActiveUIState.szName == UIStateDef.StateName.UI_FFA_RESULT_STATE then
        return true
    end
    return false
end

local function CloseWndsForDead()
    for i, v in ipairs(CLOSEWNDS) do
        UIManager:CloseWnd(v)
    end
end

local function ProcessPlayerDead(self, nDeadInsId, nCauserInsId, nLastDamageType)
    local bIsWatchBattleCameraState = GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.ViewTeammateShip)
        or GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.ViewTeammateHuman)
    if bIsWatchBattleCameraState then
        return
    end
    CloseWndsForDead()

    local tbDeader = GameObjectSystem:FindByInstanceId(nDeadInsId)
    local tbCauser = GameObjectSystem:FindByInstanceId(nCauserInsId)

    local tbValidMateInfo = TeamWatchClientHelper.GetValidOriginalTeammateInfo()
    LOG("ProcessPlayerDead process player dead 1",tbValidMateInfo == nil, IsAlreadyBattleResult())
    if tbValidMateInfo and not IsAlreadyBattleResult() then  --判断当前是否是组队模式 并且还有存活队友
        --此时需要先切死亡视角，延迟切的话人变盒子了视角切会有问题
        LOG("ProcessPlayerDead process player dead 2, has mate")
        ToDeadView(self, tbDeader, true)
        local function DelayFunc()
            --因为延迟弹界面，所以再重新取一次，可能重伤的消息跟死亡同时下来，但是先收到死亡，此时重伤判断未必能判出来
            tbValidMateInfo = TeamWatchClientHelper.GetValidOriginalTeammateInfo()
            LOG("ProcessPlayerDead process player dead 3, has mate")
            if tbValidMateInfo and not IsAlreadyBattleResult() then
                LOG("ProcessPlayerDead process player dead 4, open watch battle result")
                UIManager:OpenWnd(UIDef.UI_WATCHBATTLE_RESULT)
            else
                LOG("ProcessPlayerDead process player dead 5  ", IsAlreadyBattleResult())
            end
        end
        self.tbDelayWatchTimer = DelayTimer:DelayRun(DelayFunc, BattleResultIni.tbBattleResult.nWatchDelay)
    else

        if not IsDeadByOtherKiller(self, nDeadInsId, nCauserInsId, nLastDamageType) then
            LOG("ProcessPlayerDead process player dead 6, not valid mate, not dead by other player")
            ToDeadView(self, tbDeader, true)
        else
            LOG("ProcessPlayerDead process player dead 7, not valid mate, dead by other player")
            ToKillerView(self, tbDeader, tbCauser, nLastDamageType)
        end
    end
end

--为当前单人或正在观战的非队伍其他人寻找击杀者
local function FindKillerForCurrentWatch(self, nDeadInstanceId, nCauserInstanceId, nLastDamageType)
    local tbPlayer = PlayerSelfHelper:Get()
    local bDeadByKiller = IsDeadByOtherKiller(self, nDeadInstanceId, nCauserInstanceId, nLastDamageType)
    local bIsCauserPlayerOther = nCauserInstanceId > 0 and nCauserInstanceId ~= nDeadInstanceId

    local nRealPlayerId = -1
    local nCurrentWatchId = TeamWatchClientHelper.GetCurrentWatchId()
    if nCurrentWatchId == -1 then --代表当前 单人模式还没进行观战，这个时候找杀当前玩家的
        nRealPlayerId = tbPlayer:GetServerInstanceId()
    else
        nRealPlayerId = nCurrentWatchId
    end
    if nRealPlayerId == nDeadInstanceId and bDeadByKiller and bIsCauserPlayerOther then
        return nCauserInstanceId
    end
    -- LOG(" --> Find killer", nCurrentWatchId, tbDeader.nServerInstanceId, nRealPlayerId, bDeadByKiller, bIsCauserPlayerOther)
    return -1
end

--处理寻找击杀者
local function ProcessLastPlayerKiller(self, nDeadInstanceId, nCauserInstanceId, nLastDamageType)
    self.tbOtherInstanceId = -1
    LOG("--> Find killer start -------", PlayerSelfHelper:Get():GetServerInstanceId())
    if IsTeamBattle() then
        --LOG("--> Find killer , in team mode")
        local tbTeamInfo = TeamWatchClientHelper.GetOriginalTeamInfo()
        if tbTeamInfo ~= nil then
            for k, v in ipairs(tbTeamInfo) do
                if v.nInstanceId == nDeadInstanceId then
                    local bDeadByOtherKiller = IsDeadByOtherKiller(self, nDeadInstanceId, nCauserInstanceId, nLastDamageType)
                    local bIsCauserPlayerOther = nCauserInstanceId > 0 and  nCauserInstanceId ~= nDeadInstanceId
                    local bValid = bDeadByOtherKiller and bIsCauserPlayerOther
                    LOG("--> Find killer , kill reason is :", bDeadByOtherKiller, nCauserInstanceId, bValid)
                    table.insert(self.tbTeamDeadReason, bValid and nCauserInstanceId or -1)
                end
            end
        end

        local bIsWatchOriginTeam = TeamWatchClientHelper.GetOtherWatchTeamId() == -1
        --当前依然是自己的队伍，还没有切其他队伍
        if bIsWatchOriginTeam then
            --自己的队伍全部阵亡，计算结算，如果切其他人 那么记下杀死队伍最后那个人是谁
            LOG("--> Find killer , find killer for original team")
            if TeamWatchClientHelper.IsOriginalTeamDead() then
                local tbDeadReasons = self.tbTeamDeadReason
                self.tbOtherInstanceId = #tbDeadReasons == 0 and -1 or tbDeadReasons[#tbDeadReasons]
                LOG("--> Find killer , find killer for original team but team is dead")
            end
        else
            LOG("--> Find killer , team mode but find in other team")
            --切队伍了
            self.tbOtherInstanceId = FindKillerForCurrentWatch(self, nDeadInstanceId, nCauserInstanceId, nLastDamageType)
        end
    else
        LOG("--> Find killer , in single mode")
        self.tbOtherInstanceId = FindKillerForCurrentWatch(self, nDeadInstanceId, nCauserInstanceId, nLastDamageType)
    end
    LOG("--> Find killer, result is : ", self.tbOtherInstanceId)
    LOG("--> Find killer end -------")
end


local function OnPawnDead(self, nKillType, szKillerName, szDeadName, nKillerInstanceId, nDeadInstanceId,
        nLastDamageType, nWeaponTemplateId)

    if nKillType == Proto.d2c_BattleKillToast_EType.KILL then
        local tbPlayer = PlayerSelfHelper:Get()
        --有顺序依赖关系，不能调换顺序
        TeamWatchClientHelper.ProcessOriginalTeamDead(nDeadInstanceId)
        ProcessLastPlayerKiller(self, nDeadInstanceId, nKillerInstanceId, nLastDamageType)
        if tbPlayer:GetServerInstanceId() == nDeadInstanceId then
            ProcessPlayerDead(self, nDeadInstanceId, nKillerInstanceId, nLastDamageType)
        end
        self.EventHelper:FireEvent(ClientEventDef.EV_PAWN_DEAD_WATCHER_CHECK, nDeadInstanceId)
    end
end

--------------------------------------------------------------------------


local function OnReLoginRefreshBattleResultWnd(self,bTeamDead)
    ToDeadViewImmediately(self,PlayerSelfHelper:Get())
    self.bReLoginShowWatchWnd = true
    self.bReLoginTeamDead = bTeamDead
    TeamWatchClientHelper.InitOriginalTeamData()
end

local function OnExitLoading(self)
    if self.bReLoginShowWatchWnd then
        if self.bReLoginTeamDead then
            self.EventHelper:FireEvent(ClientEventDef.EV_BATTLE_OPEN_RESULT, true)
        else
            UIManager:OpenWnd(UIDef.UI_WATCHBATTLE_RESULT)
        end

        self.bReLoginShowWatchWnd = false
        self.bReLoginTeamDead     = false
    end
end

local function IsWatchBattleState()
    local ActiveUIState = UIManager:GetActiveState()
    if ActiveUIState.szName == UIStateDef.StateName.UI_WATCH_BATTLE_STATE then
        return true
    end
    return false
end

local function OnBattleGameOver(self)
    self.bBattleGameEnd = true
    --if IsWatchBattleState() and TeamWatchClientHelper.IsOtherTeamWatch() then
    LOG("watch battle system_c battle game over ")
    if not IsAlreadyBattleResult() and IsWatchBattleState() then
        LOG("battle game over try open battle result")
        --战局结束了，需要重设镜头角度
        self.EventHelper:FireEvent(ClientEventDef.EV_GAME_OVER_CAMERA_DETACH, true)
        self.EventHelper:FireEvent(ClientEventDef.EV_BATTLE_OPEN_RESULT, true)
        self:RequestStopWatchTeammate(EStopType.FINISH)
    end
end

local function RegisterEvent(self)
    local EventHelper = self.EventHelper

    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_BATTLE_TOAST, self, OnPawnDead)

    EventHelper:RegisterEvent(CommonEventDef.EV_CHANGE_WATCH_MATE, self, TryWatchTeammateBattle)
    EventHelper:RegisterEvent(CommonEventDef.EV_REQUEST_CHANGE_WATCH_MATE, self, RequestWatchTarget)
    EventHelper:RegisterEvent(CommonEventDef.EV_REQUEST_CHANGE_WATCH_OTHER, self, RequestWatchOther)

    EventHelper:RegisterEvent(CommonEventDef.EV_STOP_WATCH_MATE, self, StopWatchTeammateBattle)
    EventHelper:RegisterEvent(CommonEventDef.EV_MATE_CHANGE_AIM_STATE, self, ChangeViewerAimState)
    EventHelper:RegisterEvent(CommonEventDef.EV_MATE_MOVEMENT_STATE, self, ChangeViewerMovementStateCamera)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnWatchMateActorCreate)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnWatchMateActorDestroy)

    EventHelper:RegisterEvent(CommonEventDef.EV_WATCH_MATE_ON_VEHICLE, self, OnWatchMateOnVehicle)
    EventHelper:RegisterEvent(CommonEventDef.EV_FFA_RELOGIN_REFRESH_BATTLE_RESULT, self, OnReLoginRefreshBattleResultWnd)
    EventHelper:RegisterEvent(CommonEventDef.EV_DUNGEON_GAME_OVER, self, OnBattleGameOver)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, self, OnVehicleStateChange)

    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, TeamInfoChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, OnExitLoading)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MODE_INFO, self, OnTeamModeInfo)
end

local function ResetVars(self)
    self.bWaitForCreate = false
    self.nCurrentVehicleId = -1
    self.bNeedWaitVehicle = false

    self.bReLoginShowWatchWnd = false
    self.bReLoginTeamDead     = false

    self.tbOtherInstanceId = -1
    self.bInitOriginalTeam = false
    self.bBattleGameEnd = false
    self.bSelfExitWatch = false
    self.nWatchTeamId = -1
    self.nWatchState = WatchBattleDef.NONE
end

function WatchBattleSystem_C:SetSelfExitWatch(bExit)
    self.bSelfExitWatch = bExit
end

function WatchBattleSystem_C:IsSelfExitWatch()
    return self.bSelfExitWatch
end

function WatchBattleSystem_C:IsReloginTeamDead()
    return self.bReLoginTeamDead
end

function WatchBattleSystem_C:Init()
    WatchBattleSystem_C.super.Init(self)
    self.tbTeamDeadReason = {}
    self.tbDeadCameraParam = DeadCameraDataTable:GetTemplate(DEAD_CAMERA)

    ResetVars(self)
    RegisterEvent(self)
end

function WatchBattleSystem_C:Uninit()
    WatchBattleSystem_C.super.Uninit(self)

    self.tbLastWatchTarget = nil
    self.tbCurrentWatchTarget = nil
    ResetVars(self)
    self.EventHelper:UnregisterAll()
    if self.tbTimerObject then
        DelayTimer:ClearTimer(self.tbTimerObject)
        self.tbTimerObject = nil
    end
    if self.tbDelayWatchTimer then
        DelayTimer:ClearTimer(self.tbDelayWatchTimer)
        self.tbDelayWatchTimer = nil
    end
end

return WatchBattleSystem_C()