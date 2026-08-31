--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local NpcTemplateDataTable = {}

local NpcLevelDataTable = require("NpcLevelDataTable")

NpcTemplateDataTable.szFileName = "common/ffa/ai/npc/npc_template.tab"

function NpcTemplateDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nNpcLevel",  "npc_level", -1, Parser.TypeInt)
    Parser:Define("nPatrolPathId", "patrol_path_id", -1, Parser.TypeInt)
    Parser:Define("nAutoAttackRange", "trigger_attack_range", -1, Parser.TypeInt)
    Parser:Define("nMaxActiveRange", "max_active_range", -1, Parser.TypeInt)
    Parser:Define("nExpirationTime", "expiration_time", -1, Parser.TypeFloat)
    Parser:Define("nMinAttackDistance", "min_attack_dist", -1, Parser.TypeFloat)
    Parser:Define("nStopTimeWhilePatrol", "stop_time_while_patrol", -1, Parser.TypeFloat)
    Parser:Define("nLeaveActiveRangeTime", "leave_active_range_time", -1, Parser.TypeFloat)
    Parser:Define("nAlertChangeSpeed", "alert_change_speed", -1, Parser.TypeFloat)
    Parser:Define("nSightDistance", "sight_diatance", 5000, Parser.TypeFloat)
    Parser:Define("nSightAngle", "sight_angle", 120, Parser.TypeFloat)
end

function NpcTemplateDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if NpcLevelDataTable:GetTemplate(tbNewTemplate.nNpcLevel) == nil then
        error("Cannot find npc level! npc template id:"..tbNewTemplate.nId..", level:"..tbNewTemplate.nNpcLevel)
    end
    return true
end

-- [EXPORT BEGIN]
function NpcTemplateDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return NpcTemplateDataTable