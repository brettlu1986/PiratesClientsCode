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
local PVE01DataTable = {}

PVE01DataTable.szFileName = "common/dungeon/pve01.tab"

function PVE01DataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nCountDownTime", "count_down_time", -1, Parser.TypeFloat)
    Parser:Define("nShowResultTime", "show_result_time", -1, Parser.TypeInt)
    Parser:Define("nEnterSceneMatineeId", "enter_scene_matinee_id", -1, Parser.TypeInt)
    Parser:Define("nBossBornMatineeId", "boss_born_matinee_id", -1, Parser.TypeInt)
    Parser:Define("nBossDieMatineeId", "boss_die_matinee_id", -1, Parser.TypeInt)
    Parser:Define("nRebornCountdown", "reborn_countdown", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function PVE01DataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return PVE01DataTable
