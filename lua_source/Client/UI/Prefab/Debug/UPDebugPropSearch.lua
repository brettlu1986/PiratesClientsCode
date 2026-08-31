-----------------------------------------------------
--File Name    : UPDebugPropSearch.lua
--Author       : Song Fuhao
--Create Time  : 2019-05-16
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPDebugPropSearch = luaclass("UPDebugPropSearch", PrefabBase)

local L10N = require("L10N")
local StringUtil = require("StringUtil")
local ClientEventDef = require("ClientEventDef")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local GMSearchablePropDataTable = require("GMSearchablePropDataTable")

local INIT_DATA_FORMAT = "%s\n* %s"
local DATA_FORMAT = "%s\n--------------------\n%s\n* %s"

UPDebugPropSearch.szResultText = nil
UPDebugPropSearch.ListHelper = nil

local function OnBtnClearClicked(self)
    self.pWidgetRef.editSearch:SetText("")
end

local function OnReceiveData(self, szKey, szData)
    local tbTemplate = GMSearchablePropDataTable:GetTemplate(szKey)
    local szDesc = tbTemplate.szDesc
    if self.szResultText then
        self.szResultText = string.format(DATA_FORMAT, self.szResultText, szDesc, szData)
    else
        self.szResultText = string.format(INIT_DATA_FORMAT, szDesc, szData)
    end
    self.pWidgetRef.txtResult:SetText(self.szResultText)
    self.pWidgetRef.sclResult:ScrollToEnd()
end

local function ContainText(szContent, szSearchText)
    local tbParams = StringUtil.Split(szSearchText, " ")
    for _, v in ipairs(tbParams) do
        if string.find(szContent, v) == nil then
            return false
        end
    end
    return true
end

local function SetListData(self, tbDatas)
    if tbDatas and (#tbDatas > 0) then
        self.ListHelper:SetData(tbDatas)
        self.pWidgetRef.listProp:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.pWidgetRef.vboxEmpty:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.pWidgetRef.listProp:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.vboxEmpty:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

local function OnSearchTextChanged(self, l10nText)
    local tbDatas = {}
    local szSearchText = L10N:ToString(l10nText)
    for i, v in ipairs(self.tbOriginDatas) do
        if ContainText(v.szKey, szSearchText) or ContainText(v.szDesc, szSearchText) then
            table.insert(tbDatas, v)
        end
    end
    SetListData(self, tbDatas)
end

function UPDebugPropSearch:OnLoad()
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.listProp)

    self.tbOriginDatas = GMSearchablePropDataTable:GetTemplateList()
    SetListData(self, self.tbOriginDatas)
end

function UPDebugPropSearch:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UPDebugPropSearch:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClear.OnClicked, self, OnBtnClearClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.editSearch.OnTextChanged, self, OnSearchTextChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEND_PROP_DATA_FOR_GM, self, OnReceiveData)
end

return UPDebugPropSearch