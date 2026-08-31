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
local BotGroupDataTable = {}

local BotTemplateDataTable = require("BotTemplateDataTable")

BotGroupDataTable.szFileName = "common/ffa/ai/bot/bot_group.tab"

function BotGroupDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nGroupId")
    Parser:Define("nGroupId", "group_id", -1, Parser.TypeInt)
    Parser:Define("nBotTemplateId1",  "bot_template_id1", -1, Parser.TypeInt)
    Parser:Define("nWeight1",  "weight1", -1, Parser.TypeInt)
    Parser:Define("nBotTemplateId2",  "bot_template_id2", -1, Parser.TypeInt)
    Parser:Define("nWeight2",  "weight2", -1, Parser.TypeInt)
    Parser:Define("nBotTemplateId3",  "bot_template_id3", -1, Parser.TypeInt)
    Parser:Define("nWeight3",  "weight3", -1, Parser.TypeInt)
    Parser:Define("nBotTemplateId4",  "bot_template_id4", -1, Parser.TypeInt)
    Parser:Define("nWeight4",  "weight4", -1, Parser.TypeInt)
    Parser:Define("nBotTemplateId5",  "bot_template_id5", -1, Parser.TypeInt)
    Parser:Define("nWeight5",  "weight5", -1, Parser.TypeInt)
end

local function AddBotData(tbNewTemplate, tbBotList, nBotTemplateId, nWeight)
    if nBotTemplateId > 0 and nWeight <= 0 then
        error("bot weight less than 0!".. tbNewTemplate.nGroupId)
    end
    if nBotTemplateId > 0 and nWeight > 0 then
        if BotTemplateDataTable:GetTemplate(nBotTemplateId) ==  nil then
            error("Cannot find bot template!".."groupId:"..tbNewTemplate.nGroupId..", templateid:"..nBotTemplateId)
        end
        local tbBotData = {}
        tbBotData.nBotTemplateId = nBotTemplateId
        tbBotData.nWeight = nWeight
        table.insert(tbBotList, tbBotData)
        return nWeight
    end
    return 0
end

function BotGroupDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbBotList = {}
    local nTotalWeight = 0
    nTotalWeight = nTotalWeight + AddBotData(tbNewTemplate, tbBotList, tbNewTemplate.nBotTemplateId1, tbNewTemplate.nWeight1)
    nTotalWeight = nTotalWeight + AddBotData(tbNewTemplate, tbBotList, tbNewTemplate.nBotTemplateId2, tbNewTemplate.nWeight2)
    nTotalWeight = nTotalWeight + AddBotData(tbNewTemplate, tbBotList, tbNewTemplate.nBotTemplateId3, tbNewTemplate.nWeight3)
    nTotalWeight = nTotalWeight + AddBotData(tbNewTemplate, tbBotList, tbNewTemplate.nBotTemplateId4, tbNewTemplate.nWeight4)
    nTotalWeight = nTotalWeight + AddBotData(tbNewTemplate, tbBotList, tbNewTemplate.nBotTemplateId5, tbNewTemplate.nWeight5)
    if #tbBotList == 0 or nTotalWeight <= 0 then
        error("Cannot find any bot!".. tbNewTemplate.nGroupId)
    end
    tbNewTemplate.tbBotList = tbBotList
    tbNewTemplate.nTotalWeight = nTotalWeight
    return true
end

-- [EXPORT BEGIN]
-- 获得bot随机的类型和数量列表
-- @param nGroupId 随机组id
-- @param nBotTotalCount bot总数
-- @return tbBotDatas bot的类型和数量列表
-- local tbBotDatas = {}
-- local tbBotData = {}
-- tbBotData.nBotTemplateId = 1
-- tbBotData.nCount = 10
-- table.insert(tbBotDatas, tbBotData)
function BotGroupDataTable:GetBotDatas(nGroupId, nBotTotalCount)
    local tbTemplate = self.tbContainer[nGroupId]
    if tbTemplate == nil then
        error("Cannot find bot groupid!"..nGroupId)
    end
    local tbBotList = tbTemplate.tbBotList
    local nTotalWeight = tbTemplate.nTotalWeight
    local tbBotDatas = {}
    local nTempCount = 0
    local nLength = #tbBotList
    for i, v in ipairs(tbBotList) do
        local nBotTemplateId = v.nBotTemplateId
        local nCount = 0
        if i == nLength then
            nCount = nBotTotalCount - nTempCount
        else
            local nWeight = v.nWeight
            nCount = math.floor(nBotTotalCount * nWeight / nTotalWeight)
        end
        if nCount > 0 then
            local tbBotData = {}
            tbBotData.nBotTemplateId = nBotTemplateId
            tbBotData.nCount = nCount
            nTempCount = nTempCount + nCount
            table.insert(tbBotDatas, tbBotData)
        end
        if nTempCount > nBotTotalCount then
            error("Random Error! count is more than total count!".. nGroupId..", total count:"..nBotTotalCount, ", count:"..nTempCount)
        end
        if nTempCount == nBotTotalCount then
            break
        end
    end
    return tbBotDatas
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BotGroupDataTable:IsExist(nGroupId)
    return self.tbContainer[nGroupId] ~= nil
end
-- [EXPORT END]

return BotGroupDataTable