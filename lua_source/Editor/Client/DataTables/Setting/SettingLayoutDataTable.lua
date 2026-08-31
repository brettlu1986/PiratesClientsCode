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
local SettingLayoutDataTable = {}



SettingLayoutDataTable.szFileName = "client/setting/setting_layout.tab"

-- [EXPORT BEGIN]
SettingLayoutDataTable.tbContainerNew = {}
-- [EXPORT END]

function SettingLayoutDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szWidgetName", "widget_name", "", Parser.TypeString)
    Parser:Define("szMovableWidgetName", "movable_widget_name", "", Parser.TypeString, false)
    Parser:Define("szAlphaWidgetName", "alpha_widget_name", "", Parser.TypeString, false)
    Parser:Define("szScaleWidgetName", "scale_widget_name", "", Parser.TypeString, false)
    Parser:Define("szExpandWidgetName", "expand_widget_name", "", Parser.TypeString, false)
    Parser:Define("szMainWidgetName", "main_widget_name", "", Parser.TypeString)
    Parser:Define("szMainScaleWidgetName", "main_scale_widget_name", "", Parser.TypeString)
    Parser:Define("szMainAlphaWidgetName", "main_alpha_widget_name", "", Parser.TypeString)
    Parser:Define("nFrom", "from", 0, Parser.TypeInt, false)
    Parser:Define("nOperationMode", "operation_mode", 0, Parser.TypeInt)
end

function SettingLayoutDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if tbNewTemplate.szMovableWidgetName == nil or tbNewTemplate.szMovableWidgetName == "" then
        tbNewTemplate.szMovableWidgetName = tbNewTemplate.szWidgetName
    end
    if tbNewTemplate.szAlphaWidgetName == nil or tbNewTemplate.szAlphaWidgetName == "" then
        tbNewTemplate.szAlphaWidgetName = tbNewTemplate.szWidgetName
    end
    if tbNewTemplate.szScaleWidgetName == nil or tbNewTemplate.szScaleWidgetName == "" then
        tbNewTemplate.szScaleWidgetName = tbNewTemplate.szWidgetName
    end

    if tbNewTemplate.szMainAlphaWidgetName == nil or tbNewTemplate.szMainAlphaWidgetName == "" then
        tbNewTemplate.szMainAlphaWidgetName = tbNewTemplate.szMainWidgetName
    end
    if tbNewTemplate.szMainScaleWidgetName == nil or tbNewTemplate.szMainScaleWidgetName == "" then
        tbNewTemplate.szMainScaleWidgetName = tbNewTemplate.szMainWidgetName
    end
    --nFrom:
    --0:commoncommon
    --1:human
    --2:ship
    --3:Vehicle
    local tbFrom = self.tbContainerNew[tbNewTemplate.nFrom]
    if not tbFrom then
        tbFrom = {}
        self.tbContainerNew[tbNewTemplate.nFrom] = tbFrom
    end
    table.insert(tbFrom, tbNewTemplate)
    return true;
end

-- [EXPORT BEGIN]
function SettingLayoutDataTable:GetTemplate(nId)
    return self.tbContainer[nId] 
end

function SettingLayoutDataTable:GetAllLayoutData()
    return self.tbContainer
end

function SettingLayoutDataTable:GetLayoutDataFrom(nFrom)
    return self.tbContainerNew[nFrom]
end
-- [EXPORT END]



return SettingLayoutDataTable
