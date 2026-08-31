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
local L10N = require("L10N")
local RankDataTable = {}

RankDataTable.szFileName = "common/season2/rank/rank.tab"

function RankDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nRank")
    Parser:Define("nRank",          "rank",         -1, Parser.TypeInt)
    Parser:Define("l10nName" ,      "rank_name",    L10N.NullString, Parser.TypeL10N)
    Parser:Define("nRankPoint" ,    "rank_point",   -1, Parser.TypeInt)
    Parser:Define("nRankLevel",     "rank_level",   -1, Parser.TypeInt)
    Parser:Define("szRankLevelName","rank_level_text", "", Parser.TypeString, false)
    Parser:Define("szIconRes",      "icon_res", "", Parser.TypeString, false)
    -- Parser:Define("nInheritRank",   "inherit_rank", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function RankDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function RankDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function RankDataTable:GetTemplateByRankLevel(nRankLevel)
    for k, v in pairs(self.tbContainer) do
        if v.nRankLevel == nRankLevel then
            return v
        end
    end
end
-- [EXPORT END]

return RankDataTable
