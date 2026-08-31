-----------------------------------------------------
--File Name    : ShipPartItemDataTableHelper.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-22
--Description  : Lobby中ShipPartItem配置表
-----------------------------------------------------
local ShipPartItemDataTableHelper = {}

function ShipPartItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.tbBattleItemIdList = Parser:Get("battle_item_id_list", -1, Parser.TypeArrayInt)
    NewTemplate.nSourceType = Parser:Get("source_type", -1, Parser.TypeInt)
    NewTemplate.szModelRes = Parser:Get("model_res", nil, Parser.TypeString)
    NewTemplate.szClassRes = Parser:Get("class_res", nil, Parser.TypeString)
    NewTemplate.bDefaultOption = Parser:Get("default_option", false, Parser.TypeBool)
end

function ShipPartItemDataTableHelper.FillBattleItemIdToLobbyItemId(tbSubContainer, tbBattleItemIdToLobbyItemId)
    for nLobbyItemId, tbTemplate in pairs(tbSubContainer) do
        local tbBattleItemIdList = tbTemplate.tbBattleItemIdList
        for _, v in ipairs(tbBattleItemIdList) do
            tbBattleItemIdToLobbyItemId[v] = nLobbyItemId
        end
    end
end

return ShipPartItemDataTableHelper