-----------------------------------------------------
--File Name    : UPGuideTips.lua
--Author       : Edward J
--Create Time  : 2020-02-23
--Description  : UPGuideTips
-----------------------------------------------------

local luaclass      = require("luaclass")
local PrefabBase    = require("PrefabBase")
local UPGuideTips   = luaclass("UPGuideTips", PrefabBase)


function UPGuideTips:SetVisble(bEnable)
    local eVisble = bEnable and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed
    self.pWidgetRef:SetVisibility(eVisble)
end

function UPGuideTips:SetSize(tbSize)
    self.pWidgetRef.Slot:SetSize(tbSize)
end

function UPGuideTips:SetText(szText)
    self.pWidgetRef.kmtxt_tip:SetText(szText)
end

return UPGuideTips
