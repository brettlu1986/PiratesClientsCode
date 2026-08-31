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
local PVPOccupyDataTable = {}

PVPOccupyDataTable.szFileName = "common/dungeon/pvp_occupy.tab"

function PVPOccupyDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nMaxMemberCount", "max_member_count", -1, Parser.TypeInt)
    Parser:Define("nMaxScore", "max_score", -1, Parser.TypeInt)
    Parser:Define("nWaitForPlayerJoinTime", "wait_for_player_join_time", -1, Parser.TypeFloat)
    Parser:Define("nCountDownTime", "count_down_time", -1, Parser.TypeFloat)
    Parser:Define("nMatchTime", "match_time", -1, Parser.TypeFloat)
    Parser:Define("nShowResultTime", "show_result_time", -1, Parser.TypeFloat)
    Parser:Define("szOccupyNpcTag", "occupy_npc_tag", -1, Parser.TypeString)
    Parser:Define("nArea1TriggerId", "area1_trigger", -1, Parser.TypeInt)
    Parser:Define("nArea1OccupyTime", "area1_occupy_time", -1, Parser.TypeFloat)
    Parser:Define("nArea1PunishOccupyTimeCannon", "area1_punish_occupy_time_cannon", -1, Parser.TypeFloat)
    Parser:Define("nArea1PunishOccupyTimeTorpedo", "area1_punish_occupy_time_torpedo", -1, Parser.TypeFloat)
    Parser:Define("nArea1OccupyScore", "area1_occupy_score", -1, Parser.TypeFloat)
    Parser:Define("nArea1Score", "area1_score", -1, Parser.TypeFloat)
    Parser:Define("nArea2TriggerId", "area2_trigger", -1, Parser.TypeInt)
    Parser:Define("nArea2OccupyTime", "area2_occupy_time", -1, Parser.TypeFloat)
    Parser:Define("nArea2PunishOccupyTimeCannon", "area2_punish_occupy_time_cannon", -1, Parser.TypeFloat)
    Parser:Define("nArea2PunishOccupyTimeTorpedo", "area2_punish_occupy_time_torpedo", -1, Parser.TypeFloat)
    Parser:Define("nArea2OccupyScore", "area2_occupy_score", -1, Parser.TypeFloat)
    Parser:Define("nArea2Score", "area2_score", -1, Parser.TypeFloat)
    Parser:Define("nArea3TriggerId", "area3_trigger", -1, Parser.TypeInt)
    Parser:Define("nArea3OccupyTime", "area3_occupy_time", -1, Parser.TypeFloat)
    Parser:Define("nArea3PunishOccupyTimeCannon", "area3_punish_occupy_time_cannon", -1, Parser.TypeFloat)
    Parser:Define("nArea3PunishOccupyTimeTorpedo", "area3_punish_occupy_time_torpedo", -1, Parser.TypeFloat)
    Parser:Define("nArea3OccupyScore", "area3_occupy_score", -1, Parser.TypeFloat)
    Parser:Define("nArea3Score", "area3_score", -1, Parser.TypeFloat)
    Parser:Define("nAreaOutScore", "area_out_score", -1, Parser.TypeFloat)
    Parser:Define("nDeadScore", "dead_score", 0, Parser.TypeInt)
    Parser:Define("nKillScore", "kill_score", 0, Parser.TypeInt)
    Parser:Define("nTutorialLoginDialog", "tutorial_login_dialog", 0, Parser.TypeInt)
    Parser:Define("nTutorialResultDialog", "tutorial_result_dialog", 0, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function PVPOccupyDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return PVPOccupyDataTable