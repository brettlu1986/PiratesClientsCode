local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorDropItem = luaclass("GameCorePacketProcessorDropItem", GameCorePacketProcessorAction)

local Proto  = require("GameCoreClientProtoNames")
local BattleItemSystemServer = require("BattleItemSystemServer")
local GameCoreActionActorType = require("GameCoreActionActorType")

GameCorePacketProcessorDropItem.ActorType = GameCoreActionActorType.All

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorDropItem:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorDropItem:DoAction(tbPacket)
    local nItemId = tbPacket.itemid
    local nCount = tbPacket.count
    local nCharacterInstanceId = self.tbAgent:GetGameObject():GetServerInstanceId()
    BattleItemSystemServer:ThrowAwayItem(nCharacterInstanceId, nItemId, nCount)
    self:ReportActionResult(Proto.ActionType.DropItem, 0)
end


return GameCorePacketProcessorDropItem