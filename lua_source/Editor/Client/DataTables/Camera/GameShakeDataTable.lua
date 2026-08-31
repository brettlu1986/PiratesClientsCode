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
local GameShakeDataTable = {}

GameShakeDataTable.szFileName = "client/camera/game_shake.tab"

function GameShakeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nRecoilDuration", "recoil_duration", 0, Parser.TypeFloat)
    Parser:Define("nShakeCountMin", "shake_count_min", 0, Parser.TypeInt)
    Parser:Define("nShakeCountMax", "shake_count_max", 0, Parser.TypeInt)
    Parser:Define("nDecayParam", "decay_param", 0, Parser.TypeFloat)
    Parser:Define("nVUpperAngle", "v_upper_angle", 0, Parser.TypeFloat)
    Parser:Define("nVLowerAngle", "v_lower_angle", 0, Parser.TypeFloat)
    Parser:Define("nHUpperAngle", "h_upper_angle", 0, Parser.TypeFloat)
    Parser:Define("nHLowerAngle", "h_lower_angle", 0, Parser.TypeFloat)
    Parser:Define("nUpperRollAngle", "upper_roll_angle", 0, Parser.TypeFloat)
    Parser:Define("nLowerRollAngle", "lower_roll_angle", 0, Parser.TypeFloat)
    Parser:Define("nUpperVOffset", "upper_v_offset", 0, Parser.TypeFloat)
    Parser:Define("nLowerVOffset", "lower_v_offset", 0, Parser.TypeFloat)
    Parser:Define("nUpperHOffset", "upper_h_offset", 0, Parser.TypeFloat)
    Parser:Define("nLowerHOffset", "lower_h_offset", 0, Parser.TypeFloat)
    Parser:Define("nUpperFOffset", "upper_forward_offset", 0, Parser.TypeFloat)
    Parser:Define("nLowerFOffset", "lower_forward_offset", 0, Parser.TypeFloat)
    Parser:Define("nUpperFov", "upper_fov", 0, Parser.TypeFloat)
    Parser:Define("nLowerFov", "lower_fov", 0, Parser.TypeFloat)
end

-- [EXPORT BEGIN]
function GameShakeDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return GameShakeDataTable
