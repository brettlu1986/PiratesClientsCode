-----------------------------------------------------
--File Name    : GiftBoxDataTableHelper.lua
--Author       : lzheng
--Create Time  : 2020-07-30
--Description  : 礼包配置表helper
-----------------------------------------------------
local GiftBoxDataTableHelper = {}

function GiftBoxDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nGiftBoxRewardId = Parser:Get("usage_param_1", 0, Parser.TypeInt)
end

return GiftBoxDataTableHelper