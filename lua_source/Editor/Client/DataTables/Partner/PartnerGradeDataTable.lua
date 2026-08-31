-----------------------------------------------------
--File Name    : PartnerGradeDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-06
--Description  : 伙伴质量相关属性配置表
-----------------------------------------------------
local PartnerGradeDataTable = {}

local MAX_LEVEL_COUNT = 6
PartnerGradeDataTable.szFileName = "common/item2/sub/partner/partner_grade.tab"

function PartnerGradeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nGrade")
    Parser:Define("nGrade", "grade", -1, Parser.TypeInt)
    Parser:Define("szIconRes", "icon_res", nil, Parser.TypeString)
end

function PartnerGradeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbLevelFragmentCount = {}
    for i=1,MAX_LEVEL_COUNT do
        tbLevelFragmentCount[i] = Parser:Get("level_fragment_count_" .. i, 0, Parser.TypeInt)
    end
    tbNewTemplate.tbLevelFragmentCount = tbLevelFragmentCount
    return true
end

-- [EXPORT BEGIN]
function PartnerGradeDataTable:GetFragmentCountByGradeAndLevel(nGrade, nLevel)
    local tbTemplate = self.tbContainer[nGrade]
    return tbTemplate.tbLevelFragmentCount[nLevel]
end

function PartnerGradeDataTable:GetIconRes(nGrade)
    local tbTemplate = self.tbContainer[nGrade]
    return tbTemplate.szIconRes
end
-- [EXPORT END]

return PartnerGradeDataTable
