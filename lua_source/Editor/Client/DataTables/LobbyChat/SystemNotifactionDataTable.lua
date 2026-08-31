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
local SystemNotifactionDataTable = {}

SystemNotifactionDataTable.szFileName = "client/lobbychat/systemnotifaction.tab"

function SystemNotifactionDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nType", "type", -1, Parser.TypeInt)
    Parser:Define("bShowNotify", "shownotify", -1, Parser.TypeInt)
    Parser:Define("nPriority", "priority", -1, Parser.TypeInt)
    Parser:Define("nLoopCount", "loopcount", -1, Parser.TypeInt)
    Parser:Define("nInterval", "interval", -1, Parser.TypeInt)
    Parser:Define("l10nMsg", "msg", "", Parser.TypeL10N)
end

-- [EXPORT BEGIN]
function SystemNotifactionDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function SystemNotifactionDataTable:GetAll()
    return self.tbContainer
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function SystemNotifactionDataTable:GetAllCount()
    return #self.tbContainer
end
-- [EXPORT END]

return SystemNotifactionDataTable