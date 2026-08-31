local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorHello = luaclass("GameCorePacketProcessorHello", GameCorePacketProcessorBase)

local Proto                         = require("GameCoreClientProtoNames")
local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local SceneResDataTable = require("SceneResDataTable")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorHello:", ...)
end
-- luacheck: pop

function GameCorePacketProcessorHello:Process(tbPacket)
    local tbWelcomePacket = { }
    tbWelcomePacket.dungeonid = BattleGameModeSystem.nDungeonId
    local tbDungeonTemplateData = BattleGameModeSystem:GetDungeonTemplateData()
    local szMapName = SceneResDataTable:GetTemplate(tbDungeonTemplateData.nResID).szMapName
    tbWelcomePacket.mapname = szMapName
    self.tbGameCoreProxyClient:Send(Proto.c2s_welcome, tbWelcomePacket)
    log("send welcome ", BattleGameModeSystem.nDungeonId, szMapName)
end



return GameCorePacketProcessorHello