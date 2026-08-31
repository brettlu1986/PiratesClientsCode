local luaclass = require("luaclass")
local ParachutionSystem = luaclass("ParachutionSystem")
local SelfEventHelper = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local AIHelper = require("AIHelper")

ParachutionSystem.tbGameObjects = nil

local OFFSET_BORDER = 5000

local function VerifyObjectClosedBorder(tbGameObject)
    if tbGameObject == nil then
        return
    end

    -- local pLocation = tbGameObject:GetLocation()
    local nX, nY, nZ = EngineExtActorShell.GetActorLocationXYZ(tbGameObject.pUEActor)
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
    local nTempX = math.ceil(tbMapSize.GamePlayWidth / 2)
    local nTempY = math.ceil(tbMapSize.GamePlayHeight / 2)
    local nMinX = -nTempX
    local nMaxX = nTempX
    local nMinY = -nTempY
    local nMaxY = nTempY

    local bChange = false

    if nX - nMinX < OFFSET_BORDER then
        nX = nMinX + OFFSET_BORDER
        bChange = true
    elseif nMaxX - nX < OFFSET_BORDER then
        nX = nMaxX - OFFSET_BORDER
        bChange = true
    end

    if nY - nMinY < OFFSET_BORDER then
        nY = nMinY + OFFSET_BORDER
        bChange = true
    elseif nMaxY - nY < OFFSET_BORDER then
        nY = nMaxY - OFFSET_BORDER
        bChange = true
    end

    if bChange then
        log("too close mapsize:", nX, nY)
        tbGameObject:SetLocation(nX, nY, nZ)
    end
end

function ParachutionSystem:OnParachutionEnd(tbGameObject, bIsShip, bIsTransport, pTransportLocation)
    local bShouldSkipParachute = AIHelper:ShouldSkipParachute(tbGameObject)
    local nId = tbGameObject:GetServerInstanceId()
    -- if not bIsBot then
    if bIsTransport and pTransportLocation ~= nil then
        self.tbGameObjects[nId] = {nX = pTransportLocation.X, nY = pTransportLocation.Y, nZ = pTransportLocation.Z}
    else
        local nX, nY, nZ = tbGameObject:GetLocationXYZ()
        self.tbGameObjects[nId] = {nX = nX, nY = nY, nZ = nZ}
    end
    -- end
    if bIsShip then
        if not tbGameObject:IsDead() then
            local nShipId = tbGameObject:GetShipTemplateId()
            log("ParachutionSystem:OnParachutionEnd nshipid =", nShipId)
            if bIsTransport and bShouldSkipParachute then
                BattleGameModeSystem:GetGameMode():ChangeToShip(tbGameObject, nShipId, pTransportLocation)
            else
                VerifyObjectClosedBorder(tbGameObject)
                BattleGameModeSystem:GetGameMode():ChangeToShip(tbGameObject, nShipId)
            end
        else
            log("ParachutionSystem:OnParachutionEnd object is dead ", tbGameObject.nPlayerId, tbGameObject.szName)
        end
    else
        local CharacterMovement = tbGameObject.pUEActor.CharacterMovement
        CharacterMovement:SetStartTotalDistance(true)
        if bShouldSkipParachute then
            -- local pLocationTemp = ExtendBlueprintFunctions.GetAISafePosition(GWorld, pTransportLocation, 0, 20000, -20000)
            -- log("ParachutionSystem:OnParachutionEnd bot location ", tbGameObject.szName, pLocationTemp.X, pLocationTemp.Y, pLocationTemp.Z)
            CharacterMovement:TeleportHuman(pTransportLocation, 0, true, true)
            local nX, nY, nZ = EngineExtActorShell.GetActorLocationXYZ(tbGameObject.pUEActor)--tbGameObject:GetLocation()
            log("ParachutionSystem:OnParachutionEnd bot teleport ", tbGameObject.szName, nX, nY, nZ)
        else
            if bIsTransport then
                logerror("CharacterMovement:TeleportHuman:", pTransportLocation.X, pTransportLocation.Y, pTransportLocation.Z)
                CharacterMovement:TeleportHuman(pTransportLocation, 0, true, true)
            end
        end
    end
end

function ParachutionSystem:OnParachuteOpen(nUniqueId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if tbGameObject == nil then
        log("ParachutionSystem OpenParachute failed, not find object ", nUniqueId)
        return false
    end
    if tbGameObject.pUEActor == nil then
        logerror("ParachutionSystem OpenParachute failed, not find ueactor", nUniqueId)
        return false
    end
    if tbGameObject.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        logerror("ParachutionSystem OpenParachute failed, object is not playerself", nUniqueId)
        return false
    end
    if not isvalidhandle(tbGameObject.pUEActor.BPParachutingNew) then
        log("ParachutionSystem OpenParachute failed, not find bpParachuting")
        return false
    end
    tbGameObject.pUEActor.BPParachutingNew:Gliding(true)
    return true
end

function ParachutionSystem:OnHumanMovmentStateChanged(tbCharacter, nOldState, nNewState)

end

function ParachutionSystem:OnStartChangeDisplay(tbGameObject)
    if tbGameObject == nil or tbGameObject.pUEActor == nil then
        return
    end

    local nId = tbGameObject:GetServerInstanceId()
    if self.tbGameObjects[nId] == nil then
        return
    end

    self.EventHelper:FireEvent(CommonEventDef.EV_STATS_MOVEMENTDISTANCE, tbGameObject)
end

function ParachutionSystem:OnEndChangeDisplay(tbGameObject)
    if tbGameObject == nil or tbGameObject.pUEActor == nil then
        return
    end

    local nId = tbGameObject:GetServerInstanceId()
    if self.tbGameObjects[nId] == nil then
        return
    end

    if tbGameObject:IsHuman() then
        local CharacterMovement = tbGameObject.pUEActor.CharacterMovement
        if CharacterMovement then
            CharacterMovement:SetStartTotalDistance(true)
        end
    elseif tbGameObject:IsShip() then
        local ShipMovement = tbGameObject.pUEActor.ShipMovementComponent
        if ShipMovement then
            ShipMovement:SetStartTotalDistance(true)
        end
    end
end

function ParachutionSystem:GetPlayerLandingPoint(nInstanceId)
    return self.tbGameObjects and self.tbGameObjects[nInstanceId]
end

-- local function OnNewObjectCreate(self, tbGameObject)
--     local nId = tbGameObject:GetServerInstanceId()
--     local tbData = self.tbGameObjects[nId]
--     if tbData == nil then
--         return
--     end

--     self.tbGameObjects[nId] = nil

--     if not tbGameObject:IsShip() then
--         return
--     end

--     local correctPos = function(pStartLocation, pEndLocation)
--         local pForwardVector = KismetMathLibrary.Subtract_VectorVector(pEndLocation, pStartLocation)
--         local pNormalForwardVector = KismetMathLibrary.Normal(pForwardVector, GDefaultTolerance)
--         local pLocationDelta = KismetMathLibrary.Multiply_VectorFloat(pNormalForwardVector, OFFSET_BORDER)
--         local pOffsetLocation = KismetMathLibrary.Add_VectorVector(pEndLocation, pLocationDelta)
--         tbGameObject:SetLocation(pOffsetLocation.X, pOffsetLocation.Y, pOffsetLocation.Z)
--     end

--     local pStartLocation = tbGameObject:GetLocation()
--     local pEndLocation = tbData
--     local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
--     local nRegionType = GridTypeManager:GetRegionType(pStartLocation.X, pStartLocation.Y)
--     local bIsOcean =  nRegionType == EPiratesGridRegionType.Ocean or nRegionType == EPiratesGridRegionType.Port
--     log("parachuting close to island", bIsOcean, pStartLocation.X, pStartLocation.Y, tbData.X, tbData.Y)
--     if not bIsOcean then
--         if pStartLocation.X ~= pEndLocation.X or pStartLocation.Y ~= pEndLocation.Y then
--             correctPos(pStartLocation, pEndLocation)
--             log("parachuting ship on island and change location")
--         end
--     else
--         local bHit, pHitResult = KismetSystemLibrary.SphereTraceSingleForObjects(GWorld,
--             Vector{X=pStartLocation.X, Y=pStartLocation.Y, Z=pStartLocation.Z + 10000},
--             pStartLocation,
--             OFFSET_BORDER,
--             {ECollisionChannel.ECC_EngineTraceChannel3},
--             false,
--             {},
--             EDrawDebugTrace.None,
--             true,
--             KMUMGLibrary.GetLinearColor(1.0, 1.0, 1.0, 1.0),
--             KMUMGLibrary.GetLinearColor(1.0, 1.0, 1.0, 1.0),
--             0)

--         if bHit then
--             local pTemp = pHitResult.ImpactPoint
--             local pHitLocation = Vector{X = pTemp.X, Y = pTemp.Y, Z = pStartLocation.Z}
--             log("parachuting ship close island and change location", pHitLocation.X, pHitLocation.Y, pStartLocation.X, pStartLocation.Y)
--             correctPos(pHitLocation, pStartLocation)
--         end
--     end
-- end

function ParachutionSystem:Init()
	local EventHelper = SelfEventHelper()
	EventHelper:RegisterEvent(CommonEventDef.EV_FFA_PARACHUTION_END, self, self.OnParachutionEnd)
	EventHelper:RegisterEvent(CommonEventDef.EV_FFA_PARACHUTE_OPEN, self, self.OnParachuteOpen)
    -- EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnNewObjectCreate)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, self.OnHumanMovmentStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_START_CHANGEDISPLAY, self, self.OnStartChangeDisplay)
    EventHelper:RegisterEvent(CommonEventDef.EV_END_CHANGEDISPLAY, self, self.OnEndChangeDisplay)

    self.EventHelper = EventHelper

    self.tbGameObjects = {}

    return true
end

function ParachutionSystem:Uninit()
    if self.EventHelper ~= nil then
    	self.EventHelper:UnregisterAll()
    end
    self.tbGameObjects = nil
end

return ParachutionSystem