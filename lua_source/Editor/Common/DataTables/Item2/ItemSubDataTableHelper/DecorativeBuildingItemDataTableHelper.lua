-----------------------------------------------------
--File Name    : DecorativeBuildingItemDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-04-17
--Description  : 家园装饰物的配置
-----------------------------------------------------
local DecorativeBuildingItemDataTableHelper = {}

function DecorativeBuildingItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nBuildingId = Parser:Get("building_id", -1, Parser.TypeInt)
end

return DecorativeBuildingItemDataTableHelper