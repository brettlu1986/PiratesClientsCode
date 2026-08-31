-- 发现鱼类在附近

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleTorpedoDiscoveryTarget = luaclass("BattleTorpedoDiscoveryTarget", BattleTargetBaseClass)

local Timer = require("Timer")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local ShipUtilityHelper     = require("ShipUtilityHelper")

BattleTorpedoDiscoveryTarget.Timer = nil
BattleTorpedoDiscoveryTarget.nRange = 0
local CHECK_TIME = 2

function BattleTorpedoDiscoveryTarget:Init()
    BattleTorpedoDiscoveryTarget.super.Init(self)
    self.szName = "BattleTorpedoDiscoveryTarget"
end

function BattleTorpedoDiscoveryTarget:Parse(tbJsonData)
    self.nRange = tbJsonData.Range
    return true
end

function BattleTorpedoDiscoveryTarget:CheckTorpedo()
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if Object.ObjectType == GameObjectTypeDef.PlayerSelf then
            local pShip = Object.pUEActor
            local bResult = ShipUtilityHelper.CheckExistTorpedoInTheNear(pShip, self.nRange, GWorld)
            if bResult then 
                self:Complete()
            end
            return
        end
    end
    return
end

function BattleTorpedoDiscoveryTarget:RegisterEvent()

    self.Timer = Timer.NewTimerMethod(self, self.CheckTorpedo, CHECK_TIME, true)

end

function BattleTorpedoDiscoveryTarget:UnregisterEvent()
    if(self.Timer) then
        self.Timer:Clear()
        self.Timer = nil
    end
end

return BattleTorpedoDiscoveryTarget
