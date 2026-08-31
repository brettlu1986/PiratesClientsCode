-----------------------------------------------------
--File Name    : ShipThrownItemTorpedoDataTableHelper.lua
--Author       : Song Fuhao
--Create Time  : 2020-02-20
--Description  : 船投掷物（陷阱）配置读取
-----------------------------------------------------
local ShipThrownItemTorpedoDataTableHelper = {}

local ShipThrownItemDataTableHelper = require("ShipThrownItemDataTableHelper")

function ShipThrownItemTorpedoDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    ShipThrownItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nBoomWaitTime   = Parser:Get("boom_wait_time"   , 5 , Parser.TypeFloat)
end

return ShipThrownItemTorpedoDataTableHelper