
local BuildHumanArmorTipsContentHelper = {}

local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local DescKeyParser = require("DescKeyParser")
local DescKeyParserMiscDef = require("DescKeyParserMiscDef")


local DESC_KEYS =
{
    "dungeon_general_desc",
    "dungeon_special_desc",
    "dungeon_reduce_desc",
}

local function GetKeyList(tbItemTemplate)
    return DESC_KEYS
end

-- tbTipsData.szTitle
-- tbTipsData.szDesc
function BuildHumanArmorTipsContentHelper.GetTipsData(nItemTemplateId)
    local tbTipsData = {}
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    assert(nCategory == BattleItemCategoryDef.HUMAN_ARMOR, "error! category not human armor!".. nItemTemplateId)
    tbTipsData.szTitle = tbItemTemplate.l10nName
    tbTipsData.tbCharacteristics = {}
    local tbDatas = {}
    local tbInputData = {}
    tbInputData.nItemTemplateId = nItemTemplateId
    local tbKeys = GetKeyList(tbItemTemplate)
    for _, szKey in ipairs(tbKeys) do
        local tbOutData = DescKeyParser.GetParseData(DescKeyParserMiscDef.NAME_SPACE_HUMAN_ARMOR, szKey, tbInputData)
        if tbOutData.bList then
            for _, l10nData in ipairs(tbOutData.tbDatas) do
                local tbData = {}
                tbData.szTitle = l10nData
                table.insert(tbDatas, tbData)
            end
        else
            local tbData = {}
            tbData.szTitle = tbOutData.l10nData
            table.insert(tbDatas, tbData)
        end
    end
    tbTipsData.tbDatas = tbDatas

    return tbTipsData
end

return BuildHumanArmorTipsContentHelper
