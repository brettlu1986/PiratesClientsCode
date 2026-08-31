-----------------------------------------------------
--File Name    : ConvertibleItemDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-10-08
--Description  : 可转换的物品配置表读取helper
-----------------------------------------------------

local ConvertibleItemDataTableHelper = {}

function ConvertibleItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nConvertItemTemplateId = Parser:Get("convert_item_template_id", 0, Parser.TypeInt)
    NewTemplate.nConvertItemCount = Parser:Get("convert_item_count", 0, Parser.TypeInt)
end

return ConvertibleItemDataTableHelper