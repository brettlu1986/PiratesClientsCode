-----------------------------------------------------
--File Name    : LobbyShipItemDataTableHelper.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-22
--Description  : Lobby中ShipItem配置表
-----------------------------------------------------
local LobbyShipItemDataTableHelper = {}

function LobbyShipItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nLevel = Parser:Get("level", -1, Parser.TypeInt)
    NewTemplate.nBattleItemId = Parser:Get("battle_item_id", -1, Parser.TypeInt)
    NewTemplate.bDefaultEquipped = Parser:Get("default_equipped", false, Parser.TypeBool)
    NewTemplate.bDefaultUnlocked = Parser:Get("default_unlocked", false, Parser.TypeBool)
    NewTemplate.nSortIndex = Parser:Get("sort_index", -1, Parser.TypeInt)
    NewTemplate.nSourceType = Parser:Get("source_type", -1, Parser.TypeInt)
end

function LobbyShipItemDataTableHelper.FillBattleItemIdToLobbyItemId(tbSubContainer, tbBattleItemIdToLobbyItemId)
    for nLobbyItemId, tbTemplate in pairs(tbSubContainer) do
        local nBattleItemId = tbTemplate.nBattleItemId
        tbBattleItemIdToLobbyItemId[nBattleItemId] = nLobbyItemId
    end
end

return LobbyShipItemDataTableHelper