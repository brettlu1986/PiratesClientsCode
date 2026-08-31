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
local SettingDataTable = {}

SettingDataTable.szFileName = "common/setting2/setting.tab"

function SettingDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nDefaultValue" , "default_value", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function SettingDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return SettingDataTable
