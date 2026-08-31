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
local WndDataTable = {}

-- [EXPORT]
local MAX_SUB_ZORDER = 9
-- [EXPORT]
local MAX_ZORDER = 6
-- [EXPORT]
local ZORDER_MULTIPLE = 10

WndDataTable.szFileName = "client/ui/wnd.tab"

function WndDataTable:OnEditorDefine(Parser)
    Parser:SetKey("szWndName")
    Parser:Define("szWndName", "WndName", "", Parser.TypeString)
    Parser:Define("szScriptName", "ScriptName", "", Parser.TypeString)
    Parser:Define("szUIPath", "UIPath", "", Parser.TypeString)
    Parser:Define("bCache", "Cache", false, Parser.TypeBool)
    Parser:Define("bIgnoreCinematicMode", "IgnoreCinematicMode", false, Parser.TypeBool)
    Parser:Define("szWndDesc", "WndDesc", "", Parser.TypeString)
    Parser:Define("bValidInDebugWidget", "ValidInDebugWidget", false, Parser.TypeBool)
    Parser:Define("bPushToStack", "PushToStack", true, Parser.TypeBool)
    Parser:Define("bSceneRenderingOff", "SceneRenderingOff", false, Parser.TypeBool, false)
    Parser:Define("bAsync", "LoadAsync", false, Parser.TypeBool)
end

function WndDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nSubZOrder = math.min(Parser:Get("SubZOrder", 0, Parser.TypeInt), MAX_SUB_ZORDER)
    local nZOrder = math.min(Parser:Get("ZOrder", 0, Parser.TypeInt), MAX_ZORDER)
    tbNewTemplate.nZOrder = nZOrder * ZORDER_MULTIPLE + nSubZOrder
    tbNewTemplate.bNeedBlurBG = false
    tbNewTemplate.bNeedTopBar = false

    return true
end

-- [EXPORT BEGIN]
function WndDataTable:GetTemplate(szWndName)
    return self.tbContainer[szWndName]
end
-- [EXPORT END]

return WndDataTable
