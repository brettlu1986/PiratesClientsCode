local luaclass = require("luaclass")
local DestructibleObjectInteractionalSystem = luaclass("DestructibleObjectInteractionalSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SelfEventHelper = require("SelfEventHelper")

DestructibleObjectInteractionalSystem.tbBombs = nil

local function IsInRange(nX1, nY1, nX2, nY2, nSqureRadius)
    local nX, nY = nX1 - nX2, nY1 - nY2
    return nX * nX + nY * nY <= nSqureRadius
end

local function OnBombTriggerCreated(self, nCauserId, nBuffId, nBombId, pLocation, nRadius)
    local nTriggerX, nTriggerY = pLocation.X, pLocation.Y
    local nSqureRadius = nRadius * nRadius
    local nX, nY

    local tbBombRangeObjs = {}
    local bInRange = false

    local tbRealCauser = GameObjectSystem:FindByInstanceId(nCauserId)

    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.DestructibleObject)
    for v, _ in pairs(tbObjects) do
        if isvalidhandle(v.pUEActor) then 
            nX, nY = v:GetLocationXYZ()
            if IsInRange(nX, nY, nTriggerX, nTriggerY, nSqureRadius) then
                tbBombRangeObjs[v:GetServerInstanceId()] = nBuffId
                -- add buf
                v.BuffComponentServer:AddBuffWithInstigator(tbRealCauser, nBuffId, 1, 1)

                bInRange = true
            end
        end
    end

    if bInRange then
        self.tbBombs[nBombId] = tbBombRangeObjs
    end
end

local function OnBombTriggerPreDestroy(self, nBombId)
    local tbBombRangeObjs = self.tbBombs[nBombId]
    if tbBombRangeObjs == nil then
        return
    end

    for nInstanceId, nBuffId in pairs(tbBombRangeObjs) do
        -- remove buf
        local tbObject = GameObjectSystem:FindByInstanceId(nInstanceId)
        if tbObject ~= nil then
            tbObject.BuffComponentServer:RemoveBuffById(nBuffId)
        end
    end
end

function DestructibleObjectInteractionalSystem:Init()
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper

    self.tbBombs = {}

    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager()
    local GameMisc = DelegateMgr.GameMisc
    EventHelper:RegisterCppDelegate(GameMisc.OnBombTriggerCreated, self, OnBombTriggerCreated)
    EventHelper:RegisterCppDelegate(GameMisc.OnBombTriggerPreDestroy, self, OnBombTriggerPreDestroy)
    
    return true
end

function DestructibleObjectInteractionalSystem:Uninit()
    if self.EventHelper ~= nil then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end

    for k, v in pairs(self.tbBombs) do
        OnBombTriggerPreDestroy(self, k)
    end
    self.tbBombs = nil
end

function DestructibleObjectInteractionalSystem:OnRecvSwitchDoor(tbPacket, nCauserId)
    local tbGameDoor = GameObjectSystem:FindByInstanceId(tbPacket.nInstanceId)
    if tbGameDoor == nil then
        log("Request SwitchDoor but door is break:", tbPacket.nInstanceId)
        return
    end
    if tbGameDoor.pUEActor == nil then
        log("Request SwitchDoor but door actor is nil:", tbPacket.nInstanceId)
        return
    end 
    tbGameDoor.pUEActor:SwitchDoor(tbPacket.nState, nCauserId)
end

return DestructibleObjectInteractionalSystem()