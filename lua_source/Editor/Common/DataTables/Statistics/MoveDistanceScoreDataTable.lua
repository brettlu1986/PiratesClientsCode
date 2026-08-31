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
local MoveDistanceScoreDataTable = {}

MoveDistanceScoreDataTable.szFileName = "common/ffa/statistics/movedistance_score.tab"

function MoveDistanceScoreDataTable:OnEditorDefine(Parser)
    Parser:Define("nDistance",   "distance",    -1, Parser.TypeInt)
    Parser:Define("nScore",      "score",       -1, Parser.TypeInt)
end

function MoveDistanceScoreDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbContainer, tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function MoveDistanceScoreDataTable:GetScore(nDistance)
    local nCount = #self.tbContainer
    for i, v in ipairs(self.tbContainer) do
        if nDistance >= v.nDistance and (i + 1 <= nCount and nDistance < self.tbContainer[i+1].nDistance or i + 1 > nCount) then
            return v.nScore
        end        
    end
    
    return 0
end
-- [EXPORT END]

return MoveDistanceScoreDataTable