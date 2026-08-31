-- 直接结束的Target

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerSelfShipStatusTarget = luaclass("BattlePlayerSelfShipStatusTarget", BattleTargetBaseClass)

-- local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BrokenTypeDef = require("BrokenTypeDef")

local STATE_TYPE = {}
STATE_TYPE["Fire"] = BrokenTypeDef.TYPE_FIRE_SPOT
STATE_TYPE["Leak"] = BrokenTypeDef.TYPE_LEAK_SPOT

BattlePlayerSelfShipStatusTarget.nType = nil
BattlePlayerSelfShipStatusTarget.bStatus = nil

function BattlePlayerSelfShipStatusTarget:Init()
    BattlePlayerSelfShipStatusTarget.super.Init(self)
    self.szName = "BattlePlayerSelfShipStatusTarget"
end

-- local function OnBrokenStatusChanged(self, nType, pBrokenComponent, bStatus, nTime)
--     if(nType == self.nType and bStatus == self.bStatus) then
--         self:Complete()
--     end
-- end

local function BindPlayerEvent(self, tbGamePlayer)
    -- local ShipBrokenStatusComponent = tbGamePlayer.ShipBrokenStatusComponent
    
    -- if(ShipBrokenStatusComponent == nil) then
    --     BattleOperationHelper:PrintError(self, "ShipBrokenStatusComponent is nil")
    --     return false
    -- end
    
    -- ShipBrokenStatusComponent.OnBrokenStatusChangedDelegate:Bind(OnBrokenStatusChanged, self)
    return true
end

local function UnbindPlayerEvent(self, tbGamePlayer)
    -- local ShipBrokenStatusComponent = tbGamePlayer.ShipBrokenStatusComponent
    -- if(ShipBrokenStatusComponent ~= nil) then
    --     ShipBrokenStatusComponent.OnBrokenStatusChangedDelegate:Unbind(OnBrokenStatusChanged, self)
    -- end
end

function BattlePlayerSelfShipStatusTarget:RegisterEvent()
    local ObjectType = GameObjectTypeDef.PlayerSelf
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if(Object.ObjectType == ObjectType) then
            BindPlayerEvent(self, Object)
        end
    end

    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, BindPlayerEvent)
end

function BattlePlayerSelfShipStatusTarget:UnregisterEvent()
    local ObjectType = GameObjectTypeDef.PlayerSelf
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if(Object.ObjectType == ObjectType) then
            UnbindPlayerEvent(self, Object)
        end
    end

    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, BindPlayerEvent)
end

function BattlePlayerSelfShipStatusTarget:Parse(tbJsonData)
    self.nType = STATE_TYPE[tbJsonData.Type]
    self.bStatus = tbJsonData.WhenRemoved == false
    return self.nType ~= nil
end

return BattlePlayerSelfShipStatusTarget