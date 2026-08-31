-----------------------------------------------------
--File Name    : UPLayoutSaveTip.lua
--Author       : ranjie
--Create Time  : 2019-06-12
--Description  : 布局设置的保存确认框
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLayoutSaveTip = luaclass("UPLayoutSaveTip", PrefabBase)

UPLayoutSaveTip.bSyncCommonLayout = true

local function OnSyncLayoutChanged(self, bChecked)
    self.bSyncCommonLayout = bChecked
end

function UPLayoutSaveTip:OnBindEvent(EventHelper)
    
    EventHelper:RegisterCppDelegate(self.pWidgetRef.chkSynCommonLayout.OnCheckStateChanged, self, OnSyncLayoutChanged)
end

function UPLayoutSaveTip:Init(tbData)
    self.pWidgetRef.kmtxtExchange:SetText(tbData.l10nText)
end

return UPLayoutSaveTip
