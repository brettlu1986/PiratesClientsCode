-- 玩家自己
-- 在切地图时GamePlayerSelf_C不会销毁，但其用到的UEActor可能会被销毁
-- 所以逻辑数据可尽情放到此类中，但依赖UEActor的逻辑模块则需要小心切换场景

local luaclass = require("luaclass")
local GamePlayerSelfClass = require("GamePlayerSelf")
local GamePlayerSelf_C = luaclass("GamePlayerSelf_C", GamePlayerSelfClass)

local UEActorHelper = require("UEActorHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local GameComponentCreateHelper = require("GameComponentCreateHelper")
local GameComponentTypeDefine = require("GameComponentTypeDefine")
-- local HandlerManagerHelper = require("HandlerManagerHelper")
local ControlModeSystem = require("ControlModeSystem")
local TemplateTypeDef = require("TemplateTypeDef")
local CommonEventDef = require("CommonEventDef")
local SelfAnimationHelper = require("SelfAnimationHelper")
local EffectHelper = require("EffectHelper")
local DamageTypeEx = require("DamageTypeEx")
local HumanMovementStateType = require("HumanMovementStateType")
-- local GenderTypeDefine = require("GenderTypeDefine")
local NetworkManager = require("NetworkManager_C")
local HumanBodyDef = require("HumanBodyDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local VehicleDamageHelper = require("VehicleDamageHelper")
local HumanWeaponHelper = nil      -- 在用的时候require，解决循环引用

local HIT_EFFECT_ID = 36
local SHIP_CAMERA_COMMAND = "xsj.Mobile.StaticCSMCacheCameraDistanceThresHold 5000.0"
local HUMAN_CAMERA_COMMAND= "xsj.Mobile.StaticCSMCacheCameraDistanceThresHold 1000.0"

local DIRECTION_DEF = {
    ["FORWARD"] = 1,
    ["LEFT"]    = 2,
    ["RIGHT"]   = 3,
    ["BACK"]    = 4,
}

local HUMAN_PROPERTY_NAME = {
    [HumanBodyDef.HUMAN_HEAD] = {
        "Head",
    },
    [HumanBodyDef.HUMAN_BODY] = {
        "Body",
    },
    [HumanBodyDef.HUMAN_ALLFOURS] = {
        [DIRECTION_DEF.LEFT] = "Uparm_l",
        [DIRECTION_DEF.RIGHT] = "Uparm_r",
        [DIRECTION_DEF.FORWARD] = "Forearm_l",
        [DIRECTION_DEF.BACK] = "Body",
    },
}

local HIT_ANIM_DEF = {
    [DIRECTION_DEF.LEFT]    = SelfAnimationHelper.AnimDef.ON_HIT_LEFT,
    [DIRECTION_DEF.RIGHT]   = SelfAnimationHelper.AnimDef.ON_HIT_RIGHT,
    [DIRECTION_DEF.FORWARD] = SelfAnimationHelper.AnimDef.ON_HIT_FORWARD,
    [DIRECTION_DEF.BACK]    = SelfAnimationHelper.AnimDef.ON_HIT_BACK,
}

GamePlayerSelf_C.nReplicatedPCNetGuid = nil
GamePlayerSelf_C.nReplicatedPawnNetGuid = nil
GamePlayerSelf_C.bReady = false
GamePlayerSelf_C.bPawnBeginPlay = false
GamePlayerSelf_C.bDungeonPrepareReady = false

-- ServerInstanceId 会根据进出副本进行切换
GamePlayerSelf_C.nHubServerId = nil
GamePlayerSelf_C.tbHubCustomData = nil
GamePlayerSelf_C.bHasReattachedComponents = false

-- 玩家副本的初始数据
GamePlayerSelf_C.tbInitProtoData = nil

local function GetHumanPropertyNameByRegionTypeAndDirection(nRegionType, nDirection)
    local szType = nil
    local tbTypes = HUMAN_PROPERTY_NAME[nRegionType]
    if not tbTypes then
        return szType
    end

    szType = tbTypes[nDirection]
    if not szType then
        szType = tbTypes[1]
    end

    return szType
end

local function PlayHitAnimation(self, tbTaker, tbCauser, nDirection)
    local HumanMovementStateComponent = tbTaker.HumanMovementStateComponent
    local nCurrentMovementState = HumanMovementStateComponent:GetCurrentState()

    if nCurrentMovementState == HumanMovementStateType.Crawl_State then
        if not SelfAnimationHelper:IsHumanMontagePlaying(tbTaker, SelfAnimationHelper.AnimDef.ON_HIT_CRAWL) then
            SelfAnimationHelper:PlayHumanAnimation(tbTaker, SelfAnimationHelper.AnimDef.ON_HIT_CRAWL)
            log("[HitAnim] GamePlayerSelf_C:OnTakeDamage ON_HIT_CRAWL Taker:", tbTaker:GetName(), "Causer:", tbCauser:GetName())
            return
        end
    end

    if self.nServerInstanceId == tbCauser.nServerInstanceId and tbTaker.nServerInstanceId ~= tbCauser.nServerInstanceId and HumanMovementStateComponent:GetCurrentState() ~= HumanMovementStateType.Dying_State then
        local szAnimKey = HIT_ANIM_DEF[nDirection]
        if not SelfAnimationHelper:IsHumanMontagePlaying(tbTaker, szAnimKey) then
            SelfAnimationHelper:PlayHumanAnimation(tbTaker, szAnimKey)
            log("[HitAnim] GamePlayerSelf_C:OnTakeDamage Taker:", tbTaker:GetName(), "Causer:", tbCauser:GetName())
        end
    end

    return
end

function GamePlayerSelf_C:OnCreateComponents()
    self.bHasReattachedComponents = GamePlayerSelfHelper:ReattachComponentsWithGameObject(self)

    return GamePlayerSelf_C.super.OnCreateComponents(self)
end

function GamePlayerSelf_C:OnPreCreate(tbCreateData, tbCustomData)
    self.tbHubCustomData = tbCustomData

    EventManager:BindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, self.OnEnterBattle)
    EventManager:BindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_WILD, self, self.OnEnterWild)
    EventManager:BindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, self.OnTakeDamage)

    return GamePlayerSelf_C.super.OnPreCreate(self, tbCreateData, tbCustomData)
end

function GamePlayerSelf_C:OnActorPreCreated(pUEActor)
    GamePlayerSelf_C.super.OnActorPreCreated(self, pUEActor)
    local fnInitPlayerSelf = pUEActor.InitPlayerSelf
    if fnInitPlayerSelf then
        fnInitPlayerSelf(pUEActor)
    end
end


function GamePlayerSelf_C:OnActorCreated(pUEActor)
    GamePlayerSelf_C.super.OnActorCreated(self, pUEActor)

    if(not GlobalVariableSystem.bIsInDungeon) then
        local pPC = GameplayStatics.GetPlayerController(GWorld, 0)
        pPC:Possess(pUEActor)
        self:BindUEController(pPC, EngineExtActorShell.GetActorUniqueId(pPC))
        self.bIsSpectator = false
        if self:IsShip() then
            self:FlushShipAvatarRes()
        else
            self:FlushHumanAvatarRes()
        end
        pUEActor.CharacterMovement:SetMovementMode(EMovementMode.MOVE_Walking, 0)
    else
        if(self.pUEActor) then
            if(self:IsHuman())then
                -- 应引擎要求，把玩家自己不进行重要度管理
                self.pUEActor:UnRegisterFromSignificance()
                KismetSystemLibrary.ExecuteConsoleCommand(GWorld, HUMAN_CAMERA_COMMAND, nil)
            else
                -- 应引擎要求，动态调整 cvar 参数
                KismetSystemLibrary.ExecuteConsoleCommand(GWorld, SHIP_CAMERA_COMMAND, nil)
            end
        end
    end

    -- 重新绑定时候清除死亡状态
    self.bReady = false
    self.bPawnBeginPlay = true
    local AreaTriggerManager = ClientShell.GetClient(GWorld):GetAreaTriggerManager()
    AreaTriggerManager:AddActor(pUEActor)
end

function GamePlayerSelf_C:UnbindUEActor()
    local pUEActor = self.pUEActor
    if(pUEActor and isvalidhandle(pUEActor) and GlobalVariableSystem.bIsInDungeon) then
        ClientShell.GetClient(GWorld):GetGridTypeManager():RemoveActor(pUEActor)
    end

    ControlModeSystem:OnPlayerSelfUnready(self)
    self.bReady = false
    self.bPawnBeginPlay = false
    EventManager:OnFireEvent(ClientEventDef.EV_PLAYERSELF_UNREADY)
    GamePlayerSelf_C.super.UnbindUEActor(self)
end

function GamePlayerSelf_C:OnPostCreate()
    GamePlayerSelf_C.super.OnPostCreate(self)

    GamePlayerSelfHelper:Set(self)

    if(not self.bHasReattachedComponents) then
        -- 第一次执行
        --可以做一些特定顺序的逻辑

        -- 可以做component有相互依赖的的数据初始化
        -- 需要判空，说明没有连hubserver，就不用处理了
        if self.SailorComponent ~= nil then
            self.SailorComponent:OnPostCreate()
        end
        if self.ShipPreparationComponent ~= nil then
            self.ShipPreparationComponent:OnPostCreate()
        end
        if self.PartnerComponent ~= nil then
            self.PartnerComponent:OnPostCreate()
        end
        if self.PlayerNewItemRecordComponent ~= nil then
            self.PlayerNewItemRecordComponent:OnPostCreate()
        end
    end
end

function GamePlayerSelf_C:OnDestroy()
    EventManager:UnBindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, self.OnEnterBattle)
    EventManager:UnBindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_WILD, self, self.OnEnterWild)
    EventManager:UnBindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, self.OnTakeDamage)

    --GamePlayerSelf_C.super.OnDestroy(self)
    self:DestroyUEActor()

    -- 这里有detach component操作，所以必须放在DestroyAllComponents前
    GamePlayerSelfHelper:DetachComponentsWithGameObject(self)

    self:DestroyAllComponents()

    GamePlayerSelfHelper:Set(nil)
    log("GamePlayerSelf_C:OnDestroy")
end

-- Hub恢复Actor
function GamePlayerSelf_C:RestoreUEActor(tbCreateData, tbCustomData)
    log("GamePlayerSelf_C:RestoreUEActor")
    local pOldActor = self.pUEActor
    local pClientShell = ClientShell.GetClient(GWorld)
    local bIsSmoothTravel = pClientShell:IsInSmoothTravel()

    -- SmoothTravel比较特殊，必须先摘掉老Actor然后调用pActor:SmoothTravelSwap(pOldActor)，最后再把老的删掉
    if(pOldActor) then
        log("GamePlayerSelf_C:RestoreUEActor, unbindUEActor")
        self:UnbindUEActor()
    end

    if(tbCreateData ~= nil) then
        if(not self:ParseCreateData(tbCreateData)) then
            logerror("GameObject:RestoreUEActor parse create data failed, ", self:GetServerInstanceId())
            return false
        end
    end

    self.tbCustomData = tbCustomData
    local pNewActor = self:CreateUEActor(self.nTemplateId)

    if(not pNewActor) then
        logerror("GameObject:RestoreUEActor failed, ServerId: ", self:GetServerInstanceId(), ", TemplateId: ", self.nTemplateId)
        return false
    end

    log("GamePlayerSelf_C:RestorePlayerSelf successed, ServerId: ", self:GetServerInstanceId(), ", TemplateId: ", self.nTemplateId)

    local SmoothTravel = false
    if bIsSmoothTravel and pOldActor ~= nil and KismetSystemLibrary.DoesImplementInterface(pNewActor, SmoothTravel) then
        log("GamePlayerSelf_C:RestorePlayerSelf. Swap new actor with old one")
        pNewActor:SmoothTravelSwap(pOldActor)
    else
        log("GamePlayerSelf_C:RestorePlayerSelf. Skip swap new actor with old one")
    end

    UEActorHelper:DestroyActor(pOldActor)
    return true
end

-- Replicate actor时用，这时Pawn beginplay了
function GamePlayerSelf_C:BindReplicatedUEActor(pUEActor, tbCreateData, tbCustomData)
    GamePlayerSelf_C.super.BindReplicatedUEActor(self, pUEActor, tbCreateData, tbCustomData)

    EventManager:OnFireEvent(ClientEventDef.EV_PLAYERSELF_BINDREPLICATE_UEACTOR)
    return true
end

-- Replicate controller时用，这时Controller beginplay了
function GamePlayerSelf_C:BindUEController(pController, nControllerNetGuid, nControllerUniqueId)
    log("GamePlayerSelf_C:BindUEController", nControllerNetGuid, nControllerUniqueId)

    GamePlayerSelf_C.super.BindUEController(self, pController, nControllerNetGuid, nControllerUniqueId)
end

-- 这里表明possess了
function GamePlayerSelf_C:OnClientRestart(nPCNetGuid, nPawnNetGuid)
    log("GamePlayerSelf_C:OnClientRestart", nPCNetGuid, nPawnNetGuid)

    self.nReplicatedPCNetGuid = nPCNetGuid
    self.nReplicatedPawnNetGuid = nPawnNetGuid
end

function GamePlayerSelf_C:VerifyReplicatedPlayerReady()
    if(not GlobalVariableSystem.bIsInDungeon or GlobalVariableSystem.bIsStandalone) then
        return false
    end

    local nReplicatedPCNetGuid = self.nReplicatedPCNetGuid
    local nUEControllerNetGuid = self.nUEControllerNetGuid
    local nReplicatedPawnNetGuid = self.nReplicatedPawnNetGuid
    local bPawnBeginPlay = self.bPawnBeginPlay
    local bIsSpectator = self.bIsSpectator
    local bDungeonPrepareReady = self.bDungeonPrepareReady

    local nPawnNetGuid = EngineExtActorShell.GetActorNetGuid(self.pUEActor)
    log(string.format("GamePlayerSelf_C:VerifyReplicatedPlayerReady check RCGuid: %d, CGuid: %d, RPGuid: %d, PGuid: %d, IsBeginPlay: %d, IsSpectator: %d, IsDungeonPrepareReady: %d",
        nReplicatedPCNetGuid or -1,
        nUEControllerNetGuid or -1,
        nReplicatedPawnNetGuid or -1,
        nPawnNetGuid or -1,
        bPawnBeginPlay == true and 1 or 0,
        bIsSpectator == true and 1 or 0,
        bDungeonPrepareReady == true and 1 or 0
    ))

    if(not bPawnBeginPlay) then
        return false
    end

    -- 检查controllernetguid是否一致
    if(nReplicatedPCNetGuid ~= nUEControllerNetGuid) then
        return false
    end

    local bInVehicle = false
    if self:IsHuman() then
        local HumanMovementStateComponent = self.HumanMovementStateComponent
        if HumanMovementStateComponent and HumanMovementStateComponent:IsInVehicle() then
            bInVehicle = true
        end
    end

    -- 如果是spectator不校验pawn，如果是则检查pawn的netguid
    if(not bIsSpectator and not bInVehicle) then
        if(nReplicatedPawnNetGuid ~= nPawnNetGuid) then
            return false
        end
    end

    if (not bDungeonPrepareReady) then
        return false
    end

    -- 防止重复触发
    self.nReplicatedPCNetGuid = nil
    self.nReplicatedPawnNetGuid = nil

    self:MarkPlayerSelfReady()
    return true
end

function GamePlayerSelf_C:OnBeginSpectating()
    -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.SpectatorMode)

    if(self.pUEController) then
        local SpectatorPawn = self.pUEController:GetSpectatorPawn()
        if(SpectatorPawn) then
            SpectatorPawn:Init()
        end
    end

    GamePlayerSelf_C.super.OnBeginSpectating(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ENTER_SPECTATOR_MODE)

    -- 如果进入观察者模式，那么pawn就下不来了，这里得验证一下
    self:VerifyReplicatedPlayerReady()
end

function GamePlayerSelf_C:OnEndSpectating()
    EventManager:OnFireEvent(ClientEventDef.EV_EXIT_SPECTATOR_MODE)
    GamePlayerSelf_C.super.OnEndSpectating(self)
end

function GamePlayerSelf_C:GetDebugInfo()
    local tbRet = GamePlayerSelf_C.super.GetDebugInfo(self)
    tbRet.nHubServerId = self.nHubServerId
    tbRet.nUEControllerNetGuid = self.nUEControllerNetGuid
    return tbRet
end

function GamePlayerSelf_C:FlushShipAvatarRes()
    if(GlobalVariableSystem.bIsInDungeon) then
        return
    end

    -- if self:IsShip() then
    --     assert(self.DockComponent.bHasInited)
    --     -- 必须放在这里，要不然会循环引用
    --     local DockSystem = require("DockSystem")
    --     local tbResData = DockSystem:GetPlayerSelfShipResData(self.DockComponent:GetFlagShipInstanceId())
    --     self.ShipAvatarComponent:UpdateResData(tbResData)
    -- end
end

function GamePlayerSelf_C:FlushHumanAvatarRes()
    if(GlobalVariableSystem.bIsInDungeon) then
        return
    end

    -- if not self:IsShip() then
    --     local tbResData = self.HumanPropertyComponent:GetProp(PropName.nResData)
    --     self.HumanAvatarComponent:UpdateResData(tbResData)
    -- end
end

function GamePlayerSelf_C:RefreshHubData(tbCustomData)
    log("GamePlayerSelf_C:RefreshHubData start")

    self.tbCustomData    = tbCustomData
    self.tbHubCustomData = tbCustomData

    local Def                   = GameComponentTypeDefine
    local tbComponents          = self.tbComponents
    local nCurEnvironmentType   = Def.tbEnvironmentType.Lobby
    local nCurActorType         = Def.tbActorType.Ship
    local tbLiftType            = Def.tbLifeCycleType

    local CheckEnvironmentType = function(Component)
        local nEnvironmentType, _ = GameComponentCreateHelper:GetComponentRegistInfo(Component.szClassName)
        return nEnvironmentType and (nEnvironmentType & nCurEnvironmentType > 0)
    end

    if self.pUEActor == nil then
        logwarning("GamePlayerSelf_C:RefreshHubData but pUEActor is nil")
    end

    if self.pUEActor ~= nil then
        for k, v in ipairs(tbComponents) do
            if CheckEnvironmentType(v) then
                v:OnActorDestroyed(self.pUEActor)
            end
        end
    end
    local tbDestroyComponents = GameComponentCreateHelper:DestroyComponentByEnviromentType(self, nCurEnvironmentType)

    for k, v in ipairs(tbDestroyComponents) do
        GameComponentCreateHelper:CreateComponentByClassName(self, nCurEnvironmentType, nCurActorType, tbLiftType.WithGameObject, v)
    end
    self:OnPostCreate()

    if self.pUEActor ~= nil then
        for k, v in ipairs(tbDestroyComponents) do
            GameComponentCreateHelper:CreateComponentByClassName(self, nCurEnvironmentType, nCurActorType, tbLiftType.WithUEActor, v)
        end
        for k, v in ipairs(tbComponents) do
            if CheckEnvironmentType(v) then
                v:OnActorCreated(self.pUEActor)
            end
        end
    end

    log("GamePlayerSelf_C:RefreshHubData end")
end

function GamePlayerSelf_C:MarkPlayerSelfReady()
    if(self.bReady) then
        return
    end

    log("GamePlayerSelf_C:MarkPlayerSelfReady, player self is ready")

    NetworkManager:GetRPCNetworkProxy():SetActorAsyncCreatingEnabled(GlobalVariableSystem.bEnableActorAsyncCreating)

    -- 这个最好在发playerselfready前调用
    --ControlModeSystem:OnPlayerSelfReady(self)

    -- Init OceanConfig
    local tbOceanSystems = GameplayStatics.GetAllActorsOfClass(GWorld, OceanSystem)
    local pOceanSystem = tbOceanSystems[1]
    if pOceanSystem then
        pOceanSystem:SetPlayerMyself(self.pUEActor)
        if(GlobalVariableSystem.bIsInDungeon) then
            pOceanSystem.bFlotageLockZ = false
        end
    end

    self.szGuildName = self.GuildComponent and self.GuildComponent:GetGuildName()
    self.bReady = true
    local pPC = GameplayStatics.GetPlayerController(GWorld, 0)
    pPC:OnMarkClientPlayerSelfReady()
    EventManager:OnFireEvent(ClientEventDef.EV_PLAYERSELF_READY)
    --放在这里，等ui都准备好了再切换control mode
    ControlModeSystem:OnPlayerSelfReady(self)
end

function GamePlayerSelf_C:OnEnterBattle()
    self.nTemplateType = TemplateTypeDef.SHIP
    self.bReady = false
    self.bPawnBeginPlay = false
    self.bDungeonPrepareReady = false
end

function GamePlayerSelf_C:OnEnterWild()
    self.bReady = false
    self.bPawnBeginPlay = false
    self.bDungeonPrepareReady = false
    self:SetInitProtoData(nil)
end

function GamePlayerSelf_C:OnShipPropertyValueChanged()
    if self:IsShip() then
        local HubMovementComponent = self.HubMovementComponent
        if HubMovementComponent then
            HubMovementComponent:ResetSelfGears()
        else
            logerror("ShipHubMovementComponent get fail!")
        end
    end
end

function GamePlayerSelf_C:SetGuildName(szName)
    self.szGuildName = szName
end

function GamePlayerSelf_C:OnTakeDamage(tbTaker, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, tbDamageExtraData)
    if  nDamageType ~= DamageTypeEx.HUMAN_GRENADE
    and nDamageType ~= DamageTypeEx.HUMAN_EMPTY_HAND
    and nDamageType ~= DamageTypeEx.HUMAN_MELEE
    and nDamageType ~= DamageTypeEx.HUMAN_PISTOL
    and nDamageType ~= DamageTypeEx.HUMAN_FLINTLOCK
    and nDamageType ~= DamageTypeEx.HUMAN_MATCHLOCK
    and nDamageType ~= DamageTypeEx.HUMAN_CROSSBOW
    and nDamageType ~= DamageTypeEx.HUMAN_BOW
    and nDamageType ~= DamageTypeEx.HUMAN_MAGIC then
        return
    end

    if not tbTaker or tbTaker:GetObjectType() == GameObjectTypeDef.DestructibleObject then
        return
    end

    if not tbTaker.pUEActor or tbTaker:IsShip() then
        return
    end

    if not tbCauser or not tbCauser:IsHuman() then
        return
    end

    if self.nServerInstanceId ~= tbCauser.nServerInstanceId and self.nServerInstanceId ~= tbTaker.nServerInstanceId then
        return
    end

    if tbTaker:IsDead() or tbTaker.pUEActor:IsPlayingRootMotion() then
        return
    end

    if nDamage <= 0 then
        return
    end

    if tbTaker.ObjectType == GameObjectTypeDef.Horse then
        local szDamageType = VehicleDamageHelper.CalculateDamageType(tbTaker, tbCauser, tbDamageExtraData and tbDamageExtraData.nRegionType)
        VehicleDamageHelper.PlayHitEffect(tbTaker, nil, szDamageType)
        return
    end

    local nDirection = 1
    local Direction = tbTaker.pUEActor:GetDirectionFromActor(tbCauser.pUEActor)
    if Direction >= -45 and Direction <= 45 then  -- Forward
        nDirection = DIRECTION_DEF.FORWARD
    elseif Direction >= 145 or Direction <= -145 then -- Back
        nDirection = DIRECTION_DEF.BACK
    elseif Direction <-45 and Direction >-145 then  --Left
        nDirection = DIRECTION_DEF.LEFT
    else --Right
        nDirection = DIRECTION_DEF.RIGHT
    end

    if tbTaker.pUEActor:WasRecentlyRendered(0.2) or GlobalVariableSystem:IsServerLogic() then
        PlayHitAnimation(self, tbTaker, tbCauser, nDirection)
    else
        log("[HitAnim] GamePlayerSelf_C:OnTakeDamage Taker was not recently rendered Taker:", tbTaker:GetName(), "Causer:", tbCauser:GetName())
    end

    local pReleationLocation = nil
    if tbDamageExtraData and tbDamageExtraData.nRegionType then
        local szType = GetHumanPropertyNameByRegionTypeAndDirection(tbDamageExtraData.nRegionType, nDirection)
        if szType then
            if not HumanWeaponHelper then
                HumanWeaponHelper = require("HumanWeaponHelper")      -- 会循环引用
            end
            pReleationLocation = HumanWeaponHelper.GetLocationByHitType(tbTaker.pUEActor, szType)
        end
    end
    EffectHelper:PlayEffectAttached(tbTaker, HIT_EFFECT_ID, pReleationLocation)

end

function GamePlayerSelf_C:SetInitProtoData(tbInitProtoData)
    self.tbInitProtoData = tbInitProtoData
end

function GamePlayerSelf_C:GetInitProtoData()
    return self.tbInitProtoData
end

return GamePlayerSelf_C

