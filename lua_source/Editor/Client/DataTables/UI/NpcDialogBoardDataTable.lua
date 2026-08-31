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
local NpcDialogBoardDataTable = {}

NpcDialogBoardDataTable.szFileName = "client/ui/npc_dialog_board.tab"

function NpcDialogBoardDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID", "id", -1, Parser.TypeInt)
    Parser:Define("tbBorn", "born", {}, Parser.TypeArrayInt, false)
    Parser:Define("nBornIntervalTime", "born_interval_time", -1, Parser.TypeInt, false)
    Parser:Define("tbDiscoverEnemy", "discover_enemy", {}, Parser.TypeArrayInt, false)
    Parser:Define("nDiscoverEnemyIntervalTime", "discover_enemy_interval_time", -1, Parser.TypeInt, false)
    Parser:Define("tbKillEnemy", "kill_enemy", {}, Parser.TypeArrayInt, false)
    Parser:Define("nKillEnemyIntervalTime", "kill_enemy_interval_time", -1, Parser.TypeInt, false)
    Parser:Define("tbBurnEnemy", "burn_enemy", {}, Parser.TypeArrayInt, false)
    Parser:Define("nBurnEnemyIntervalTime", "burn_enemy_interval_time", -1, Parser.TypeInt, false)
    Parser:Define("tbHitEnemy", "hit_enemy", {}, Parser.TypeArrayInt, false)
    Parser:Define("nHitEnemyIntervalTime", "hit_enemy_interval_time", -1, Parser.TypeInt, false)
    Parser:Define("tbDeadSelf", "dead_self", {}, Parser.TypeArrayInt, false)
    Parser:Define("nDeadSelfIntervalTime", "dead_self_interval_time", -1, Parser.TypeInt, false)
    Parser:Define("tbHitTorpedoSelf", "hit_torpedo_self", {}, Parser.TypeArrayInt, false)
    Parser:Define("nHitTorpedoSelfIntervalTime", "hit_torpedo_self_interval_time", -1, Parser.TypeInt, false)
    Parser:Define("tbHitCoreSelf", "hit_core_self", {}, Parser.TypeArrayInt, false)
    Parser:Define("nHitCoreSelfIntervalTime", "hit_core_self_interval_time", -1, Parser.TypeInt, false)
    Parser:Define("tbBurnSelf", "burn_self", {}, Parser.TypeArrayInt, false)
    Parser:Define("nBurnSelfIntervalTime", "burn_self_interval_time", -1, Parser.TypeInt, false)
    Parser:Define("tbWaterLeakSelf", "water_leak_self", {}, Parser.TypeArrayInt, false)
    Parser:Define("nWaterLeakSelfIntervalTime", "water_leak_self_interval_time", -1, Parser.TypeInt, false)
    Parser:Define("tbHitSelf", "hit_self", {}, Parser.TypeArrayInt, false)
    Parser:Define("nHitSelfIntervalTime", "hit_self_interval_time", -1, Parser.TypeInt, false)
end

-- [EXPORT BEGIN]
function NpcDialogBoardDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function NpcDialogBoardDataTable:Container()
    return self.tbContainer
end
-- [EXPORT END]

return NpcDialogBoardDataTable