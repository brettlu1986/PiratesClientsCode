--[[    DataTable类中必须有的成员变量与函数
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
local FFADialogDataTable = {}
local L10N = require("L10N")

FFADialogDataTable.szFileName = "common/ffa/dialog/ffa_dialog.tab"

function FFADialogDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "dialog_id", - 1, Parser.TypeInt)
    Parser:Define("nIndex", "index", - 1, Parser.TypeInt)
    Parser:Define("l10nContent", "content", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nIconId", "icon_id", - 1, Parser.TypeInt)
    Parser:Define("nRemainTime", "remain_time", - 1, Parser.TypeInt)
    Parser:Define("nSoundId", "sound_id", 0, Parser.TypeInt)
end

function FFADialogDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if self.tbContainer[tbNewTemplate.nId] == nil then 
        tbContainer[tbNewTemplate.nId] = {}
    end
    tbContainer[tbNewTemplate.nId][tbNewTemplate.nIndex] = tbNewTemplate
    return true;
end

-- [EXPORT BEGIN]
function FFADialogDataTable:GetTemplate(nId, nIndex)
    local tbDialog = self.tbContainer[nId]
    if tbDialog then
        return tbDialog[nIndex]
    end
    return nil
end
-- [EXPORT END]

return FFADialogDataTable
