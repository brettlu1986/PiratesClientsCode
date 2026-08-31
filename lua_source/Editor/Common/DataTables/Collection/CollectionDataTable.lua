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
local CollectionDataTable = {}

CollectionDataTable.szFileName = "common/collection/collection.tab"

function CollectionDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nTypeId")
    Parser:Define("nTypeId", "type_id", -1, Parser.TypeInt)
    Parser:Define("nResId", "res_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function CollectionDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function CollectionDataTable:GetCollectionResData(nTemplateId)
    local tbTemplate = self:GetTemplate(nTemplateId)
    if(tbTemplate) then
        return tbTemplate.tbResData
    end
    return nil
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function CollectionDataTable:OnGameRequired()
    local CollectionResDataTable = require("CollectionResDataTable")
    local tbContainer = self.tbContainer
    for k,v in pairs(tbContainer) do
        v.tbResData = CollectionResDataTable:GetTemplate(v.nResId)
        if(v.tbResData == nil) then
            error("CollectionDataTable find res data failed: ".. v.nResId)
        end
    end
end
-- [EXPORT END]

return CollectionDataTable
