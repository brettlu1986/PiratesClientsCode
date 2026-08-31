-----------------------------------------------------
--File Name    : GuideSharedInfoHelper.lua
--Author       : zhiyuan
--Create Time  : 2020-02-26
--Description  : 指引共享数据相关的工具方法
-----------------------------------------------------

local GuideSharedInfoHelper = {}

local GuideSharedInfoKeyDef = require("GuideSharedInfoKeyDef")

function GuideSharedInfoHelper.FillObjectNameToSharedInfo(tbTrigger, tbGameObject)
    local tbFormatStrings = {}
    table.insert(tbFormatStrings, tbGameObject:GetName())
    tbTrigger:SetSharedInfo(GuideSharedInfoKeyDef.FORMAT_STRINGS, tbFormatStrings)
end

return GuideSharedInfoHelper