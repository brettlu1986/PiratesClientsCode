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
local SocietyGuardDataTable = {}

SocietyGuardDataTable.szFileName = "common/dungeon/society_guard.tab"

function SocietyGuardDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nCountDownTime", "count_down_time", -1, Parser.TypeFloat)
    Parser:Define("nStageCount", "stage_count", -1, Parser.TypeInt)
    Parser:Define("tbStageTimeList", "stage_time", nil, Parser.TypeArrayInt)
    Parser:Define("tbStageCountdownTipsList", "stage_count_down_tips", nil, Parser.TypeArrayInt)
    Parser:Define("nShowResultTime", "show_result_time", -1, Parser.TypeInt)
    Parser:Define("tbGroupTriggerIdList", "group_trigger_id", nil, Parser.TypeArrayInt)
    Parser:Define("nLastStageRandomRatio", "last_stage_random_ratio", -1, Parser.TypeInt)
    Parser:Define("nLastStageRandomShipId", "last_stage_random_ship_id", -1, Parser.TypeInt)
    Parser:Define("nHeadHintDialogId", "head_hint_dialog_id", -1, Parser.TypeInt)
    Parser:Define("bTest", "is_test", false, Parser.TypeBool)
end

function SocietyGuardDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    if tbNewTemplate.nStageCount ~= #tbNewTemplate.tbStageTimeList or 
        tbNewTemplate.nStageCount ~= #tbNewTemplate.tbGroupTriggerIdList then
        logerror('nStageCount not equal to data count, nStageCount : ', tbNewTemplate.nStageCount, ' stage time list : ', #tbNewTemplate.tbStageTimeList, 
                    ' trigger buff id count : ', #tbNewTemplate.tbTriggerBuffIdList)
        return false
    end


    return true
end

-- [EXPORT BEGIN]
function SocietyGuardDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return SocietyGuardDataTable
