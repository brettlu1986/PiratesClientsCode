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
local TimeUtil = require("TimeUtil")
local SeasonDataTable = {}

SeasonDataTable.szFileName = "common/season2/season.tab"

function SeasonDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nSeasonId")
    Parser:Define("nSeasonId", "season_id", -1, Parser.TypeInt)
    Parser:Define("l10nName" , "name",      L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nDesc" , "desc",      L10N.NullString, Parser.TypeL10N)
    Parser:Define("nCurrencyId", "currency_id", -1, Parser.TypeInt)
    Parser:Define("nCurrencyCost", "currency_cost", -1, Parser.TypeInt)
    -- Parser:Define("nDurationWeek", "duration_week", -1, Parser.TypeInt)
    Parser:Define("nDurationDay", "duration_day", -1, Parser.TypeInt)
    Parser:Define("szStartTime", "start_time", "", Parser.TypeString)
end

function SeasonDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local szStartTime = tbNewTemplate.szStartTime
    local nSeasonId = tbNewTemplate.nSeasonId

    local nTime, szError = TimeUtil.GetTimeByString(szStartTime)

    if nTime == nil then
        error("get season start time failed!nSeasonId:"..nSeasonId..", error:"..szError)
        return false
    end
    tbNewTemplate.nStartTime = nTime

    return true
end

-- [EXPORT BEGIN]
function SeasonDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function SeasonDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

return SeasonDataTable
