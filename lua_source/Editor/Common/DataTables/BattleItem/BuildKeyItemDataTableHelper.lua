-----------------------------------------------------
--File Name    : BuildKeyItemDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-10-17
--Description  : 建造关键材料的配置表读取helper
-----------------------------------------------------

local BuildKeyItemDataTableHelper = {}

function BuildKeyItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.szCostIconPath = Parser:Get("cost_icon", "", Parser.TypeString)
end

return BuildKeyItemDataTableHelper