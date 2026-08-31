-----------------------------------------------------
--File Name    : UILobbyIAP.lua
--Author       : song fuhao
--Create Time  : 2019-07-22
--Description  : 充值界面的UI
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILobbyIAP = luaclass("UILobbyIAP", WndBase)

local UIUtils = require("UIUtils")
local DelayTimer = require("DelayTimer")
local IAPDataTable = require("IAPDataTable")
local ClientEventDef = require("ClientEventDef")
local IAPResultCodeDef = require("IAPResultCodeDef")
local ChannelSDKSystem = require("ChannelSDKSystem")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local IAPResultToastDataTable = require("IAPResultToastDataTable")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local DEFAULT_PLATFORM = "android"
local DEFAULT_CHANNEL = "seasungames"

-- 是否处于充值状态中
UILobbyIAP.bInPurchasing = false
UILobbyIAP.DelayHandle = nil

local function OnIAPBegin(self)
    self.bInPurchasing = true
    UIUtils.ShowLoadingDialogWithKey("LOADING_DIALOG_IAP_MESSAGE")
end

local function OnIAPEnd(self, nResultCode)
    self.bInPurchasing = false
    if not self.DelayHandle then
        DelayTimer:ClearTimer(self.DelayHandle)
        self.DelayHandle = nil
    end
    self.DelayHandle = DelayTimer:RunNextTick(function()
        UIUtils.HideLoadingDialog()
        if IAPResultToastDataTable:IsShowToast(nResultCode) then
            local l10nMessage = IAPResultToastDataTable:GetMessage(nResultCode)
            UIUtils.ShowToast(l10nMessage)
        end
        self.DelayHandle = nil
    end)
end

local function UpdateIAPData(self, szPlatform, szChannel)
    local tbDatas = IAPDataTable:GetTemplateByPlatformAndChannel(szPlatform, szChannel)
    if #tbDatas > 0 then
        self.pWidgetRef.listItems:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.pWidgetRef.vboxEmpty:SetVisibility(ESlateVisibility.Collapsed)
        self.ListHelper:SetData(tbDatas)
    else
        self.pWidgetRef.listItems:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.vboxEmpty:SetVisibility(ESlateVisibility.HitTestInvisible)
    end
end

local function ShowDefaultIAPData(self)
    UpdateIAPData(self, DEFAULT_PLATFORM, DEFAULT_CHANNEL)
end

function UILobbyIAP:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.listItems)

    UpdateIAPData(self, GlobalVariableSystem:GetPlatformName(true), ChannelSDKSystem:GetChannelName())
end

function UILobbyIAP:OnUnload()
    if self.ListHelper then
        self.ListHelper:Uninit()
        self.ListHelper = nil
    end
end

function UILobbyIAP:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_IAP_BEGIN, self, OnIAPBegin)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_IAP_END, self, OnIAPEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_DEFAULT_IAP_DATA, self, ShowDefaultIAPData)
end

function UILobbyIAP:OnExit()
    if self.bInPurchasing then
        OnIAPEnd(self, IAPResultCodeDef.UNKNOWN_RESULT_WITH_UI_CLOSED)
    end
end

return UILobbyIAP
