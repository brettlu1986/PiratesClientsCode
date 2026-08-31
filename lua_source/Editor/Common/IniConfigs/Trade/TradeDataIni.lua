--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local TradeDataIni = {}
TradeDataIni.szFileName = "common/trade/trade.ini"

function TradeDataIni:OnParse(Parser)
    self.nNormalCargoMinPrice    = Parser:Get("trade", "cargo_price_min", 100, Parser.TypeNumber)
    self.nNormalCargoMaxPrice    = Parser:Get("trade", "cargo_price_max", 100, Parser.TypeNumber)
    self.nNormalCargoMinCount    = Parser:Get("trade", "cargo_count_min", 100, Parser.TypeNumber)
    self.nNormalCargoMaxCount    = Parser:Get("trade", "cargo_count_max", 100, Parser.TypeNumber)
    
    self.nGenreForNewPlayer   = Parser:Get("new_player_cargo", "new_player_cargo_genre", -1, Parser.TypeNumber)
    self.nDetailTypeForNewPlayer   = Parser:Get("new_player_cargo", "new_player_cargo_detail_type", -1, Parser.TypeNumber)
    self.nParticularForNewPlayer   = Parser:Get("new_player_cargo", "new_player_cargo_particular", -1, Parser.TypeNumber)
end

return TradeDataIni

