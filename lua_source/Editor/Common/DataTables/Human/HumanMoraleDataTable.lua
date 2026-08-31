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
local HumanMoraleDataTable = {}

HumanMoraleDataTable.szFileName = "common/ffa/human/human_morale.tab"

function HumanMoraleDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nPhase")    
    Parser:Define("nPhase", "phase", -1, Parser.TypeInt)
    Parser:Define("nMorale", "morale", -1, Parser.TypeInt)
    Parser:Define("tbBuffIds", "buffid", nil, Parser.TypeArrayInt)
    Parser:Define("tbBuffIcons", "bufficon", nil, Parser.TypeArrayString)
end

-- [EXPORT BEGIN]
function HumanMoraleDataTable:GetMoralePhase(nPhaseId)
    local tbTemplate = self.tbContainer[nPhaseId]
    if tbTemplate == nil then
        log("HumanMoraleDataTable:GetMoralePhase fail!", nPhaseId)
    end
    return tbTemplate
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function HumanMoraleDataTable:GetPhaseCount()
    local nCount = 0
    for k, v in pairs(self.tbContainer) do
        nCount = nCount + 1
    end
    return nCount
end
-- [EXPORT END]

return HumanMoraleDataTable
