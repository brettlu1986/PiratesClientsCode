-----------------------------------------------------
--File Name    : UPDebugUIPanel.lua
--Author       : Song Fuhao
--Create Time  : 2018-04-19
--Description  : DebugUI面板
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPDebugUIPanel = luaclass("UPDebugUIPanel", PrefabBase)

local L10N = require("L10N")
local WndDataTable = require("WndDataTable")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

UPDebugUIPanel.tbDatas = nil
UPDebugUIPanel.tbListHelper = nil

local function GenerateListData(self)
    local tbDatas = {}
    local tbUIWndData = WndDataTable.tbContainer
    for _, v in pairs(tbUIWndData) do
        if v.bValidInDebugWidget then
            table.insert(tbDatas, v)
        end
    end
    self.tbDatas = tbDatas
end

local function GetDataByFilter(self, szFilterName)
    local tbFilterDatas = {}
    for _, v in ipairs(self.tbDatas) do
        local nPos = string.find(v.szWndName, szFilterName)
        if nPos and nPos > 0 then
            table.insert(tbFilterDatas, v)
        end
    end
    return tbFilterDatas
end

local function OnSearchTextChanged(self, l10nFilterName)
    local tbFilterDatas = GetDataByFilter(self, L10N:ToString(l10nFilterName))
    self.tbListHelper:SetData(tbFilterDatas)
end

local function OnClickedBtnUIClear(self)
    self.pWidgetRef.txtUISearch:SetText("")
end

function UPDebugUIPanel:OnLoad()
    GenerateListData(self)

    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, self.pWidgetRef.klistUI, self.tbDatas)
    self.tbListHelper.tbExtraDatas.bUI = true
end

function UPDebugUIPanel:OnUnload()
    self.tbListHelper:Uninit()
end

function UPDebugUIPanel:OnBindEvent(Helper)
    local pWidgetRef = self.pWidgetRef
    Helper:RegisterCppDelegate(pWidgetRef.txtUISearch.OnTextChanged , self, OnSearchTextChanged)
    Helper:RegisterCppDelegate(pWidgetRef.btnUIClear.OnClicked      , self, OnClickedBtnUIClear)
end

return UPDebugUIPanel
