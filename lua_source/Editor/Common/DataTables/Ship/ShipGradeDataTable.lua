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
local ShipGradeDataTable = {}

ShipGradeDataTable.szFileName = "common/ffa/ship/ship_grade.tab"

-- [EXPORT]
ShipGradeDataTable.nMinGrade = -1
-- [EXPORT]
ShipGradeDataTable.nMaxGrade = -1

function ShipGradeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nGrade")
    Parser:Define("nGrade", "grade", -1, Parser.TypeInt)
    Parser:Define("nMaxMaterialCapacity",  "max_material_capacity", -1, Parser.TypeInt)
end

function ShipGradeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    if tbNewTemplate.nGrade > self.nMaxGrade then
        self.nMaxGrade = tbNewTemplate.nGrade
    end

    if tbNewTemplate.nGrade < self.nMinGrade or self.nMinGrade == -1 then
        self.nMinGrade = tbNewTemplate.nGrade
    end

    return true
end

-- [EXPORT BEGIN]
function ShipGradeDataTable:GetTemplate(nShipGrade)
    return self.tbContainer[nShipGrade]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShipGradeDataTable:GetMaxGrade()
    return self.nMaxGrade
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShipGradeDataTable:IsGradeValid(nShipGrade)
    return nShipGrade <= self.nMaxGrade and nShipGrade >= self.nMinGrade
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShipGradeDataTable:GetMaxMaterialCapacity(nShipGrade)
    if not self:IsGradeValid(nShipGrade) then
        error("ShipGradeDataTable:GetMaxMaterialCapacity failed! nShipGrade not valid!".. nShipGrade)
    end
    local tbTemplate = self.tbContainer[nShipGrade]
    return tbTemplate.nMaxMaterialCapacity
end
-- [EXPORT END]

return ShipGradeDataTable