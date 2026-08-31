-----------------------------------------------------
--File Name    : HumanWeaponFashionItemDataTableHelper.lua
--Author       : WuJizhou
--Create Time  : 2020-05-14
--Description  : 人武器时装的配置表读取helper
-----------------------------------------------------
local HumanWeaponFashionItemDataTableHelper = {}

function HumanWeaponFashionItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nFashionId    = Parser:Get("fashion_id",     -1,  Parser.TypeInt)
    NewTemplate.nSourceType   = Parser:Get("source_type",    -1,  Parser.TypeInt)
    NewTemplate.bShowLevel    = Parser:Get("show_level",   true,  Parser.TypeBool)
    NewTemplate.tbEffects     = Parser:Get("effect",         {},  Parser.TypeArrayInt)
end

return HumanWeaponFashionItemDataTableHelper