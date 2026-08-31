--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ArenaIni = {}
ArenaIni.szFileName = "common/arena/arena.ini"
local StringUtil = require("StringUtil")

local function ParseAward(szAward)
    if not szAward or string.len( szAward ) <= 0 then
        return  nil 
    end
    local tbTemp = StringUtil.Split(szAward, ",")
    if #tbTemp < 3  then
        return nil
    end 

    local tbItemId = {}   
    tbItemId.nGenre = tonumber(tbTemp[1]) 
    tbItemId.nDetailType = tonumber(tbTemp[2]) 
    tbItemId.nParticular = tonumber(tbTemp[3]) 
    
    return tbItemId
end

function ArenaIni:OnParse(Parser)
    local tbDailyFirstWin = {}
    tbDailyFirstWin.nAwardId    = Parser:Get("daily_first_win", "award_id"            , -1, Parser.TypeNumber)
    tbDailyFirstWin.nResetHour  = Parser:Get("daily_first_win", "reset_hour"          , -1, Parser.TypeNumber)
    tbDailyFirstWin.tbPreviewAward = ParseAward(Parser:Get("daily_first_win", "preview_award", "", Parser.TypeString))

    self.tbDailyFirstWin = tbDailyFirstWin
end

return ArenaIni
