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
local SettingLayoutDefaultDataTable = {}



SettingLayoutDefaultDataTable.szFileName = "client/setting/ffa_main_layout_default.tab"

-- [EXPORT BEGIN]
SettingLayoutDefaultDataTable.tbContainerNew = {}
-- [EXPORT END]

function SettingLayoutDefaultDataTable:OnEditorDefine(Parser)
    --Parser:SetKey("szWidgetName")
    Parser:Define("szWidgetName", "widget_name", "", Parser.TypeString)
    Parser:Define("nX", "position_x", -1, Parser.TypeInt)
    Parser:Define("nY", "position_y", -1, Parser.TypeInt)
end

function SettingLayoutDefaultDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbNewTemplate.szMovableWidgetName = Parser:Get("moveable_widget_name", "", Parser.TypeString, false)
    if tbNewTemplate.szMovableWidgetName == nil or tbNewTemplate.szMovableWidgetName == "" then
        tbNewTemplate.szMovableWidgetName = tbNewTemplate.szWidgetName
    end
    if tbNewTemplate.szAlphaWidgetName == nil or tbNewTemplate.szAlphaWidgetName == "" then
        tbNewTemplate.szAlphaWidgetName = tbNewTemplate.szWidgetName
    end
    if tbNewTemplate.szScaleWidgetName == nil or tbNewTemplate.szScaleWidgetName == "" then
        tbNewTemplate.szScaleWidgetName = tbNewTemplate.szWidgetName
    end
    local tbTemplate = self.tbContainerNew[tbNewTemplate.szWidgetName]
    if not tbTemplate then
        self.tbContainerNew[tbNewTemplate.szWidgetName] = tbNewTemplate
    -- else
    --     log("duplicated szWidgetName, tbNewTemplate.szWidgetName=",tbNewTemplate.szWidgetName)
    end
    return true;
end
-- [EXPORT BEGIN]
function SettingLayoutDefaultDataTable:GetTemplate(szWidgetName)
    return self.tbContainerNew[szWidgetName] 
end
-- [EXPORT END]


return SettingLayoutDefaultDataTable
