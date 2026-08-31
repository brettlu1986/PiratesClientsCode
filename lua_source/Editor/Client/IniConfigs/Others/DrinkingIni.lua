--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local DrinkingIni = {}
-- local StringUtil = require("StringUtil")

DrinkingIni.szFileName = "client/minigame/drinking/drinking.ini"

-- local function ParseMatinee(szMatinees)
--     local tbTemp = StringUtil.Split(szMatinees, ",")
--     if #tbTemp <= 0 then 
--         error("DrinkingIni matinee is invalid"..szMatinees)
--         return nil
--     end 
    
--     local tbMatinee = {}
--     for _, v in ipairs(tbTemp) do
--         table.insert(tbMatinee, tonumber(v))
--     end   

--     return tbMatinee  
-- end

function DrinkingIni:OnParse(Parser)
    local tbSize = {}
    tbSize.nRowCount = Parser:Get("size", "row_count", -1, Parser.TypeNumber)
    tbSize.nColCount = Parser:Get("size", "col_count", -1, Parser.TypeNumber)
    self.tbSize = tbSize
    -- 移到drinkinglevel.tab中配置
    -- local tbMatinee = {}
    -- tbMatinee.tbStartMatinee        = ParseMatinee(Parser:Get("matinee", "start_matinee", "", Parser.TypeString))
    -- tbMatinee.tbNextMatinee         = ParseMatinee(Parser:Get("matinee", "next_matinee", "", Parser.TypeString))
    -- tbMatinee.tbSuccessfulMatinee   = ParseMatinee(Parser:Get("matinee", "successful_matinee", "", Parser.TypeString))
    -- tbMatinee.tbFailedMatinee       = ParseMatinee(Parser:Get("matinee", "failed_matinee", "", Parser.TypeString))
    -- tbMatinee.nPauseMatinee         = Parser:Get("matinee", "pause_matinee", -1, Parser.TypeNumber)
    -- self.tbMatinee = tbMatinee
end

return DrinkingIni
