-----------------------------------------------------
--File Name    : MaterialBoxDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-06-05
--Description  : 材料盒子的物品配置表读取helper
-----------------------------------------------------
local MaterialBoxDataTableHelper = {}

local ConvertibleItemDataTableHelper = require("ConvertibleItemDataTableHelper")

function MaterialBoxDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    ConvertibleItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nOffsetXLand = Parser:Get("offset_x_land", 0, Parser.TypeInt)
    NewTemplate.nOffsetYLand = Parser:Get("offset_y_land", 0, Parser.TypeInt)
    NewTemplate.nOffsetXSea = Parser:Get("offset_x_sea", 0, Parser.TypeInt)
    NewTemplate.nOffsetYSea = Parser:Get("offset_y_sea", 0, Parser.TypeInt)
    NewTemplate.nYaw = Parser:Get("yaw", 0, Parser.TypeInt)
end

return MaterialBoxDataTableHelper