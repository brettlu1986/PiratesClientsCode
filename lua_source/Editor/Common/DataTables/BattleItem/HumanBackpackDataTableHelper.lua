-----------------------------------------------------
--File Name    : HumanBackpackDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-09-13
--Description  : 人的背包配置表读取helper
-----------------------------------------------------
local HumanBackpackDataTableHelper = {}

function HumanBackpackDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nMaxInventorySlots = Parser:Get("max_inventory_slots", 0, Parser.TypeInt)
    NewTemplate.nInventoryCapacity = Parser:Get("inventory_capacity", 0, Parser.TypeInt)
    NewTemplate.nAvatarId = Parser:Get("avatar_id", 0, Parser.TypeInt)
end

return HumanBackpackDataTableHelper