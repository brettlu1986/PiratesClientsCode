--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local NpcInitItemRandomDataTable = {}

local BattleItemDataTable = require("BattleItemDataTable")

NpcInitItemRandomDataTable.szFileName = "common/npc/dungeon/npc_init_item_random.tab"

local function CheckItemValid(nGroupId, nItemTemplateId)
    if nItemTemplateId > 0 then
        local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        if tbItemTemplate == nil then
            error("CheckItemValid failed! tbItemTemplate is nil! nGroupId:"..nGroupId ..", nItemTemplateId:"..nItemTemplateId)
        end
    end
end

function NpcInitItemRandomDataTable:OnEditorDefine(Parser)
    Parser:Define("nGroupId", "group_id", -1, Parser.TypeInt)
    Parser:Define("nRandomGroupId", "random_group_id", 0, Parser.TypeInt)
    Parser:Define("nRandomWeight", "random_weight", -1, Parser.TypeInt)
    Parser:Define("nItemTemplateId1", "item_template_id1", -1, Parser.TypeInt)
    Parser:Define("nItemCount1", "item_count1", -1, Parser.TypeInt)
    Parser:Define("nItemTemplateId2", "item_template_id2", -1, Parser.TypeInt)
    Parser:Define("nItemCount2", "item_count2", -1, Parser.TypeInt)
end

function NpcInitItemRandomDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nGroupId = tbNewTemplate.nGroupId
    local nRandomGroupId = tbNewTemplate.nRandomGroupId
    local bNeedRandom = false
    if nRandomGroupId > 0 then
        bNeedRandom = true
    end

    CheckItemValid(nGroupId, tbNewTemplate.nItemTemplateId1)
    CheckItemValid(nGroupId, tbNewTemplate.nItemTemplateId2)

    local tbGroupTemplates = tbContainer[nGroupId]
    if not tbGroupTemplates then
        tbGroupTemplates = {}
        tbContainer[nGroupId] = tbGroupTemplates
    end
    local tbNeedRandomTemplates = tbGroupTemplates[bNeedRandom]
    if not tbNeedRandomTemplates then
        tbNeedRandomTemplates = {}
        tbGroupTemplates[bNeedRandom] = tbNeedRandomTemplates
    end
    if bNeedRandom then
        local tbRandomTemplates = tbNeedRandomTemplates[nRandomGroupId]
        if not tbRandomTemplates then
            tbRandomTemplates = {}
            tbNeedRandomTemplates[nRandomGroupId] = tbRandomTemplates
        end
        table.insert(tbRandomTemplates, tbNewTemplate)
    else
        table.insert(tbNeedRandomTemplates, tbNewTemplate)
    end
    return true
end

-- [EXPORT BEGIN]
local function AddItemToResultList(tbRandomItems, nItemTemplateId, nItemCount)
    if nItemTemplateId > 0 then
        local tbRandomItem = {}
        tbRandomItem.nItemTemplateId = nItemTemplateId
        tbRandomItem.nItemCount = nItemCount
        table.insert(tbRandomItems, tbRandomItem)
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
local function RandomGroup(tbRandomItems, tbRandomGroupTemplates)
    local nTotalWeight = 0
    for _, v in ipairs(tbRandomGroupTemplates) do
        nTotalWeight = nTotalWeight + v.nRandomWeight
    end
    local nRandomResult = math.random(1, nTotalWeight)
    local nWeightCount = 0
    for _, v in ipairs(tbRandomGroupTemplates) do
        if nRandomResult > nWeightCount and nRandomResult <= nWeightCount + v.nRandomWeight then
            AddItemToResultList(tbRandomItems, v.nItemTemplateId1, v.nItemCount1)
            AddItemToResultList(tbRandomItems, v.nItemTemplateId2, v.nItemCount2)
            return
        end
        nWeightCount = nWeightCount + v.nRandomWeight
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function NpcInitItemRandomDataTable:GetRandomItems(nGroupId)
    local tbGroupTemplates = self.tbContainer[nGroupId]
    if tbGroupTemplates == nil then
        error("NpcInitItemRandomDataTable:GetRandomItems failed, nGroupId:".. nGroupId)
    end
    local tbRandomItems = {}
    for k, v in pairs(tbGroupTemplates) do
        if k then  -- bNeedRandom
            for _, tbRandomGroupTemplates in pairs(v) do
                RandomGroup(tbRandomItems, tbRandomGroupTemplates)
            end
        else
            for _, tbTemplate in ipairs(v) do
                AddItemToResultList(tbRandomItems, tbTemplate.nItemTemplateId1, tbTemplate.nItemCount1)
                AddItemToResultList(tbRandomItems, tbTemplate.nItemTemplateId2, tbTemplate.nItemCount2)
            end
        end
    end
    return tbRandomItems
end
-- [EXPORT END]

return NpcInitItemRandomDataTable
