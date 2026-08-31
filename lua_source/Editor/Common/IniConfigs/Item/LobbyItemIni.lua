--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local LobbyItemIni = {}
LobbyItemIni.szFileName = "common/item2/lobby_item.ini"

function LobbyItemIni:OnParse(Parser)
    local tbItemUse = {}
    tbItemUse.nUseMax = Parser:Get("item_use", "use_max", -1, Parser.TypeNumber)
    self.tbItemUse = tbItemUse

    local tbCurrency = {}
    tbCurrency.tbDefaultDisplayCurrencyIds = Parser:Get("currency", "default_display", {}, Parser.TypeArrayNumber)
    self.tbCurrency = tbCurrency
end

return LobbyItemIni
