-----------------------------------------------------
--File Name    : UPCaptainSubTab.lua
--Author       : WuJizhou
--Create Time  : 3/1/2019, 5:10:09 PM
--Description  : UPCaptainSubTab
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPCaptainSubTab = luaclass("UPCaptainSubTab", PrefabBase)

local UISetUtils = require("UISetUtils")

UPCaptainSubTab.nIndex = nil
UPCaptainSubTab.tbTabManager = nil
UPCaptainSubTab.bSelected = false

local function OnClicked(self)
    -- if not self.bSelected then
    if self.tbTabManager.fnOnTabSelected then
        self.tbTabManager.fnOnTabSelected(self.nIndex)
    end
    -- end
end

function UPCaptainSubTab:SetTabImage(szRes)
    local pRes = szRes:load()
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgItem, pRes)
end

function UPCaptainSubTab:UpdateSelectedState(bSelected)
    if bSelected then
        self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Hidden)
    end
    self.bSelected = bSelected
end

function UPCaptainSubTab:InitParams(tbParams)
    self.nIndex = tbParams.nIndex
    self.tbTabManager = tbParams.tbTabManager
end

--用代码选中某个tab调用此接口
function UPCaptainSubTab:SelectTab()
    OnClicked(self)
end

----------life cycle----------

function UPCaptainSubTab:OnBindEvent( EventHelper )
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnTab.OnClicked, self, OnClicked)
end


return UPCaptainSubTab