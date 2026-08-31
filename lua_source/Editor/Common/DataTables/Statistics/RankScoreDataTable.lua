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
local RankScoreDataTable = {}

RankScoreDataTable.szFileName = "common/ffa/statistics/rank_score.tab"
-- [EXPORT]
local MAX_RANK = 100

function RankScoreDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nRank")
    Parser:Define("nRank",   "rank",  -1, Parser.TypeInt)
    Parser:Define("nScore",  "score", -1, Parser.TypeInt)
end

function RankScoreDataTable:OnEditorParseFinished()
    for i = 1, MAX_RANK do
        if self.tbContainer[i] == nil then
            local tbLast = self.tbContainer[i - 1] 
            self.tbContainer[i] = {nRank = i, nScore = tbLast.nScore}
        end 
    end
end

-- [EXPORT BEGIN]
function RankScoreDataTable:GetScore(nRank)
    local tbData = self.tbContainer[nRank]
    if tbData ~= nil then
        return tbData.nScore
    elseif nRank > MAX_RANK then
        return self:GetScore(MAX_RANK)
    else
        logerror("RankScoreDataTable:GetScore failed invalid rank ", nRank)
        return 0
    end
end
-- [EXPORT END]

return RankScoreDataTable