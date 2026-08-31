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
local QuestDataTable = {}

-- [EXPORT BEGIN]
local L10N = require("L10N")
-- [EXPORT END]

QuestDataTable.szFileName = "common/dungeon/quest.tab"

function QuestDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID", "quest_id", -1, Parser.TypeInt)
    Parser:Define("l10nQuestName", "quest_name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nText", "text", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nProgressDesc", "quest_progress_desc", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nAwardsDesc", "quest_awards_desc", L10N.NullString, Parser.TypeL10N)
end

-- [EXPORT BEGIN]
function QuestDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function QuestDataTable:GetQuestNameById(nID)
    local tbTemplate = self:GetTemplate(nID)
    if tbTemplate then
        return tbTemplate.l10nQuestName
    end
    return L10N.NullString
end

function QuestDataTable:GetTextById(nID)
    local tbTemplate = self:GetTemplate(nID)
    if tbTemplate then
        return tbTemplate.l10nText
    end
    return L10N.NullString
end

function QuestDataTable:GetProgressDescById(nID)
    local tbTemplate = self:GetTemplate(nID)
    if tbTemplate then
        return tbTemplate.l10nProgressDesc
    end
    return L10N.NullString
end

function QuestDataTable:GetAwardsDescById(nID)
    local tbTemplate = self:GetTemplate(nID)
    if tbTemplate then
        return tbTemplate.l10nAwardsDesc
    end
    return L10N.NullString
end
-- [EXPORT END]

return QuestDataTable
