-----------------------------------------------------
--File Name    : ShipSkillDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-18
--Description  : 船只技能配置表
-----------------------------------------------------

local ShipSkillDataTable = {}

ShipSkillDataTable.szFileName = "common/battle_ability/ship_skill.tab"

function ShipSkillDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "ship_id", -1, Parser.TypeInt)
    Parser:Define("tbFlagSkill", "flag_skill", {}, Parser.TypeArrayInt)
    Parser:Define("tbStepSkill", "step_skill", {}, Parser.TypeArrayInt)
    Parser:Define("tbFeatureSkill", "feature_skill", {}, Parser.TypeArrayInt)
end

-- [EXPORT BEGIN]
function ShipSkillDataTable:GetTemplate( nTemplateId )
    return self.tbContainer[nTemplateId]
end

local function FillSkill(tbSkillList, tbTemplateSkills)
    local nDefaultSkillLevel = 1
    if tbTemplateSkills then
        for i,v in ipairs(tbTemplateSkills) do
            local skill = {
                skill_id = v,
                level = nDefaultSkillLevel
            }
            table.insert(tbSkillList, skill)
        end
    end
end

function ShipSkillDataTable:GetDefaultSkillInfo(nTemplateId)
    local tbSkillInfo = {
        skill_list = {},
        cd_effect = 0
    }
    local tbTemplate = self:GetTemplate(nTemplateId)
    if tbTemplate then
        FillSkill(tbSkillInfo.skill_list, tbTemplate.tbFlagSkill)
        FillSkill(tbSkillInfo.skill_list, tbTemplate.tbStepSkill)
        FillSkill(tbSkillInfo.skill_list, tbTemplate.tbFeatureSkill)
    end
    return tbSkillInfo
end
-- [EXPORT END]

return ShipSkillDataTable
