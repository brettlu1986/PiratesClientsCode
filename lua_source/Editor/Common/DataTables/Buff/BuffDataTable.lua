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
local BuffDataTable = {}

local L10N = require("L10N")
BuffDataTable.szFileName = "common/buff2/buff.tab"
-- [EXPORT]
local BuffResData = require("BuffResData")

function BuffDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID", "id", -1, Parser.TypeInt)
    Parser:Define("nIconID", "icon_id", -1, Parser.TypeInt)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nDesc", "desc", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nValue", "value", -1, Parser.TypeInt)
    Parser:Define("szBuffType", "buff_type", "", Parser.TypeString)
    Parser:Define("nRewardId", "remark_1", -1, Parser.TypeInt)
    Parser:Define("nRefRank", "remark_2", -1, Parser.TypeInt)
end


function BuffDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    local tbResTemp = BuffResData:GetTemplate(tbNewTemplate.nIconID)
    tbNewTemplate.szIcon = tbResTemp.szIcon
    tbNewTemplate.bCountType = tbNewTemplate.szBuffType == "COUNT"
    tbNewTemplate.nRate = tbNewTemplate.nValue * 0.01
    self.tbContainer[tbNewTemplate.nID] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function BuffDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return BuffDataTable