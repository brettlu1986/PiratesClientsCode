-----------------------------------------------------
--File Name    : ShipPreparationHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-07-12
--Description  : mock装配数据
-----------------------------------------------------
local luaclass = require("luaclass")
local ShipPreparationHelper = luaclass("ShipPreparationHelper")

function ShipPreparationHelper.GetDefaultData()
    return {
        -- 可建造的船
        1760001, 1760003, 1760016, 1760006, 1760007, 1760008, 1760009,
        -- 可建造的武器
        1801001, 1805001, 1806001, 1807001, 1808001, 1811001,
        -- 可建造的零件套装
        1901001, 1902001
    }

end

return ShipPreparationHelper