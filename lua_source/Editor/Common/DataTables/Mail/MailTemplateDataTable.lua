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
local MailTemplateDataTable = {}
local L10N = require("L10N")

MailTemplateDataTable.szFileName = "client/mail/mail_template.tab"
-- [EXPORT BEGIN]
local DEFAULT_TEMPLATE_TYPE = 0
-- [EXPORT END]
function MailTemplateDataTable:OnEditorDefine(Parser)
    Parser:Define("nType"              , "type"             , -1                        , Parser.TypeInt)
    Parser:Define("nTemplateType"      , "template_type"    , DEFAULT_TEMPLATE_TYPE     , Parser.TypeInt)
    Parser:Define("l10nTitle"          , "subject"          , L10N.NullString           , Parser.TypeL10N)
    Parser:Define("l10nContent"        , "body"             , L10N.NullString           , Parser.TypeL10N)
    Parser:Define("l10nTipTitle"       , "title"            , L10N.NullString           , Parser.TypeL10N)
    Parser:Define("nMailDisplayType"   , "display_type"     , -1                        , Parser.TypeInt)
end

function MailTemplateDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nType = tbNewTemplate.nType
    local nTemplateType = tbNewTemplate.nTemplateType
    local tbSubContainer = self.tbContainer[nType]
    if not tbSubContainer then
        tbSubContainer = {}
        self.tbContainer[nType] = tbSubContainer
    end
    if tbSubContainer[nTemplateType] then
        logerror(string.format("MailTemplateDataTable duplicate template type, type is %d, template type is %d", nType, nTemplateType))
        return
    end
    tbSubContainer[nTemplateType] =tbNewTemplate
    return true;
end

-- [EXPORT BEGIN]
function MailTemplateDataTable:GetTemplate(nType, nTemplateType)
    if not nTemplateType then
        nTemplateType = DEFAULT_TEMPLATE_TYPE
    end
    local tbSubContainer = self.tbContainer[nType]
    return tbSubContainer[nTemplateType]
end
-- [EXPORT END]

return MailTemplateDataTable