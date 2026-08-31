-----------------------------------------------------
--File Name    : NpcSkillDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-18
--Description  : NPC技能配置表
-----------------------------------------------------

local NpcSkillDataTable = {}

NpcSkillDataTable.szFileName = "common/npc/npc_skill.tab"

local function CheckConfig( self, tbTemplate )
    local nSkillSum = tbTemplate.nSkillSum
    local nSkillListLength = tbTemplate.tbSkillList and #tbTemplate.tbSkillList or 0
    local ntbSkillLevelListLength = tbTemplate.tbSkillLevelList and #tbTemplate.tbSkillLevelList or 0
    if (nSkillSum ~= nSkillListLength) or (nSkillSum ~= ntbSkillLevelListLength) then
        error("npc_skill check failed, skill count is not match, npc_id = " .. tbTemplate.nId)
    end
end
-- [EXPORT END]

function NpcSkillDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "npc_id", -1, Parser.TypeInt)
    Parser:Define("nSkillSum", "skill_sum", 0, Parser.TypeInt)
    Parser:Define("tbSkillList", "skill_list", nil, Parser.TypeArrayInt)
    Parser:Define("tbSkillLevelList", "skill_level_list", nil, Parser.TypeArrayInt)
    Parser:Define("tbStatusList", "status_list", nil, Parser.TypeArrayInt)
end

function NpcSkillDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    
    CheckConfig(self, tbNewTemplate)
    
    return true
end

-- [EXPORT BEGIN]
function NpcSkillDataTable:GetTemplate( nTemplateId )
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function NpcSkillDataTable:GetNpcSkillInfo( nTemplateId )
    local tbSkillInfoList = {}
    local tbTemplate = self:GetTemplate(nTemplateId)
    if tbTemplate then
        local nSkillSum = tbTemplate.nSkillSum
        if nSkillSum > 0 then
            local tbSkillLevelList = tbTemplate.tbSkillLevelList
            local tbSkillList = tbTemplate.tbSkillList
            for i=1, nSkillSum do
                tbSkillInfoList[i] = {level = tbSkillLevelList[i], skill_id = tbSkillList[i]}
            end
        end
    end
    return { skill_list = tbSkillInfoList, cd_effect = 0 }
end
-- [EXPORT END]

return NpcSkillDataTable
