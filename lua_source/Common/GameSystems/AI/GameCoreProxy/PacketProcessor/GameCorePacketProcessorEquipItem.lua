local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorEquipItem = luaclass("GameCorePacketProcessorEquipItem", GameCorePacketProcessorAction)

local Proto           = require("GameCoreClientProtoNames")
local BattleItemSystemServer = require("BattleItemSystemServer")
local GameCoreActionActorType = require("GameCoreActionActorType")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorEquipItem:", ...)
end
-- luacheck: pop

GameCorePacketProcessorEquipItem.ActorType = GameCoreActionActorType.All

function GameCorePacketProcessorEquipItem:DoAction(tbPacket)
    local tbGameObject = self.tbAgent:GetGameObject()
    local nItemInstanceId = tbPacket.item_id
    local nSlot = tbPacket.slot
    local nOwnerInstanceId = tbPacket.owner_item_id
    local nCharacterInstanceId = tbGameObject:GetServerInstanceId()
    BattleItemSystemServer:EquipItem(nCharacterInstanceId, nOwnerInstanceId, nItemInstanceId, nSlot, true)
    self:ReportActionResult(Proto.ActionType.EquipItem, 0)
    LOG("equip item:", nItemInstanceId, nSlot, nOwnerInstanceId)
end


return GameCorePacketProcessorEquipItem