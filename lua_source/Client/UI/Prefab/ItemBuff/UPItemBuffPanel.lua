-----------------------------------------------------
--File Name    : UPItemBuffPanel.lua
--Author       : lzheng
--Create Time  : 2019-10-15
--Description  : 大厅物品buff
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPTipBase         = require("UPTipBase")
local UPItemBuffPanel   = luaclass("UPItemBuffPanel", UPTipBase)
local ItemBuffHelper = require("ItemBuffHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")

local function OnRefreshItemBuffs(self)
    local tbBuffs = ItemBuffHelper.GetItemBuffs() 
    self:RefreshBuffItems(tbBuffs)
end

function UPItemBuffPanel:OnLoad()
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.bufList, {}, UIDef.UP_ITEM_BUFF)
end

function UPItemBuffPanel:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UPItemBuffPanel:OnExit()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end


function UPItemBuffPanel:OnBindEvent(EventHelper)
    --EventHelper:RegisterCppDelegate(self.pWidgetRef.brdClose.OnMouseButtonDownEvent, self, OnMouseButtonUp)
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_ITEM_BUFFS, self, OnRefreshItemBuffs)
end

function UPItemBuffPanel:RefreshBuffItems(tbBuffs)
    local tbData = {}
    for _, v in pairs(tbBuffs) do  
        local bValid = ItemBuffHelper.IsBuffValid(v)
        if bValid then
            table.insert(tbData, v)
        end
    end

    self.ListHelper:SetData(tbData)
    self.ListHelper:ScrollToTop(false)
end

function UPItemBuffPanel:OnSetData(tbData)
    UPItemBuffPanel.super.OnSetData(self, tbData)
    self:RefreshBuffItems(tbData)
end


return UPItemBuffPanel
