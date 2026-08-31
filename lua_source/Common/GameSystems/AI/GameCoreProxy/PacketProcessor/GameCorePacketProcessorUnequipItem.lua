local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorUnequipItem = luaclass("GameCorePacketProcessorUnequipItem", GameCorePacketProcessorAction)

local Proto           = require("GameCoreClientProtoNames")
local BattleItemSystemServer = require("BattleItemSystemServer")
local GameCoreActionActorType = require("GameCoreActionActorType")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorUnequipItem:", ...)
end
-- luacheck: pop

GameCorePacketProcessorUnequipItem.ActorType = GameCoreActionActorType.All

function GameCorePacketProcessorUnequipItem:DoAction(tbPacket)
    local tbGameObject = self.tbAgent:GetGameObject()
    local nItemId = tbPacket.item_id
    local nCharacterInstanceId = tbGameObject:GetServerInstanceId()
    BattleItemSystemServer:UnEquipItem(nCharacterInstanceId, nItemId)
    self:ReportActionResult(Proto.ActionType.UnequipItem, 0)
    LOG("unquip item:", nItemId)
end


return GameCorePacketProcessorUnequipItem