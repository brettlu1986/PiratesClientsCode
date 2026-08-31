-----------------------------------------------------
--File Name    : UIAwardParseHelper.lua
--Author       : Ran Jie
--Create Time  : 2017-05-09
--Description  : UI发奖励解析工具
-----------------------------------------------------

local UIAwardParseHelper = {}

-- import require
local ItemSystemOld = require("ItemSystemOld")




function UIAwardParseHelper:ParseAwardList(tbPacketAwardList)
    local tbAwardList = {}
    for k,v in ipairs(tbPacketAwardList)do
        local tbAward = self:ParseAward(v)
        table.insert(tbAwardList,tbAward)
    end

    return tbAwardList
end

function UIAwardParseHelper:ParseAward(tbPacketAward)
    local tbAward = {}
    local tbTemplate = ItemSystemOld:GetItemTemplate(tbPacketAward.g, tbPacketAward.d, tbPacketAward.p)
    tbAward.tbTemplate = tbTemplate
    tbAward.nCount = tbPacketAward.count
    tbAward.bFirstAward = tbPacketAward.bFirstAward
    
    return tbAward
end


return UIAwardParseHelper
