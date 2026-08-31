--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local TreasureIni = {}
TreasureIni.szFileName = "common/welfare/treasure.ini"

function TreasureIni:OnParse(Parser)
    local tbUIData = {}
    tbUIData.nDailyFreeTimes = Parser:Get("treasure_config", "daily_free_times", -1, Parser.TypeNumber)
    tbUIData.nMaxTime = Parser:Get("treasure_config", "daily_max_times", -1, Parser.TypeNumber)
    tbUIData.nRewardSilver = Parser:Get("treasure_config", "reward_silver", -1, Parser.TypeNumber)
    tbUIData.nConsumeGold = Parser:Get("treasure_config", "consume_gold", -1, Parser.TypeNumber)
    tbUIData.nActorID = Parser:Get("treasure_config", "actor_id", -1, Parser.TypeNumber)
    tbUIData.nStartDialogID = Parser:Get("treasure_config", "start_dialog_id", -1, Parser.TypeNumber)
    tbUIData.tbRandomDialogID = Parser:Get("treasure_config", "random_dialog_id", {}, Parser.TypeArrayNumber)
    self.tbUIData = tbUIData
end

return TreasureIni