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
local ShipMoraleDataTable = {}

ShipMoraleDataTable.szFileName = "common/ffa/ship/ship_morale.tab"

function ShipMoraleDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nPhase", "phase", -1, Parser.TypeInt)
    Parser:Define("nMorale", "morale", -1, Parser.TypeInt)
    Parser:Define("tbBuffIds", "buffid", nil, Parser.TypeArrayInt)
    Parser:Define("nSound", "sound", -1, Parser.TypeInt)
    Parser:Define("strParticle", "particle", "", Parser.TypeString)
    Parser:Define("nPopText", "pop_text", -1, Parser.TypeInt)
    Parser:Define("tbBuffIcons", "bufficon", nil, Parser.TypeArrayString)
end

function ShipMoraleDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbSubPhaseTable = self.tbContainer[tbNewTemplate.nId]
    if not tbSubPhaseTable then
        self.tbContainer[tbNewTemplate.nId] = {}
        tbSubPhaseTable = self.tbContainer[tbNewTemplate.nId]
    end
    tbSubPhaseTable[tbNewTemplate.nPhase] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function ShipMoraleDataTable:GetMoralePhase(nId, nPhaseId)
    local tbTemplate = self.tbContainer[nId]
    if tbTemplate == nil then
        logerror("ShipMoraleDataTable:GetMoralePhase fail!", nId)
    end
    return tbTemplate[nPhaseId]
end

function ShipMoraleDataTable:GetMoralePhaseCount(nId)
    local tbTemplate = self.tbContainer[nId]
    if tbTemplate == nil then
        logerror("ShipMoraleDataTable:GetMoralePhase fail!", nId)
    end
    return #tbTemplate
end
-- [EXPORT END]

return ShipMoraleDataTable
