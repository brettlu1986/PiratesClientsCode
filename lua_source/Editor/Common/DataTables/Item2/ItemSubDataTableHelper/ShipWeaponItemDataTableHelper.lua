-----------------------------------------------------
--File Name    : ShipWeaponItemDataTableHelper.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-22
--Description  : Lobby中ShipWeaponItem配置表
-----------------------------------------------------
local ShipWeaponItemDataTableHelper = {}

function ShipWeaponItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nBattleItemId = Parser:Get("battle_item_id", -1, Parser.TypeInt)
    NewTemplate.nSourceType = Parser:Get("source_type", -1, Parser.TypeInt)
    NewTemplate.bDefaultOption = Parser:Get("default_option", false, Parser.TypeBool)
    -- NewTemplate.tbCharacteristic = Parser:Get("characteristic_id", {}, Parser.TypeArrayInt)
end

function ShipWeaponItemDataTableHelper.FillBattleItemIdToLobbyItemId(tbSubContainer, tbBattleItemIdToLobbyItemId)
    for nLobbyItemId, tbTemplate in pairs(tbSubContainer) do
        local nBattleItemId = tbTemplate.nBattleItemId
        tbBattleItemIdToLobbyItemId[nBattleItemId] = nLobbyItemId
    end
end

return ShipWeaponItemDataTableHelper