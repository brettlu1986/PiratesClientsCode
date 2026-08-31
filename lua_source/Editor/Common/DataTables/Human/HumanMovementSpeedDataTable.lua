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
local HumanMovementSpeedDataTable = {}

HumanMovementSpeedDataTable.szFileName = "common/ffa/human/human_movement_speed.tab"

function HumanMovementSpeedDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nPose")
    Parser:Define("nPose", "pose_id", -1, Parser.TypeInt)
    Parser:Define("nSpeed", "speed", -1, Parser.TypeInt)

    Parser:Define("nRun", "run", -1, Parser.TypeInt)
    Parser:Define("nLeftRight", "left_right", -1, Parser.TypeInt)
    Parser:Define("nBack", "back", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function HumanMovementSpeedDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return HumanMovementSpeedDataTable
