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
local ShipPathMoveGearDataTable = {}

ShipPathMoveGearDataTable.szFileName = "common/ship/ship_path_move_gear.tab"

function ShipPathMoveGearDataTable:OnEditorDefine(Parser)
    Parser:Define("nGear", "gear", -1, Parser.TypeInt)
    Parser:Define("nMaxSteerAngle", "max_steer_angle", -1, Parser.TypeFloat)
    Parser:Define("nMinDistance", "min_distance", -1, Parser.TypeFloat)
end

function ShipPathMoveGearDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    table.insert(self.tbContainer, tbNewTemplate)
    --tbContainer[tbNewTemplate.nGear + 1] = tbNewTemplate
    return true;
end

return ShipPathMoveGearDataTable