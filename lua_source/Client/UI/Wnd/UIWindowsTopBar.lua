-----------------------------------------------------
--File Name    : UIWindowTopBar.lua
--Author       : Song Fuhao
--Create Time  : 2018-1-26
--Description  : 窗口顶部金币条
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIWindowTopBar = luaclass("UIWindowTopBar", WndBase)

local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local PlayerPropertySystem = require("PlayerPropertySystem")
local CurrencyDef = require("CurrencyDef")
local WidgetAnimationHandle = require("WidgetAnimationHandle")
local CurrencyIconResDataTable = require("CurrencyIconResDataTable")

UIWindowTopBar.nSpecialCurrencyType = nil

local function OnAnimationFinished(self)
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef:IsAnimationPlayingForward(pWidgetRef.animIn) then
        self:HideFinished()
    end
end

local function OnClickedBtnAddGoldCoin(self)
    UIUtils.ShowToastWithKey("IN_DEVELOPMENT")
end

local function OnClickedBtnAddSilverCoin(self)
    UIUtils.ShowToastWithKey("IN_DEVELOPMENT")
end

local function OnClickedBtnAddSpecialCoin(self)
    UIUtils.ShowToastWithKey("IN_DEVELOPMENT")
end

local function SetCurrency(self, nType, nCurrency)
    if nType == CurrencyDef.GOLD then
        self.pWidgetRef.txtGoldCoinCount:SetText(nCurrency)
    elseif nType == CurrencyDef.SILVER then
        self.pWidgetRef.txtSilverCoinCount:SetText(nCurrency)
    elseif self.bSpecialCoinEnabled then
        self.pWidgetRef.txtSpecialCoinCount:SetText(nCurrency)
    end
end

local function SyncCurrency(self, nType, nCurrency)
    SetCurrency(self, nType, nCurrency)
end

--[[
    在需要启用特殊货币的窗口的OnEnter或者OnShow时期发送事件
    local EventManager = require("EventManager")
    local ClientEventDef = require("ClientEventDef")
    EventManager:OnFireEvent(ClientEventDef.EV_SPECIAL_COIN_ENABLE, true, nType)
]]
local function SetSpecialCoinEnable(self, bEnable, nType)
    self.bSpecialCoinEnabled = bEnable
    self.nSpecialCurrencyType = nType
    if bEnable then
        self.pWidgetRef.ovlSpecialCoin:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

        local tbIconTemplate = CurrencyIconResDataTable:GetTemplate(nType)
        local tbRes = tbIconTemplate.szIcon

        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgSpecialCoinIcon, tbRes:load())
        self.pWidgetRef.txtSpecialCoinCount:SetText(PlayerPropertySystem:GetCurrency(nType))
    else
        self.pWidgetRef.ovlSpecialCoin:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UIWindowTopBar:OnShow()
    SetCurrency(self, CurrencyDef.GOLD, PlayerPropertySystem:GetGold())
    SetCurrency(self, CurrencyDef.SILVER, PlayerPropertySystem:GetSilver())

    local nCurrentTime = self.pWidgetRef:GetAnimationCurrentTime(self.pWidgetRef.animIn)
    local nStartAtTime = (nCurrentTime > 0) and nCurrentTime or 0
    self:PlayAnimation("animIn", nStartAtTime, 1, EUMGSequencePlayMode.Forward, 1)
end

function UIWindowTopBar:OnHide()
    self:PlayAnimation("animIn", 0, 1, EUMGSequencePlayMode.Reverse, 1)
    return false
end

function UIWindowTopBar:OnBindEvent(EventHelper)
    EventHelper:UnregisterAll()
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animIn, OnAnimationFinished, self))
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAddGoldCoin.OnClicked, self, OnClickedBtnAddGoldCoin)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAddSilverCoin.OnClicked, self, OnClickedBtnAddSilverCoin)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAddSpecialCoin.OnClicked, self, OnClickedBtnAddSpecialCoin)
    EventHelper:RegisterEvent(ClientEventDef.EV_CURRENCY_SYNC, self, SyncCurrency)
    EventHelper:RegisterEvent(ClientEventDef.EV_SPECIAL_COIN_ENABLE, self, SetSpecialCoinEnable)
end

return UIWindowTopBar
