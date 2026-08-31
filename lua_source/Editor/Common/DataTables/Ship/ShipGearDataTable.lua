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
local ShipGearDataTable = {}

ShipGearDataTable.szFileName = "common/ship/ship_gear.tab"

function ShipGearDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nPosture", "posture", -1, Parser.TypeInt)
    Parser:Define("nGear", "gear", -1, Parser.TypeInt)
    Parser:Define("nLinearAcceleration", "linear_acceleration", -1, Parser.TypeFloat)
    Parser:Define("nLinearDeceleration", "linear_deceleration", -1, Parser.TypeFloat)
    Parser:Define("nMaxLinearSpeed", "max_linear_speed", -1, Parser.TypeFloat)
    Parser:Define("nAngularAcceleration", "angular_acceleration", -1, Parser.TypeFloat)
    Parser:Define("nMaxAngularSpeed", "max_angular_speed", -1, Parser.TypeFloat)
    Parser:Define("nAngularDeceleration", "angular_deceleration", -1, Parser.TypeFloat)
end

function ShipGearDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbNewTemplate.bIsHub = false

    local tbGears = self.tbContainer[tbNewTemplate.nId];
    if (not tbGears) then
        tbGears = {}
        tbContainer[tbNewTemplate.nId] = tbGears;
    end

    table.insert(tbGears, tbNewTemplate)
    --tbGears[tbNewTemplate.nGear + 1] = tbNewTemplate;

    return true;
end

-- [EXPORT BEGIN]
function ShipGearDataTable:GetTemplateArray(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShipGearDataTable:GetGear(nId, nPosture, nGear)
    local tbGears = self.tbContainer[nId]
    for _, v in ipairs(tbGears) do
        if v.nPosture == nPosture and v.nGear == nGear then
            return v
        end
    end
    return nil
end
-- [EXPORT END]

return ShipGearDataTable