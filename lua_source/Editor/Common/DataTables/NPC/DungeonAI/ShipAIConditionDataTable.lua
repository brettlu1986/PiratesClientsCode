local ShipAIConditionDataTable = {}

ShipAIConditionDataTable.szFileName = "common/npc/dungeon/ship_ai_condition.tab"
-- [EXPORT]
ShipAIConditionDataTable.nMaxConditionCount = 5

function ShipAIConditionDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
end

function ShipAIConditionDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nLastCondition = -1
    local nNewCondition = -1
    local nMaxConditionCount = self.nMaxConditionCount

    for i=1,nMaxConditionCount do
        nNewCondition = Parser:Get("stage_"..i.."_condition", -1, Parser.TypeFloat, true)
        if(nNewCondition > 1) then
            error("Parse ship_skill_condition.tab failed, the condition must be less than one.")
            return false
        end
        if(nNewCondition < 0) then
            if(nLastCondition ~= 0) then
                error("Parse ship_skill_condition.tab failed, the end condition must be zero.")
                return false                
            else
                break
            end
        end

        tbNewTemplate["nCondition"..i] = nNewCondition
        tbNewTemplate["tbSkills"..i] = Parser:Get("stage_"..i.."_skill", nil, Parser.TypeArrayInt, true)
        tbNewTemplate["tbSkillTypes"..i] = Parser:Get("stage_"..i.."_skill_type", nil, Parser.TypeArrayInt, true)
        nLastCondition = nNewCondition
    end

    return true
end

-- [EXPORT BEGIN]
function ShipAIConditionDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return ShipAIConditionDataTable
