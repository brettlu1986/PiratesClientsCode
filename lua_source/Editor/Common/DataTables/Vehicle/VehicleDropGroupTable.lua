--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local VehicleDropGroupTable = {}

VehicleDropGroupTable.szFileName = "common/ffa/vehicle/vehicle_group.tab"

function VehicleDropGroupTable:OnEditorDefine(Parser)
    -- Parser:SetKey("nVehicleGroupId")
    Parser:Define("nVehicleGroupId"  , "vehicle_group_id"  , -1, Parser.TypeInt)
    Parser:Define("nWeight"  , "weight"  , -1, Parser.TypeInt)
    Parser:Define("nVehicleId"  , "vehicle_id"  , -1, Parser.TypeInt)
    Parser:Define("nVehicleType"  , "vehicle_type"  , -1, Parser.TypeInt)
end

function VehicleDropGroupTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if not tbContainer[tbNewTemplate.nVehicleGroupId] then
        tbContainer[tbNewTemplate.nVehicleGroupId] = {}
    end 
    table.insert(tbContainer[tbNewTemplate.nVehicleGroupId], tbNewTemplate)
    return true
end 

-- [EXPORT BEGIN]
function VehicleDropGroupTable:GetTemplate(nVehicleGroupId)
    return self.tbContainer[nVehicleGroupId]
end
-- [EXPORT END]



return VehicleDropGroupTable
