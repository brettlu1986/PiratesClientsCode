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
local SocietyPrivateerDataTable = {}

SocietyPrivateerDataTable.szFileName = "common/dungeon/society_privateer.tab"

function SocietyPrivateerDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nShowResultTime", "show_result_time", -1, Parser.TypeInt)
    Parser:Define("szDebuffBallTriggerId", "debuff_ball_trigger_id", "", Parser.TypeString)
    Parser:Define("szDebuffId", "debuff_id", "", Parser.TypeString)
    Parser:Define("nEscapeTriggerId", "escape_trigger_id", -1, Parser.TypeInt)
    Parser:Define("szResId", "res_id", "", Parser.TypeString)
    Parser:Define("szEffectId", "effect_id", "", Parser.TypeString)
    Parser:Define("nDebuffBallCD", "debuff_ball_cd", "", Parser.TypeInt)
    Parser:Define("nHeadHintDialogId", "head_hint_dialog_id", -1, Parser.TypeInt)
    Parser:Define("nCountDownTime", "count_down_time", -1, Parser.TypeInt)
    Parser:Define("nTargetNpcId", "target_npc_id", -1, Parser.TypeInt)
    Parser:Define("nTargetGroupId", "target_group_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function SocietyPrivateerDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return SocietyPrivateerDataTable