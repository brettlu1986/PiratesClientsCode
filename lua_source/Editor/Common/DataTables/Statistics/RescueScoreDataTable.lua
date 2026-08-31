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
local RescueScoreDataTable = {}

RescueScoreDataTable.szFileName = "common/ffa/statistics/rescue_score.tab"

function RescueScoreDataTable:OnEditorDefine(Parser)
    Parser:Define("nCount",   "count",    -1, Parser.TypeInt)
    Parser:Define("nScore",   "score",    -1, Parser.TypeInt)
end

function RescueScoreDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbContainer, tbNewTemplate)
    return true
end 

function RescueScoreDataTable:OnEditorParseFinished()
    local fnSort = function(a, b)
        return a.nCount < b.nCount
    end
    table.sort(self.tbContainer, fnSort)
end

-- [EXPORT BEGIN]
function RescueScoreDataTable:GetScore(nRescueCount)
    local nCount = #self.tbContainer
    for i, v in ipairs(self.tbContainer) do
        if nRescueCount >= v.nCount and (i + 1 <= nCount and nRescueCount < self.tbContainer[i+1].nCount or i + 1 > nCount) then
            return v.nScore
        end        
    end
    return 0
end
-- [EXPORT END]

return RescueScoreDataTable