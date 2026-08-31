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
local GradeValueRatioDataTable = {}

GradeValueRatioDataTable.szFileName = "common/ffa/statistics/grade_value_ratio.tab"

function GradeValueRatioDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nGradeValue")
    Parser:Define("nGradeValue",   "grade_value",  -1, Parser.TypeInt)
    Parser:Define("nSurvivalValue","survival_value",  -1, Parser.TypeInt)
    Parser:Define("nKillValue",    "kill_value",  -1, Parser.TypeInt)
    Parser:Define("nItemValue",    "item_value",  -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function GradeValueRatioDataTable:GetTemplate(nGradeValue)
    local tbData = self.tbContainer[nGradeValue]
    if tbData ~= nil then
        return tbData
    end

    local nTempGrade, tbTempData = 10000, nil
    for k, v in pairs(self.tbContainer) do
        local nValue = nGradeValue - k
        if nValue > 0 and nValue <= nTempGrade then
            nTempGrade = k
            tbTempData = v
        end
    end
    return tbTempData
end
-- [EXPORT END]

return GradeValueRatioDataTable