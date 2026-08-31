local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIUseRose = luaclass("UIUseRose", WndBase)

local LobbyItemIni = require("LobbyItemIni")
local MathUtil = require("MathUtil")
local UIDef = require("UIDef")
local ItemSystem = require("ItemSystem")
local ClientEventDef = require("ClientEventDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local UITextDef = require("UITextDef")

UIUseRose.pbDialogFrame = nil
UIUseRose.pbLobbyDisplayItem = nil

UIUseRose.tbItem = nil
UIUseRose.nReceveFriendId = -1
UIUseRose.szReceiveFriendName = ""
UIUseRose.nMaxChooseCount = nil
UIUseRose.nStepSize = -1

local function SetChooseCount(self, nCount)
    local Item = self.tbItem
    local nCurrentMaxCount = self.nMaxChooseCount
    local nCurrentCount = MathUtil.Clamp(nCount, 1, nCurrentMaxCount)
    local nPercent = nCurrentCount / nCurrentMaxCount
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pgbCount:SetPercent(nPercent)
    pWidgetRef.sldrCount:SetValue(nPercent)

    local szChooseCount = nCurrentCount .."/".. self.nMaxChooseCount
    self.pWidgetRef.txtChooseCount:SetText(szChooseCount)

    local tbTemplate = Item:GetTemplate()
    local nBaseIntimateCount = tbTemplate.nRewardIntimacy or 0
    self.pWidgetRef.txtAddCount:SetText("+" .. nBaseIntimateCount * nCurrentCount)

    self.nCurrentCount = nCurrentCount
end

local function OnClickedBtnAdd(self)
    if self.nCurrentCount < self.nMaxChooseCount then
        SetChooseCount(self, self.nCurrentCount + 1)
    end
end

local function OnClickedBtnMinus(self)
    SetChooseCount(self, self.nCurrentCount - 1)
end

local function OnSldrCountValueChanged(self, nValue)
    local nCount = MathUtil.Round(nValue / self.nStepSize)
    SetChooseCount(self, nCount)
end

local function ConfirmUse(self)
    ItemSystem:RequestUseItem(self.tbItem:GetInstanceId(), self.nCurrentCount, self.nReceveFriendId)
end 

local function OnUseItemSuccess(self)
    self:CloseSelf()
    local tbTemplate = self.tbItem:GetTemplate()
    local nBaseIntimateCount = tbTemplate.nRewardIntimacy or 0
    local nIntimateCount = nBaseIntimateCount * self.nCurrentCount

    local fnOk = function() end
    local l10nTitle = L10N:Format(UISetUtils.GetL10NTextByKey("USE_SUCCESSED"))
    local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("USE_INTIMATE_CONTENT"), self.szReceiveFriendName, self.tbItem:GetName(), self.nCurrentCount, nIntimateCount)
    UIUtils.ShowDialog(l10nTitle, l10nMessage, UITextDef.L10N_OK, fnOk)
end

function UIUseRose:OnLoad()
    self.tbItem = self.tbOpenArgs.tbItem
    self.nReceveFriendId = self.tbOpenArgs.nFriendId
    self.szReceiveFriendName = self.tbOpenArgs.szName

    self.pbDialogFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogFrame)
    self.pbDialogFrame:SetDialogClosedCallback(self.CloseSelf, self)
    self.pbDialogFrame:SetCloseButtonVisible(true)
    self.pbDialogFrame:SetPositiveButtonCallback(ConfirmUse, self)

    self.pbLobbyDisplayItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyItem, UIDef.UP_LOBBY_DISPLAY_ITEM)
    self.pbLobbyDisplayItem:SetDisplayItemData(self.tbItem:GetTemplateId(), nil, false)
end

function UIUseRose:OnShow()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtName:SetText(self.tbItem:GetName())

    local nCount = self.tbItem:GetStackCount()
    if self.tbItem:HasHoldLimit() then
        local szCount = nCount .."/".. self.tbItem:GetHoldLimit()
        pWidgetRef.txtCount:SetText(szCount)
    else
        pWidgetRef.txtCount:SetText(nCount)
    end
    
    self.nMaxChooseCount = math.min(self.tbItem:GetStackCount(), LobbyItemIni.tbItemUse.nUseMax)
    local nStackCount = self.nMaxChooseCount
    self.nStepSize = 1 / nStackCount
    self.pWidgetRef.sldrCount:SetStepSize(self.nStepSize)
    SetChooseCount(self, 1)
end

function UIUseRose:OnBindEvent()
    local Helper = self.EventHelper
    local pWidgetRef = self.pWidgetRef
    Helper:RegisterCppDelegate(pWidgetRef.btnAdd.OnClicked, self, OnClickedBtnAdd)
    Helper:RegisterCppDelegate(pWidgetRef.btnMinus.OnClicked, self, OnClickedBtnMinus)
    Helper:RegisterCppDelegate(pWidgetRef.sldrCount.OnValueChanged, self, OnSldrCountValueChanged)
    Helper:RegisterEvent(ClientEventDef.EV_USE_LOBBY_ITEM_SUCCESS, self, OnUseItemSuccess)
end

function UIUseRose:OnDestroy()
end

return UIUseRose
