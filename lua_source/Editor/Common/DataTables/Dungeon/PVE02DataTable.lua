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
local PVE02DataTable = {}

PVE02DataTable.szFileName = "common/dungeon/pve02.tab"

function PVE02DataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nBattle2MobRefreshInterval", "battle2_mob_refresh_interval", -1, Parser.TypeInt)
    Parser:Define("nBattle2MobCountLimit", "battle2_mob_count_limit", -1, Parser.TypeInt)
    Parser:Define("nBattle2MobRefreshCount", "battle2_mob_refresh_count", -1, Parser.TypeInt)
    Parser:Define("nSummonDialogId", "battle2_summon_dialog_id", -1, Parser.TypeInt)
    Parser:Define("nShowResultTime", "show_result_time", -1, Parser.TypeInt)
    Parser:Define("nMatinee1", "matinee1", -1, Parser.TypeInt)
    Parser:Define("nMatinee2", "matinee2", -1, Parser.TypeInt)
    Parser:Define("nMatinee3", "matinee3", -1, Parser.TypeInt)
    Parser:Define("nMatinee4", "matinee4", -1, Parser.TypeInt)
    Parser:Define("nDialog1", "dialog1", -1, Parser.TypeInt)
    Parser:Define("nDialog2", "dialog2", -1, Parser.TypeInt)
    Parser:Define("nDialog3", "dialog3", -1, Parser.TypeInt)
    Parser:Define("nPreStepStatusId", "pre_step_status_id", -1, Parser.TypeInt)
    Parser:Define("nBattle2NonCombatStatusId", "battle2_non_combat_status_id", -1, Parser.TypeInt)
    Parser:Define("nRebornCountdown", "reborn_countdown", -1, Parser.TypeInt)
    Parser:Define("nTargetTrackId", "target_track_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function PVE02DataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return PVE02DataTable