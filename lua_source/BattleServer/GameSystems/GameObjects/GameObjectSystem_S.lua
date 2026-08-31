local luaclass = require("luaclass")
local GameObjectSystem = require("GameObjectSystem")
local GameObjectSystem_S = luaclass("GameObjectSystem_S", GameObjectSystem)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")

local function MulticastDestroyPacket(nInstanceId)
    NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_DestroyGameObject, {instance_id = nInstanceId}, false)
end

function GameObjectSystem_S:DestroyPlayerSelfInGameMode(nServerInstanceId)
    GameObjectSystem_S.super.DestroyPlayerSelfInGameMode(self, nServerInstanceId)
    MulticastDestroyPacket(nServerInstanceId)
end

function GameObjectSystem_S:DestroyNpcInGameMode(nUniqueId)
    local tbGameObject = self:FindByUniqueId(nUniqueId)
    if(not tbGameObject) then
        return
    end
    local nInstanceId = tbGameObject:GetServerInstanceId()
    GameObjectSystem_S.super.DestroyNpcInGameMode(self, nUniqueId)
    MulticastDestroyPacket(nInstanceId)
end

function GameObjectSystem_S:DestroyNpcInGameModeByInstanceId(nInstanceId)
    GameObjectSystem_S.super.DestroyNpcInGameModeByInstanceId(self, nInstanceId)
    MulticastDestroyPacket(nInstanceId)
end

return GameObjectSystem_S()