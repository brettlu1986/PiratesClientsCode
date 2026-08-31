local luaclass = require("luaclass")
local GOCustomDataHelper = luaclass("GOCustomDataHelper")

local GameComponentDataParser = dynamic_require("GameComponentDataParser")

function GOCustomDataHelper:ParsePlayerSelfControllerData(tbPlayerSelf, tbInOutInitProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParsePlayerSelfControllerData(tbPlayerSelf, tbInOutInitProtoData)
    return tbData
end

-- Gamemode创建玩家时
function GOCustomDataHelper:ParsePlayerSelfGameModeData(tbPrepareInfo, tbSpawnInfo, tbInOutInitProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParsePlayerSelfGameModeData(tbPrepareInfo, tbSpawnInfo, tbInOutInitProtoData)
    return tbData
end

-- Gamemode创建Npc时
function GOCustomDataHelper:ParseNpcGameModeData(tbSpawnInfo, tbInOutInitProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParseNpcGameModeData(tbSpawnInfo, tbInOutInitProtoData)
    return tbData
end

-- GameMode创建Trigger时
function GOCustomDataHelper:ParseTriggerGameModeData(tbSpawnInfo, tbInOutInitProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParseTriggerGameModeData(tbSpawnInfo, tbInOutInitProtoData)
    return tbData
end

-- GameMode创建Dummy时
function GOCustomDataHelper:ParseDummyGameModeData(nTemplateId, tbJsonData, tbInOutInitProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParseDummyGameModeData(nTemplateId, tbJsonData, tbInOutInitProtoData)
    return tbData
end

-- GameMode创建DestructibleObject时
function GOCustomDataHelper:ParseDestructibleObjectGameModeData(nTemplateId, tbJsonData, tbInOutInitProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParseDestructibleObjectGameModeData(nTemplateId, tbJsonData, tbInOutInitProtoData)
    return tbData
end

return GOCustomDataHelper
