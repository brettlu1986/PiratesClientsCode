local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorConsumeItem = luaclass("GameCorePacketProcessorConsumeItem", GameCorePacketProcessorAction)

local Proto  = require("GameCoreClientProtoNames")
local GameCoreActionActorType = require("GameCoreActionActorType")

GameCorePacketProcessorConsumeItem.ActorType = GameCoreActionActorType.All
-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorConsumeItem:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorConsumeItem:DoAction(tbPacket)
    local nItemId = tbPacket.itemid
    local tbGameObject = self.tbAgent:GetGameObject()
    if tbGameObject.ConsumableItemComponentServer and nItemId > 0 then
        tbGameObject.ConsumableItemComponentServer:ConsumeItemRequest(nItemId)
        self:ReportActionResult(Proto.ActionType.ConsumeItem, 0)
    else
        self:ReportActionResult(Proto.ActionType.ConsumeItem, 1)
    end
end


return GameCorePacketProcessorConsumeItem