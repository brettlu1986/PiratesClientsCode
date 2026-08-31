local NpcAIConditionDataTable = {}

NpcAIConditionDataTable.szFileName = "common/npc/dungeon/npc_ai_condition.tab"
-- [EXPORT]
NpcAIConditionDataTable.nMaxConditionCount = 5

function NpcAIConditionDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
end

function NpcAIConditionDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nLastCondition = -1
    local nNewCondition = -1
    local nMaxConditionCount = self.nMaxConditionCount
    local tbSkills, tbLoadingTimes, tbBuffs, tbPassiveSkills

    for i=1,nMaxConditionCount do
        nNewCondition = Parser:Get("stage_"..i.."_condition", -1, Parser.TypeFloat, true)
        if(nNewCondition > 1) then
            error("Parse npc_ai_condition.tab failed, the condition must be less than one.")
            return false
        end
        if(nNewCondition < 0) then
            if(nLastCondition ~= 0) then
                error("Parse npc_ai_condition.tab failed, the end condition must be zero.")
                return false                
            else
                break
            end
        end

        tbSkills = Parser:Get("stage_"..i.."_skill", nil, Parser.TypeArrayInt, true)
        tbLoadingTimes = Parser:Get("stage_"..i.."_loading", nil, Parser.TypeArrayFloat, true)
        tbBuffs = Parser:Get("stage_"..i.."_buff", nil, Parser.TypeArrayInt, true)
        tbPassiveSkills = Parser:Get("stage_"..i.."_skill_passive", nil, Parser.TypeArrayInt, true)

        if(tbSkills ~= nil and tbLoadingTimes ~= nil and #tbSkills ~= #tbLoadingTimes) then
            error("Parse npc_ai_condition.tab failed, the number of skill is not equal to loading.")
            return false
        end

        tbNewTemplate["nCondition"..i] = nNewCondition
        tbNewTemplate["tbSkills"..i] = tbSkills
        tbNewTemplate["tbLoadingTimes"..i] = tbLoadingTimes
        tbNewTemplate["tbBuffs"..i] = tbBuffs
        tbNewTemplate["tbPassiveSkills"..i] = tbPassiveSkills
        
        nLastCondition = nNewCondition
    end

    return true
end

-- [EXPORT BEGIN]
function NpcAIConditionDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return NpcAIConditionDataTable
