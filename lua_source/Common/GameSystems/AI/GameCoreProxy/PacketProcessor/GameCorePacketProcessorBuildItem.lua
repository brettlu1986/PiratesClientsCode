local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorBuildItem = luaclass("GameCorePacketProcessorBuildItem", GameCorePacketProcessorAction)

local Proto  = require("GameCoreClientProtoNames")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleItemDataTable = require("BattleItemDataTable")
local GameCoreActionActorType = require("GameCoreActionActorType")

GameCorePacketProcessorBuildItem.ActorType = GameCoreActionActorType.All

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorBuildItem:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorBuildItem:DoAction(tbPacket)
    local tbGameObject  = self.tbAgent:GetGameObject()
    local nItemTemplateId, nSlotId = tbPacket.templateid, tbPacket.slotid
    local nOwnerInstanceId = tbGameObject.nServerInstanceId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nValidSlot = self:GetValidSlot(tbItemTemplate.nCategory, nSlotId)
    if tbItemTemplate then
        BattleItemSystemServer:BuildItem(nOwnerInstanceId, nItemTemplateId, nValidSlot)
        self:ReportActionResult(Proto.ActionType.BuildItem, 0)
        LOG("Action_BuildItem", nOwnerInstanceId, nItemTemplateId, nValidSlot)
    end
end


return GameCorePacketProcessorBuildItem