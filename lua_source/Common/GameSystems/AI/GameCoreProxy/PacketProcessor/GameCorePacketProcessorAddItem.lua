local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorAddItem = luaclass("GameCorePacketProcessorAddItem", GameCorePacketProcessorAction)
local GameCoreActionActorType = require("GameCoreActionActorType")

local BattleItemSystemServer  = require("BattleItemSystemServer")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorAddItem:", ...)
end
-- luacheck: pop

GameCorePacketProcessorAddItem.ActorType = GameCoreActionActorType.All

function GameCorePacketProcessorAddItem:DoAction(tbPacket)
    local nServerInstanceId  = self.tbAgent:GetGameObject().nServerInstanceId
    local tbItems = tbPacket.items
    for i,v in ipairs(tbItems) do
        BattleItemSystemServer:AddItemByTemplate(nServerInstanceId ,v.id, v.num)
   end
end


return GameCorePacketProcessorAddItem