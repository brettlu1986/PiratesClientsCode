local luaclass = require("luaclass")
local CppDelegateProcesserBaseClass = require("CPPDelegateProcessorBase")
local PlayerCppDelegateProcessor = luaclass("PlayerCppDelegateProcessor", CppDelegateProcesserBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
-- local DestructiableObjectSystem = dynamic_require("DestructiableObjectSystem")
local BotAISystem = dynamic_require("BotAISystem")

-- function PlayerCppDelegateProcessor:OnPlayerControllerPostPossess(tbPlayerController, tbPawn)
-- end

-- This function will be called only when run as standalone mode
-- function PlayerCppDelegateProcessor:OnPossess(nPCUniqueId, nPawnUniqueId)
--     local tbPlayerController = BattleActorManager:FindBattleActor(nPCUniqueId)
--     if tbPlayerController == nil then
--         logerror("Cannot find PlayerController with UniqueId:", nPCUniqueId)
--     end
--     local tbPawn = BattleActorManager:FindBattleActor(nPawnUniqueId)
--     if tbPawn == nil then
--         logerror("Cannot find Pawn with UniqueId:", nPawnUniqueId)
--     end
--     if tbPlayerController ~= nil and tbPawn ~= nil then
--         tbPlayerController:OnPossess(tbPawn)
--         self:OnPlayerControllerPostPossess(tbPlayerController, tbPawn)
--     end
-- end

-- function PlayerCppDelegateProcessor:OnUnpossess(nPCUniqueId)
--     local tbPlayerController = BattleActorManager:FindBattleActor(nPCUniqueId)
--     if tbPlayerController == nil then
--         logerror("Cannot find PlayerController with UniqueId:", nPCUniqueId)
--     end
--     tbPlayerController:OnUnPossess()
-- end

function PlayerCppDelegateProcessor:OnBeginSpectating(nPCUniqueId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nPCUniqueId)
    if(tbGameObject == nil) then
        -- 这里因为客户端在beinplay前会下来这个，所以这里只是log下，beginplay后就应该有了
        --log("PlayerCppDelegateProcessor:OnBeginSpectating ignore object", nPCUniqueId)
        return
    end

    log("PlayerCppDelegateProcessor:OnBeginSpectating", nPCUniqueId)
    tbGameObject:OnBeginSpectating()
end

function PlayerCppDelegateProcessor:OnEndSpectating(nPCUniqueId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nPCUniqueId)
    if(tbGameObject == nil) then
        -- 这里因为客户端在beinplay前会下来这个，所以这里只是log下，beginplay后就应该有了
        log("PlayerCppDelegateProcessor:OnEndSpectating ignore object", nPCUniqueId)
        return
    end

    log("PlayerCppDelegateProcessor:OnEndSpectating", nPCUniqueId)
    tbGameObject:OnEndSpectating()
end

local function OnParachutingEnd(nUniqueId, bIsTransport, pTransportLocation)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if(tbGameObject == nil) then
        -- 这里因为客户端在beinplay前会下来这个，所以这里只是log下，beginplay后就应该有了
        log("PlayerCppDelegateProcessor:OnParachutingEnd ignore object", nUniqueId)
        return
    end

    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local pLocation = tbGameObject:GetLocation()
    local nRegionType = GridTypeManager:GetRegionType(pLocation.X, pLocation.Y)
    -- if bIsTransport then
    --     nRegionType = GridTypeManager:GetRegionType(pTransportLocation.X, pTransportLocation.Y)
    -- else
    --     nRegionType = GridTypeManager:GetRegionType(pLocation.X, pLocation.Y)
    -- end
    local bIsShip = false
    local bFalling = tbGameObject.pUEActor.CharacterMovement.MovementMode == EMovementMode.MOVE_Falling
    if BotAISystem:IsBot(tbGameObject) then
        bIsShip = nRegionType == EPiratesGridRegionType.Ocean
    else
        log("[parachuting] lua parachuting is ship: ", enumtoint(nRegionType), bFalling, enumtoint(tbGameObject.pUEActor.CharacterMovement.MovementMode))
        bIsShip = nRegionType == EPiratesGridRegionType.Ocean and bFalling and pLocation.Z <= 0
        
        if nRegionType == EPiratesGridRegionType.Ocean then
            if pLocation.Z > 0 then
                if not bFalling then 
                    local CharacterMovement = tbGameObject.pUEActor.CharacterMovement
                    if CharacterMovement then
                        local pFloorResult = CharacterMovement:K2_FindFloor(pLocation)
                        local pHitActor = pFloorResult.HitResult.Actor 
                        if isvalidhandle(pHitActor) then
                            log("[parachuting] lua parachuting end on ocean but not falling ", tbGameObject.nPlayerId,
                                KismetSystemLibrary.GetDisplayName(pHitActor)) 
                            local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pHitActor)
                            local tbHitObject = GameObjectSystem:FindByUniqueId(nUniqueID)
                            if tbHitObject then
                                log("[parachuting] lua parachuting end on ocean but not falling, hit on game object ", tbGameObject.nPlayerId, tbHitObject:GetObjectType())                        
                                bIsShip = true
                            end
                        end   
                    end
                else
                    if bIsTransport then
                        log("[parachuting] lua parachuting end on rock and teleport but z > 0 ")
                        bIsShip = true
                    end
                end
            elseif pLocation.Z <= 0 then
                log("[parachuting] lua parachuting end on ocean and z < 0", tbGameObject.nPlayerId)
                bIsShip = true
            end     
        end
    end
    log("[parachuting] lua parachuting end: ", tbGameObject.szName, tbGameObject.nPlayerId, bIsShip, bIsTransport, pLocation.X, pLocation.Y, pLocation.Z, pTransportLocation.X, pTransportLocation.Y)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_PARACHUTION_END, tbGameObject, bIsShip, bIsTransport, pTransportLocation)
end

local function OnParachutingReachSeaLevel(nUniqueId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if(tbGameObject == nil) then
        -- 这里因为客户端在beinplay前会下来这个，所以这里只是log下，beginplay后就应该有了
        log("PlayerCppDelegateProcessor:OnParachutingReachSealevel ignore object", nUniqueId)
        return
    end

    log("lua parachuting reach sea level")
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_PARACHUTING_REACH_SEALEAVEL, tbGameObject)
end

-- local function OnHitDestructibleObject(pDestructibleActor, nDamage, pDamageType)
--     if (pDestructibleActor == nil) then
--         log("PlayerCppDelegateProcessor:OnHitDestructibleObject ignore object")
--         return
--     end
--     log("OnHitDestructibleObject")
--     DestructiableObjectSystem:OnDestructibleObjectTakeDamage(pDestructibleActor, nDamage, pDamageType)
-- end

-- local function OnMeshChangedDestructibleObject(pDestructibleActor, nMeshIndex)
--     if (pDestructibleActor == nil) then
--         log("PlayerCppDelegateProcessor:OnMeshChangedDestructibleObject ignore object")
--         return
--     end
--     log("OnMeshChangedDestructibleObject")
--     DestructiableObjectSystem:OnDestructibleObjectMeshChange(pDestructibleActor, nMeshIndex)
-- end

local function OnAirDropEnd(nUniqueId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if(tbGameObject == nil) then
        log("PlayerCppDelegateProcessor_C:OnAirDropEnd", nUniqueId)
        return
    end
    local pLocation = tbGameObject:GetLocation()
    log("OnAirDropEnd: ", nUniqueId, tbGameObject:GetServerInstanceId(), pLocation.X, pLocation.Y, pLocation.Z)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_AIRDROP_END, tbGameObject)
end

local function OnDoorSwitched(nUniqueId, nCauserId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if(tbGameObject == nil) then
        log("PlayerCppDelegateProcessor_C:OnDoorSwitched", nUniqueId)
        return
    end
    log("OnDoorSwitched: ", nUniqueId, nCauserId)
    EventManager:OnFireEvent(CommonEventDef.EV_DOOR_SWITCHED, tbGameObject, nCauserId)
end

local function OnActorEnterTrigger(nOwnerUniqueId, nUniqueId)
    local tbOwnerGameObject = GameObjectSystem:FindByUniqueId(nOwnerUniqueId)
    if(tbOwnerGameObject == nil) then
        log("PlayerCppDelegateProcessor:OnActorEnterTrigger ignore owner object", nOwnerUniqueId)
        return
    end

    local tbEnterGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if(tbEnterGameObject == nil) then
        -- log("PlayerCppDelegateProcessor:OnActorEnterTrigger ignore enter object", nUniqueId)
        return
    end

    -- log("OnActorEnterTrigger ", tbOwnerGameObject.nPlayerId, nUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_PLAYER_ENTER_TRIGGER, tbOwnerGameObject, tbEnterGameObject)
end

local function OnActorLeaveTrigger(nOwnerUniqueId, nUniqueId)
    local tbOwnerGameObject = GameObjectSystem:FindByUniqueId(nOwnerUniqueId)
    if(tbOwnerGameObject == nil) then
        log("PlayerCppDelegateProcessor:OnActorLeaveTrigger ignore owner object", nOwnerUniqueId)
        return
    end

    local tbEnterGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if(tbEnterGameObject == nil) then
        -- log("PlayerCppDelegateProcessor:OnActorLeaveTrigger ignore enter object", nUniqueId)
        return
    end

    -- log("OnActorLeaveTrigger ", tbOwnerGameObject.nPlayerId, nUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_PLAYER_LEAVE_TRIGGER, tbOwnerGameObject, tbEnterGameObject)
end

function PlayerCppDelegateProcessor:Init()
    PlayerCppDelegateProcessor.super.Init(self)

    -- Register Gameplay Delegate
    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager()

    -- 有需求再开吧
    local Player = DelegateMgr.Player
    --self:RegisterMethod(Player.OnPossess, self, self.OnPossess)
    --self:RegisterMethod(Player.OnUnPossess, self, self.OnUnPossess)
    self:RegisterMethod(Player.OnBeginSpectating, self, self.OnBeginSpectating)
    self:RegisterMethod(Player.OnEndSpectating, self, self.OnEndSpectating)

    local GameMisc = DelegateMgr.GameMisc
    self:Register(GameMisc.OnParachutingEnd, OnParachutingEnd)
    self:Register(GameMisc.OnParachutingReachSeaLevel, OnParachutingReachSeaLevel)
    -- self:Register(GameMisc.OnHitDestructibleObject, OnHitDestructibleObject)
    -- self:Register(GameMisc.OnMeshChangedDestructibleObject, OnMeshChangedDestructibleObject)
    self:Register(GameMisc.OnAirDropEnd, OnAirDropEnd)
    self:Register(GameMisc.OnActorEnterTrigger, OnActorEnterTrigger)
    self:Register(GameMisc.OnActorLeaveTrigger, OnActorLeaveTrigger)
    self:Register(GameMisc.OnDoorSwitched, OnDoorSwitched)

    return true
end

return PlayerCppDelegateProcessor
