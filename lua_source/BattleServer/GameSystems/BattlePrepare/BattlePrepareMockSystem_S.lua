local luaclass = require("luaclass")
local BattlePrepareMockSystemClass = require("BattlePrepareMockSystem")
local BattlePrepareMockSystem_S = luaclass("BattlePrepareMockSystem_S", BattlePrepareMockSystemClass)

local NetPlayerManager = require("NetPlayerManager_S")

function BattlePrepareMockSystem_S:OnMockPlayerData(nPlayerId, szPlayerName)
    BattlePrepareMockSystem_S.super.OnMockPlayerData(self, nPlayerId, szPlayerName)
    NetPlayerManager:RegisterPlayer(0, nPlayerId)
end

return BattlePrepareMockSystem_S()