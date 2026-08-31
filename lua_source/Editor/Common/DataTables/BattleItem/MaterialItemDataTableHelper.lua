-----------------------------------------------------
--File Name    : MaterialItemDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-09-11
--Description  : 材料的配置表读取helper
-----------------------------------------------------
local MaterialItemDataTableHelper = {}

function MaterialItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nIndex = Parser:Get("index", 0, Parser.TypeInt)
    NewTemplate.szMaterialBarUiIcon = Parser:Get("material_bar_ui_icon", "", Parser.TypeString)
end

return MaterialItemDataTableHelper