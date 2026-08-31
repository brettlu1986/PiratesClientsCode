-----------------------------------------------------
--File Name    : UnlockItemDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-04-24
--Description  : 体验卡的配置读取helper
-----------------------------------------------------
local UnlockItemDataTableHelper = {}

function UnlockItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nUnlockItemTemplateId = Parser:Get("usage_param_1", -1, Parser.TypeInt)
    NewTemplate.nUnlockItemExpirationTime = Parser:Get("usage_param_2", -1, Parser.TypeInt)
    NewTemplate.nRelatedItemTemplateId = Parser:Get("usage_param_3", -1, Parser.TypeInt)
end

return UnlockItemDataTableHelper