local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorSpawnItem = luaclass("GameCorePacketProcessorSpawnItem", GameCorePacketProcessorBase)

local BattleItemSystemServer = require("BattleItemSystemServer")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorSpawnItem:", ...)
end
-- luacheck: pop

function GameCorePacketProcessorSpawnItem:Process(tbPacket)
    local tbinfo = tbPacket
    local tbSceneItemData = {}
    tbSceneItemData.tbTransform = {X=tbinfo.x,Y=tbinfo.y,Z=tbinfo.z,Yaw=0}
    tbSceneItemData.tbItemInfos = {}
    local tbItemInfo = {}
    tbItemInfo.nItemTemplateId = tbinfo.templateid
    tbItemInfo.nItemCount = tbinfo.count > 0 and tbinfo.count or 1
    table.insert(tbSceneItemData.tbItemInfos,tbItemInfo)
    BattleItemSystemServer:AddItemsToScene(tbSceneItemData)
end



return GameCorePacketProcessorSpawnItem