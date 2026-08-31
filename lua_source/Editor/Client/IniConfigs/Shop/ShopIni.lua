--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ShopIni = {}
local TimeUtil = require("TimeUtil")

ShopIni.szFileName = "common/shop/shop.ini"

function ShopIni:OnParse(Parser)
    local tbShopRefresh = {}
    tbShopRefresh.szFirstRefreshTime = Parser:Get("shop_refresh", "first_refresh_time", "", Parser.TypeString)

    local nTime, szError = TimeUtil.GetTimeByString(tbShopRefresh.szFirstRefreshTime)

    if nTime == nil then
        error("parse first_refresh_time failed!"..szError)
    end
    tbShopRefresh.nFirstRefreshTime = nTime
    self.tbShopRefresh = tbShopRefresh
end

return ShopIni
