--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local CurrencyIni = {}
CurrencyIni.szFileName = "common/item2/sub/currency/currency.ini"

function CurrencyIni:OnParse(Parser)
    local tbCurrencyCeiling = {}
    tbCurrencyCeiling.nCurrencyId = Parser:Get("currency_ceiling", "currency_id", -1, Parser.TypeNumber)
    tbCurrencyCeiling.nRefreshPeriod = Parser:Get("currency_ceiling", "refresh_period", -1, Parser.TypeNumber)
    tbCurrencyCeiling.nDelaySecondsMax = Parser:Get("currency_ceiling", "delay_seconds_max", -1, Parser.TypeNumber)

    self.tbCurrencyCeiling = tbCurrencyCeiling

    local tbExchange = {}
    tbExchange.nExchangeRatio = Parser:Get("exchange", "exchange_ratio", -1, Parser.TypeNumber)
    tbExchange.nUnchangedId = Parser:Get("exchange", "unchanged_id", -1, Parser.TypeNumber)
    tbExchange.nExchangedId = Parser:Get("exchange", "exchanged_id", -1, Parser.TypeNumber)
    self.tbExchange = tbExchange
end

return CurrencyIni
