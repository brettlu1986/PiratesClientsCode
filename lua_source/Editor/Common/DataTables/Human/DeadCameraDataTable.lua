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
local DeadCameraDataTable = {}
DeadCameraDataTable.szFileName = "common/human/dead_camera.tab"

function DeadCameraDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId",                        "id",                           -1,  Parser.TypeInt)
    Parser:Define("nViewShipBoxTime",           "quick_view_ship_time",         -1,  Parser.TypeFloat)
    Parser:Define("nViewHumanBoxTime",          "quick_view_human_time",        -1,  Parser.TypeFloat)
    Parser:Define("nDeadToKillerTime",          "dead_to_killer_time",          -1,  Parser.TypeFloat)
    Parser:Define("nViewKillerTime",            "view_killer_time",             -1,  Parser.TypeFloat)
    Parser:Define("nKillerToDeadTime",          "killer_to_dead_time",          -1,  Parser.TypeFloat)
    Parser:Define("nToKillerParam",             "tokiller_param",               -1,  Parser.TypeFloat)
    
end


-- [EXPORT BEGIN]
function DeadCameraDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return DeadCameraDataTable
