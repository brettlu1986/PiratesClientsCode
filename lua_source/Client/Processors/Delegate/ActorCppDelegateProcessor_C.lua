local luaclass = require("luaclass")
local ActorCppDelegateProcessorClass = require("ActorCppDelegateProcessor")
local ActorCppDelegateProcessor_C = luaclass("ActorCppDelegateProcessor_C", ActorCppDelegateProcessorClass)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local GameObjectSystem = require("GameObjectSystem_C")
local GameObjectTypeDef = require("GameObjectTypeDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local UEActorHelper = require("UEActorHelper")
local ActorChannelOpenHelper = require("ActorChannelOpenHelper")

ActorCppDelegateProcessor_C.bEnableReplicationMode = false
ActorCppDelegateProcessor_C.tbDelegateHandlers = nil

local tbBeginPlayProcessors = {}
tbBeginPlayProcessors[GameObjectTypeDef.PlayerSelf] = function(pUEActor, nUniqueId, nServerInstanceId, tbInitProtoData)
    return GameObjectSystem:BindReplicatedPlayerSelfActor(pUEActor, nServerInstanceId, tbInitProtoData)
end

tbBeginPlayProcessors[GameObjectTypeDef.PlayerOther] = function(pUEActor, nUniqueId, nServerInstanceId, tbInitProtoData)
    return GameObjectSystem:BindPlayerOtherByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
end

tbBeginPlayProcessors[GameObjectTypeDef.Npc] = function(pUEActor, nUniqueId, nServerInstanceId, tbInitProtoData)
    return GameObjectSystem:BindNpcByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
end

tbBeginPlayProcessors[GameObjectTypeDef.Trigger] = function(pUEActor, nUniqueId, nServerInstanceId, tbInitProtoData)
    return GameObjectSystem:BindTriggerByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
end

tbBeginPlayProcessors[GameObjectTypeDef.Dummy] = function(pUEActor, nUniqueId, nServerInstanceId, tbInitProtoData)
    return GameObjectSystem:BindDummyByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
end

tbBeginPlayProcessors[GameObjectTypeDef.Horse] = function(pUEActor, nUniqueId, nServerInstanceId, tbInitProtoData)
    return GameObjectSystem:BindHorseByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
end

tbBeginPlayProcessors[GameObjectTypeDef.DestructibleObject] = function(pUEActor, nUniqueId, nServerInstanceId, tbInitProtoData)
    return GameObjectSystem:BindDestructibleObjectByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
end

local function OnControllerPreBeginPlay(self, pUEActor, nUniqueId, nServerInstanceId)
    log("ActorCppDelegateProcessor_C:OnControllerPreBeginPlay", nUniqueId, nServerInstanceId)

    -- 同步给客户端的controller，这里应该带了playerId，这里的controller只是自己
    local tbGamePlayerSelf = GamePlayerSelfHelper:Get()
    GameObjectSystem:ChangeServerInstanceId(tbGamePlayerSelf:GetServerInstanceId(), nServerInstanceId)

    local pMessageRef = self.pDungeonCommonActorShell:GetActorSpawnInitData(pUEActor)
    if(pMessageRef == nil) then
        log("ActorCppDelegateProcessor_C:OnControllerPreBeginPlay, no initdata", nUniqueId, nServerInstanceId)
        return
    end
    local tbInitProtoData = msgtoluatable(pMessageRef)
    if(tbInitProtoData == nil) then
        log("ActorCppDelegateProcessor_C:OnControllerPreBeginPlay, msgtoluatable(pMessageRef) failed", nUniqueId, nServerInstanceId)
        return
    end

    local pController = pUEActor
    local nControllerNetGuid = EngineExtActorShell.GetActorNetGuid(pUEActor)
    GameObjectSystem:BindPlayerUEController(tbGamePlayerSelf, pController, nControllerNetGuid, nUniqueId, tbInitProtoData)
end

local function OnControllerEndPlay(self, pUEActor, nUniqueId, nServerInstanceId)
    local tbGamePlayerSelf = GamePlayerSelfHelper:Get()
    if(tbGamePlayerSelf) then
        local nHubId = tbGamePlayerSelf.nHubServerId
        log("ActorCppDelegateProcessor_C:OnControllerEndPlay", nUniqueId, nServerInstanceId, nHubId)
        GameObjectSystem:UnbindPlayerUEController(tbGamePlayerSelf)
        if(nHubId ~= nil) then
            GameObjectSystem:ChangeServerInstanceId(nServerInstanceId, nHubId)
        end
    end
end

local function OnControllerPostBeginPlay(self, pUEActor, nUniqueId, nServerInstanceId)
    GamePlayerSelfHelper:Get():VerifyReplicatedPlayerReady()
end

local function OnActorPreCreated(self, pUEActor, nUniqueId, nServerInstanceId)
    UEActorHelper.TryCreateTemplateComponents(pUEActor, nil, false, false)

    local tbGamePlayerSelf = GamePlayerSelfHelper:Get()
    if(tbGamePlayerSelf == nil) then
        log("ActorCppDelegateProcessor_C:OnPawnPreBeginPlay, no playerself", nUniqueId, nServerInstanceId)
        return
    end

    local pMessageRef = self.pDungeonCommonActorShell:GetActorSpawnInitData(pUEActor)
    if(pMessageRef == nil) then
        log("ActorCppDelegateProcessor_C:OnPawnPreBeginPlay, no initdata", nUniqueId, nServerInstanceId)
        return
    end
    local tbInitProtoData = msgtoluatable(pMessageRef)
    if(tbInitProtoData == nil) then
        log("ActorCppDelegateProcessor_C:OnPawnPreBeginPlay, msgtoluatable(pMessageRef) failed", nUniqueId, nServerInstanceId)
        return
    end

    local nType = tbInitProtoData.script_type
    if(nType == GameObjectTypeDef.PlayerSelf
        and tbGamePlayerSelf.nPlayerId ~= tbInitProtoData.player_id) then
        nType = GameObjectTypeDef.PlayerOther
    end

    log("ActorCppDelegateProcessor_C:OnPreBeginPlay ObjectType: "..nType..", UniqueId: "..nUniqueId..", ServerId:".. nServerInstanceId)
    local fnProcessor = tbBeginPlayProcessors[nType]
    if(fnProcessor == nil) then
        logerror("ActorCppDelegateProcessor_C:OnPreBeginPlay failed, can not find processor, type: "..tbInitProtoData.script_type)
        return
    end

    -- local tbGameObject = GameObjectSystem:FindByInstanceId(nServerInstanceId)
    -- if(tbGameObject) then
    --     GameObjectSystem:UnbindUEActor(tbGameObject)
    -- end

    local tbGameObject = fnProcessor(pUEActor, nUniqueId, nServerInstanceId, tbInitProtoData)
    if(tbGameObject) then
        tbGameObject:OnActorPreCreated(pUEActor)
    end
end

local function OnActorChannelOpen(self, pUEActor, nUniqueId, nServerInstanceId)
    --OnActorPreCreated(self, pUEActor, nUniqueId, nServerInstanceId)
    ActorChannelOpenHelper.OnProcess(pUEActor, nUniqueId, nServerInstanceId)
end

local function OnActorDestroyed(self, pUEActor, nUniqueId, nServerInstanceId)
    local tbGameObject = GameObjectSystem:FindByInstanceId(nServerInstanceId)
    if(tbGameObject and tbGameObject.pUEActor ~= nil and tbGameObject.bHasActorCreated == false) then
        -- 当actorchanelopen时有可能不会beginplay然后就被销毁，这里处理的就是这种情况
        log("OnActorDestroyed", nUniqueId, nServerInstanceId)
        self:OnPawnEndPlay(pUEActor, nUniqueId, nServerInstanceId)
    end
end

function ActorCppDelegateProcessor_C:OnPawnPreBeginPlay(pUEActor, nUniqueId, nServerInstanceId)
    if(self.bEnableReplicationMode) then
        OnActorPreCreated(self, pUEActor, nUniqueId, nServerInstanceId)
    else
        local tbGameObject = GameObjectSystem:FindByInstanceIdWithoutVerify(nServerInstanceId)
        if(tbGameObject) then
            GameObjectSystem:BindUEActor(tbGameObject, pUEActor)
            tbGameObject:OnActorPreCreated(pUEActor)
        end
    end
end

function ActorCppDelegateProcessor_C:OnPawnPostBeginPlay(pUEActor, nUniqueId, nInstanceId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    -- if(tbGameObject and tbGameObject.pUEActor == pUEActor and tbGameObject.bHasActorCreated) then
    --     log("ActorCppDelegateProcessor_C:OnPawnPostBeginPlay, ignore", nUniqueId, nServerInstanceId)
    --     return
    -- end

    if(tbGameObject) then
        EventManager:OnFireEvent(ClientEventDef.EV_GAME_OBJECT_BEGIN_PLAY, tbGameObject)
        tbGameObject:OnActorCreated(pUEActor)
    end

    if(self.bEnableReplicationMode) then
        local tbGamePlayerSelf = GamePlayerSelfHelper:Get()
        if(tbGamePlayerSelf:GetServerInstanceId() == nInstanceId) then
            tbGamePlayerSelf:VerifyReplicatedPlayerReady()
        end
    end
end

function ActorCppDelegateProcessor_C:OnPawnEndPlay(pUEActor, nUniqueId, nServerInstanceId)
    if(self.bEnableReplicationMode == false) then
        ActorCppDelegateProcessor_C.super.OnPawnEndPlay(self, pUEActor, nUniqueId, nServerInstanceId)
        return
    end

    -- 不知道有啥用，先屏蔽了试试
    -- local tbGamePlayerSelf = GamePlayerSelfHelper:Get()
    -- if(tbGamePlayerSelf == nil) then
    --     if(GWithEditor) then
    --         return
    --     end
    --     logerror("ActorCppDelegateProcessor_C:OnEndPlay failed, the player self is nil", nUniqueId)
    --     return
    -- end

    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if(tbGameObject == nil) then
        -- log("ActorCppDelegateProcessor_C:OnEndPlay ignore", nUniqueId)
        return
    end

    -- if(tbGamePlayerSelf.nUniqueId == nUniqueId) then
    --     log("ActorCppDelegateProcessor_C:OnEndPlay tbGamePlayerSelf", nUniqueId)
    --     GameObjectSystem:UnbindUEActor(tbGamePlayerSelf)
    -- else
        -- 先解绑在删掉逻辑对象
        log("ActorCppDelegateProcessor_C:OnEndPlay", nUniqueId, nServerInstanceId)
        GameObjectSystem:UnbindUEActor(tbGameObject, nUniqueId)

        if(GameObjectSystem:IsReadyToDestroy(tbGameObject)) then
            GameObjectSystem:DestroyByInstanceId(nServerInstanceId)
        end
    --end
end

local function OnEnterBattle(self)
    -- 只有客户端联网副本才听
    if(GlobalVariableSystem.bIsStandalone) then
        return
    end

    self.bEnableReplicationMode = true
    local CommonShell = CommonShell.GetCommon(GWorld)
    self.pDungeonCommonActorShell = CommonShell:GetCommonActorShell()

    local tbHandlers = {}
    self.tbDelegateHandlers = tbHandlers
    local DelegateMgr = CommonShell:GetGameDelegateManager().Actor
    table.insert(tbHandlers, self:RegisterMethod(DelegateMgr.OnControllerPreBeginPlay, self, OnControllerPreBeginPlay))
    table.insert(tbHandlers, self:RegisterMethod(DelegateMgr.OnControllerPostBeginPlay, self, OnControllerPostBeginPlay))
    table.insert(tbHandlers, self:RegisterMethod(DelegateMgr.OnControllerEndPlay, self, OnControllerEndPlay))
    table.insert(tbHandlers, self:RegisterMethod(DelegateMgr.OnActorChannelOpen, self, OnActorChannelOpen))
    table.insert(tbHandlers, self:RegisterMethod(DelegateMgr.OnActorDestroyed, self, OnActorDestroyed))
end

local function OnLeaveBattle(self)
    -- 只有客户端联网副本才听
    if(GlobalVariableSystem.bIsStandalone) then
        return
    end

    self.bEnableReplicationMode = false
    local tbHandlers = self.tbDelegateHandlers
    if(tbHandlers) then
        self.tbDelegateHandlers = nil
        for i, v in ipairs(tbHandlers) do
            self:Unregister(v)
        end
    end
end

function ActorCppDelegateProcessor_C:Init()
    ActorCppDelegateProcessor_C.super.Init(self)

    self.bEnableReplicationMode = false
    EventManager:BindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    EventManager:BindEventMethod(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveBattle)
end

function ActorCppDelegateProcessor_C:Uninit()
    EventManager:UnBindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    EventManager:UnBindEventMethod(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveBattle)

    ActorCppDelegateProcessor_C.super.Uninit(self)
end

return ActorCppDelegateProcessor_C
