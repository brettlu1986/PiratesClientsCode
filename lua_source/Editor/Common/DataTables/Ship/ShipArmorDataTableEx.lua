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
local ShipArmorDataTableEx = {}

ShipArmorDataTableEx.szFileName = "common/ffa/ship/ship_armor.tab"

function ShipArmorDataTableEx:OnEditorDefine(Parser)
    Parser:Define("nArmorSuitId", "armor_suit_id", -1, Parser.TypeInt)
    Parser:Define("nArmorId", "armor_id", -1, Parser.TypeInt)
    Parser:Define("nRegionType", "region_type", -1, Parser.TypeInt)
    Parser:Define("szRegionName", "region_name", "", Parser.TypeString)
    Parser:Define("bIsCoreRegion", "is_core_region", false, Parser.TypeBool)
    Parser:Define("nShipPartCategory", "ship_part_category", -1, Parser.TypeInt)
    Parser:Define("tbCoveredShipPartGrades", "ship_part_covered_grades", nil, Parser.TypeArrayInt)
    Parser:Define("nDamageRatio", "damage_ratio", 1, Parser.TypeFloat)
    Parser:Define("nBurningProofProb", "burning_proof_prob", -1, Parser.TypeFloat)
    Parser:Define("nLeakingProofProb", "leaking_proof_prob", -1, Parser.TypeFloat)
end

function ShipArmorDataTableEx:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    local tbSuit = self.tbContainer[tbNewTemplate.nArmorSuitId]
    if not tbSuit then
        tbSuit = {}
        tbContainer[tbNewTemplate.nArmorSuitId] = tbSuit
    end
    tbSuit[tbNewTemplate.nArmorId] = tbNewTemplate
    return true;
end


-- [EXPORT BEGIN]
function ShipArmorDataTableEx:GetTemplate(nSuitId, nArmorId)
    local tbSuit = self.tbContainer[nSuitId]
    if tbSuit then
        return tbSuit[nArmorId]
    end
    return nil
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShipArmorDataTableEx:GetAllPartsForSuit(nSuitId)
    return self.tbContainer[nSuitId]
end
-- [EXPORT END]

return ShipArmorDataTableEx
