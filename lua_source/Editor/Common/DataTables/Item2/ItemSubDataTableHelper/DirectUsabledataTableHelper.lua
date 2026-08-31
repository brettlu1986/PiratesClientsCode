-----------------------------------------------------
--File Name    : DirectUsabledataTableHelper.lua
--Author       : lzheng
--Create Time  : 2020-07-30
--Description  : 直接使用物品配置表helper
-----------------------------------------------------
local DirectUsabledataTableHelper = {}
local DirectUseItemCategoryDef = require("DirectUseItemCategoryDef")

function DirectUsabledataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    local szUsage = Parser:Get("usage", "", Parser.TypeString)
    local nUsageParam1 = Parser:Get("usage_param_1", 0, Parser.TypeInt)
    
    local nUsageDef = DirectUseItemCategoryDef.Usage
    if szUsage == nUsageDef.RENAME_CARD then
        NewTemplate.nRenameDuration = nUsageParam1
    elseif szUsage == nUsageDef.FRIENDSHIP_CARD then  
        NewTemplate.nRewardIntimacy = nUsageParam1
    elseif szUsage == nUsageDef.SHOUT_CARD or szUsage == nUsageDef.VIP_CARD or szUsage == nUsageDef.BUFF_CARD then  
        NewTemplate.nUseCount = nUsageParam1
    elseif szUsage == nUsageDef.CHEST then
        NewTemplate.nGiftBoxRewardId = nUsageParam1
    end
end

return DirectUsabledataTableHelper