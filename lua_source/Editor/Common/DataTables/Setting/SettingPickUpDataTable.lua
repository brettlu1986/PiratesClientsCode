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
local SettingPickUpDataTable = {}

SettingPickUpDataTable.szFileName = "common/setting2/setting_pickup.tab"
-- [EXPORT]
SettingPickUpDataTable.tbContainerByItemId = {}


function SettingPickUpDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nItemId", "item_id", -1, Parser.TypeInt)
    Parser:Define("nMaxCount", "max_count", -1, Parser.TypeInt)
    Parser:Define("nDefaultCount", "default_count", -1, Parser.TypeInt)
    Parser:Define("nSettingType", "setting_type", -1, Parser.TypeInt)
end

function SettingPickUpDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    self.tbContainerByItemId[tbNewTemplate.nItemId] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function SettingPickUpDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

function SettingPickUpDataTable:GetAll()
    return self.tbContainer
end

function SettingPickUpDataTable:GetTemplateByItemId(nItemId)
    return self.tbContainerByItemId[nItemId]
end
-- [EXPORT END]


return SettingPickUpDataTable
