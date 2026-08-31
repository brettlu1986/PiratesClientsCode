--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT] 
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local ObjectiveDataTable = {}

-- [EXPORT BEGIN]
local L10N = require("L10N")
-- [EXPORT END]

ObjectiveDataTable.szFileName = "common/dungeon/objective.tab"

function ObjectiveDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID", "id", -1, Parser.TypeInt)
    Parser:Define("l10nText", "text", L10N.NullString, Parser.TypeL10N)
end

-- [EXPORT BEGIN]
function ObjectiveDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ObjectiveDataTable:GetTextById(nID)
    local tbTemplate = self:GetTemplate(nID)
    if tbTemplate then
        return tbTemplate.l10nText
    end
    return L10N.NullString
end
-- [EXPORT END]

return ObjectiveDataTable
