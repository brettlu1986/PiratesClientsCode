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
local TriggerResDataTable = {}
local TriggerDef = require("TriggerDef")

TriggerResDataTable.szFileName = "common/res/trigger_res.tab"

function TriggerResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nResId")
    Parser:Define("nResId", "res_id", -1, Parser.TypeInt)

    Parser:Define("szPawnClassName", "pawn_class_name", "", Parser.TypeString)
    Parser:Define("nShapeType", "shape_type", -1, Parser.TypeInt)
    Parser:Define("ScaleType", "scale_type", TriggerDef.ScaleType.NONE, Parser.TypeInt)
    Parser:Define("nScaleSize", "base_scale_size", 1000, Parser.TypeInt)
    Parser:Define("nType", "trigger_type", 0, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function TriggerResDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return TriggerResDataTable
