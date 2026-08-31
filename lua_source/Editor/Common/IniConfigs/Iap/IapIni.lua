--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local IapIni = {}
IapIni.szFileName = "common/iap/iap.ini"

function IapIni:OnParse(Parser)
    local tbFirstPurchase = {}
    tbFirstPurchase.nItemId = Parser:Get("first_purchase", "item_id", 0, Parser.TypeNumber)
    self.tbFirstPurchase = tbFirstPurchase

    local tbGuildFirstPurchase = {}
    tbGuildFirstPurchase.nModule = Parser:Get("guild_first_purchase", "module", 0, Parser.TypeNumber)
    tbGuildFirstPurchase.nGroup = Parser:Get("guild_first_purchase", "group", 0, Parser.TypeNumber)
    tbGuildFirstPurchase.nStep = Parser:Get("guild_first_purchase", "step", 0, Parser.TypeNumber)
    self.tbGuildFirstPurchase = tbGuildFirstPurchase
end

return IapIni
