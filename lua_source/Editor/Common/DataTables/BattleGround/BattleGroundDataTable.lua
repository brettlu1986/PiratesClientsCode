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
local L10N = require("L10N")
local BattleGroundDataTable = {}

BattleGroundDataTable.szFileName = "common/battleground/battleground.tab"
-- list

function BattleGroundDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nPlayerCount", "player_per_team", 1, Parser.TypeInt)
    Parser:Define("nPlayerLevelLimit", "player_level_limit", 1, Parser.TypeInt)
    Parser:Define("nScheduleId", "schedule", 1, Parser.TypeInt)
    Parser:Define("l10nTime", "time", L10N.NullString, Parser.TypeL10N)
    Parser:Define("szImagePath", "image_path", "", Parser.TypeString)
    Parser:Define("l10nDesc1", "desc1", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nDesc2", "desc2", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nRuleId", "rule_id", -1, Parser.TypeInt)
    Parser:Define("nAwardId", "level_award_id", -1, Parser.TypeInt)
    Parser:Define("szBigImgPath", "big_image_path", "", Parser.TypeString)
end

-- [EXPORT BEGIN]
function BattleGroundDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleGroundDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

return BattleGroundDataTable
