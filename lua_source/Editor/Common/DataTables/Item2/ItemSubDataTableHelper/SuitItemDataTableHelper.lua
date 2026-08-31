-----------------------------------------------------
--File Name    : SuitItemDataTableHelper.lua
--Author       : WuJizhou
--Create Time  : 2020-09-27
--Description  : 时装的配置表读取helper
-----------------------------------------------------
local SuitItemDataTableHelper = {}

function SuitItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.tbSubItemTemplateIds    = Parser:Get("part_id",         {},     Parser.TypeArrayInt)
    NewTemplate.nFashionType            = Parser:Get("fashion_type",    -1,     Parser.TypeInt)
    NewTemplate.tbEffects               = Parser:Get("effect",          {},     Parser.TypeArrayInt)
    NewTemplate.nSourceType             = Parser:Get("source_type",     -1,     Parser.TypeInt)
end

function SuitItemDataTableHelper.OnEditorParseFinished(tbSelfCategoryTemplates, tbOutBlackboardData)
    local tbFashionToSuit = {}
    for nTemplateId, tbTemplate in pairs(tbSelfCategoryTemplates) do
        local tbSubItemTemplateIds = tbTemplate.tbSubItemTemplateIds
        for _, nFashionItemTemplateId in ipairs(tbSubItemTemplateIds) do
            tbFashionToSuit[nFashionItemTemplateId] = nTemplateId
        end
    end
    tbOutBlackboardData.tbFashionToSuit = tbFashionToSuit
end

return SuitItemDataTableHelper