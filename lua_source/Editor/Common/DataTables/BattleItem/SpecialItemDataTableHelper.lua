-----------------------------------------------------
--File Name    : SpecialItemDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-05-23
--Description  : 特殊道具的配置读取helper
-----------------------------------------------------
local SpecialItemDataTableHelper = {}

function SpecialItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.bSightFree = Parser:Get("sight_free", false, Parser.TypeBool)
end

return SpecialItemDataTableHelper