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

local UTF8NameValidatorHelper = require("UTF8NameValidatorHelper")
local L10N = require("L10N")
local RandomNameTable = {}

RandomNameTable.szFileName = "common/name/random_name.tab"

RandomNameTable.tbNameValidator = nil 
-- [EXPORT]
RandomNameTable.tbAll = {}

function RandomNameTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")    
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nSex", "sex", -1, Parser.TypeInt)
    Parser:Define("l10nPrefix", "prefix", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nPostfix", "postfix", L10N.NullString, Parser.TypeL10N)
end

function RandomNameTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if not self.tbNameValidator then 
        self.tbNameValidator = UTF8NameValidatorHelper:CreatePlayerNameValidator()
    end 
    local _, nDisplayWidth = self.tbNameValidator:DisplayWidth(L10N:ToString(tbNewTemplate.l10nPrefix))
    tbNewTemplate.nPrefixLen = nDisplayWidth
    _, nDisplayWidth = self.tbNameValidator:DisplayWidth(L10N:ToString(tbNewTemplate.l10nPostfix))
    tbNewTemplate.nPostfixLen = nDisplayWidth
    if not self.tbAll[tbNewTemplate.nSex] then 
        self.tbAll[tbNewTemplate.nSex] = {}
    end 

    table.insert(self.tbAll[tbNewTemplate.nSex], tbNewTemplate)
    return true
end

function RandomNameTable:OnEditorParseFinished()
    self.tbNameValidator = nil 
end 

-- [EXPORT BEGIN]
function RandomNameTable:GetTemplate(nSex)
    return self.tbAll[nSex]
end 
-- [EXPORT END]

return RandomNameTable