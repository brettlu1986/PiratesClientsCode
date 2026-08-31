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
local GradeScoreDataTable = {}

GradeScoreDataTable.szFileName = "common/ffa/statistics/grade_score.tab"

function GradeScoreDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nGrade")
    Parser:Define("nGrade",       "grade",    -1, Parser.TypeInt)
    Parser:Define("nScore",       "score",    -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function GradeScoreDataTable:GetScore(nGrade)
    local tbData = self.tbContainer[nGrade]
    if tbData ~= nil then
        return tbData.nScore 
    else
        log("GradeScoreDataTable:GetScore invalid grade ", nGrade)
        return 0
    end
end
-- [EXPORT END]

return GradeScoreDataTable