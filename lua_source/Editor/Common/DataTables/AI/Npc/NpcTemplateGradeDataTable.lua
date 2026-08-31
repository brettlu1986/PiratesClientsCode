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
local NpcTemplateGradeDataTable = {}

local NpcLevelDataTable = require("NpcLevelDataTable")

-- [EXPORT]
local NpcTemplateDataTable = require("NpcTemplateDataTable")

NpcTemplateGradeDataTable.szFileName = "common/ffa/ai/npc/npc_template_grade.tab"

function NpcTemplateGradeDataTable:OnEditorDefine(Parser)
    Parser:Define("nGradeId", "grade_id", -1, Parser.TypeInt)
    Parser:Define("nDungeonGrade",  "dungeon_grade", -1, Parser.TypeInt)
    Parser:Define("nNpcTemplate", "npc_template", -1, Parser.TypeInt)
end

function NpcTemplateGradeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if NpcLevelDataTable:GetTemplate(tbNewTemplate.nNpcLevel) == nil then
        error("Cannot find npc level! npc template id:"..tbNewTemplate.nId..", level:"..tbNewTemplate.nNpcLevel)
    end
    return true
end


function NpcTemplateGradeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbGradeTemplates = tbContainer[tbNewTemplate.nGradeId] or { }
    tbContainer[tbNewTemplate.nGradeId] = tbGradeTemplates
    if not NpcTemplateDataTable:GetTemplate(tbNewTemplate.nNpcTemplate) then
        error("npc template not found, at grade id ", tbNewTemplate.nGradeId)
        return
    end
    tbGradeTemplates[tbNewTemplate.nDungeonGrade] = tbNewTemplate.nNpcTemplate

    return true
end


-- [EXPORT BEGIN]
function NpcTemplateGradeDataTable:GetTemplate(nGradeId, nDungeonGrade)
    if self.tbContainer[nGradeId] then
       return self.tbContainer[nGradeId][nDungeonGrade]
    end
end
-- [EXPORT END]

return NpcTemplateGradeDataTable