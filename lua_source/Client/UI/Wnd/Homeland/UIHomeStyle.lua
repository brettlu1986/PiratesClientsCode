-----------------------------------------------------
--File Name    : UIHomeStyle.lua
--Author       : WuJizhou
--Create Time  : 5/15/2019, 10:47:23 AM
--Description  : UIHomeStyle
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")

local UIHomeStyle = luaclass("UIHomeStyle", WndBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local HomelandSceneDataTable = require("HomelandSceneDataTable")
local LandmarkBuildingTypeDataTable = require("LandmarkBuildingTypeDataTable")
local HomelandUIHelper = require("HomelandUIHelper")
local UIDef = require("UIDef")
local UISetUtils = require("UISetUtils")
local HomelandSystem = require("HomelandSystem")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
local ItemDataTable = require("ItemDataTable")
local ProcedureTool = require("ProcedureTool")
local ClientEventDef = require("ClientEventDef")
local UIUtils = require("UIUtils")
local SaveGameDef = require("SaveGameDef")

local SceneStyleState = HomelandUIHelper.MiscDef.SceneStyleState
UIHomeStyle.ListHelper = nil

local nCurrentSelectedIndex = nil

local function GetSceneStyleDatas(self)
    local nCurrentStyleIndex = 0
    local tbStyles = {}
    local tbTemplates = HomelandSceneDataTable:GetAllSceneTemplates()
    local nValue = 0
    for nSceneId, tbTemplate in pairs(tbTemplates) do
        nValue = nValue + 1
        local tbData = {}
        tbData.nSceneId = nSceneId
        local nCurrentSceneId = HomelandSystem:GetCurrentSceneId()
        if nSceneId == nCurrentSceneId then
            tbData.nState = SceneStyleState.InUse
            nCurrentStyleIndex = nValue
        else
            if HomelandSystem:IsSceneUnlock(nSceneId) then
                if HomelandSystem:IsSceneCanUse(nSceneId) then
                    tbData.nState = SceneStyleState.Owned
                else
                    tbData.nState = SceneStyleState.Unlocked
                end
            else
                tbData.nState = SceneStyleState.Locked
            end
        end
        table.insert(tbStyles, tbData)
    end
    table.sort(tbStyles, function (tbStyle1, tbStyle2) return tbStyle1.nSceneId < tbStyle2.nSceneId end)
    if not nCurrentSelectedIndex then
        nCurrentSelectedIndex = nCurrentStyleIndex
    end
    return tbStyles, nCurrentSelectedIndex
end

local function InitWindowFrame(self)
    local pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame = pbWindowFrame
end

local function Refresh(self, tbData)
    local nSceneId = tbData.nSceneId
    local nState = tbData.nState
    local pWidgetRef = self.pWidgetRef
    local Visible = ESlateVisibility_SelfHitTestInvisible
    local Hidden = ESlateVisibility_Collapsed

    local tbTemplate = HomelandSceneDataTable:GetSceneTemplate(nSceneId)
    local l10nName = tbTemplate.l10nName
    pWidgetRef.txtStyleName:SetText(l10nName)
    local l10nDesc = tbTemplate.l10nDesc
    pWidgetRef.txtStyleDesc:SetText(l10nDesc)
    local szBackground = tbTemplate.szBackground
    UISetUtils.SetImageBrushRes(self.pbWindowFrame.pWidgetRef.imgBg, szBackground:load())

    if nState == SceneStyleState.InUse then
        pWidgetRef.ovlSwitch:SetVisibility(Hidden)
        pWidgetRef.hboxCost:SetVisibility(Hidden)
        pWidgetRef.txtUnlockCondition:SetVisibility(Hidden)
    elseif nState == SceneStyleState.Owned then
        pWidgetRef.ovlSwitch:SetVisibility(Visible)
        pWidgetRef.txtSwicth:SetText(UITextDef.HOMELAND_SWITCH_STYLE)
        pWidgetRef.hboxCost:SetVisibility(Hidden)
        pWidgetRef.txtUnlockCondition:SetVisibility(Hidden)

    elseif nState == SceneStyleState.Unlocked then
        pWidgetRef.ovlSwitch:SetVisibility(Visible)
        pWidgetRef.txtSwicth:SetText(UITextDef.HOMELAND_BUY_STYLE)
        pWidgetRef.hboxCost:SetVisibility(Visible)
        pWidgetRef.txtUnlockCondition:SetVisibility(Hidden)
        local nCurrencyId = tbTemplate.nCurrencyId
        local tbResTemplate = ItemDataTable:GetResTemplate(nCurrencyId)
        local szCurrencyIcon = tbResTemplate.szIconPath
        UISetUtils.SetImageBrushRes(pWidgetRef.imgCoin, szCurrencyIcon:load())
        local nPrice = tbTemplate.nPrice
        pWidgetRef.txtCoinCount:SetText(nPrice)
    else
        pWidgetRef.ovlSwitch:SetVisibility(Hidden)
        pWidgetRef.hboxCost:SetVisibility(Hidden)
        pWidgetRef.txtUnlockCondition:SetVisibility(Visible)
        local nUnlockLandmarkType = tbTemplate.nUnlockLandmarkType
        local nUnlockLandmarkGrade = tbTemplate.nUnlockLandmarkGrade
        local l10nLandmarkName = LandmarkBuildingTypeDataTable:GetTemplate(nUnlockLandmarkType).l10nName
        local l10nText = L10N:Format(UITextDef.HOMELAND_STYLE_UNLOCK_CONDITION, l10nLandmarkName, nUnlockLandmarkGrade)
        pWidgetRef.txtUnlockCondition:SetText(l10nText)
    end
end


local function OnListSelectedChanged(self, nIndex)
    local tbData = self.ListHelper:GetSelectedData()
    nCurrentSelectedIndex = nIndex
    Refresh(self, tbData)
end

local function RequestToSwitch(self, bRecovered)
    local tbData = self.ListHelper:GetSelectedData()
    HomelandSystem:RequestSetCurrentSceneId(tbData.nSceneId, bRecovered)
end

local function ConfirmSwitchNotRecover(self)
    RequestToSwitch(self, false)
end

local function ConfirmSwitchRecover(self)
    RequestToSwitch(self, true)
end

local function ShowRecoverStyleDialog(self)
    local Dialog = UIUtils.CreateDialog(L10N.NullString)
    Dialog:SetMessage(UITextDef.HOMELAND_RECOVER_STYLE_DIALOG_CONTENT)
    Dialog:SetPositiveButtonVisible(true)
    Dialog:SetNegativeButtonVisible(true)
    Dialog:SetCloseButtonVisible(false)
    Dialog:SetNegativeText(UITextDef.HOMELAND_RECOVER_STYLE_DIALOG_NEGATIVE_BTN_TEXT)
    Dialog:SetPositiveButtonCallback(ConfirmSwitchRecover, self)
    Dialog:SetNegativeButtonCallback(ConfirmSwitchNotRecover, self)
    Dialog:ShowDialog()
end


local function ConfirmSwitch(self)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
	pSaveGameMgr:AddBoolData(SaveGameDef.HOMELAND_SWITCH_FLAG, true)
	pSaveGameMgr:Save()
    RequestToSwitch(self)
end

local function ShowConfirmSwitchDialog(self)
    local Dialog = UIUtils.CreateDialog(L10N.NullString)
    Dialog:SetMessage(UITextDef.HOMELAND_SWITCH_STYLE_DIALOG_CONTENT)
    -- Dialog:SetPositiveText(UITextDef.HOMELAND_MARK_BUILDING_UPGRADE_CONFIRM)
    Dialog:SetPositiveButtonCallback(ConfirmSwitch, self)
    Dialog:SetPositiveButtonVisible(true)
    Dialog:SetNegativeButtonVisible(true)
    Dialog:SetCloseButtonVisible(false)
    Dialog:ShowDialog()
end

-- local function HasTargetStyleCached(nSceneId)
--     local bResult = false
--     local tbSceneData = HomelandSystem:GetCurrentSceneData()
--     for k, v in pairs(tbSceneData) do
--         if v.nItemInstanceId and v.nItemInstanceId > 0 then
--             bResult = true
--             break
--         end
--     end
--     return bResult
-- end

local function ProcessOwnedStyle(self, nSceneId)
    local bHasTargetStyleCached = HomelandSystem:SceneHasBuildData(nSceneId)
    if bHasTargetStyleCached then
        ShowRecoverStyleDialog(self)
        return
    end
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local bFlag = pSaveGameMgr:GetBoolDataWithDefault(SaveGameDef.HOMELAND_SWITCH_FLAG, false)
    if not bFlag then
        ShowConfirmSwitchDialog(self)
    else
        RequestToSwitch(self, false)
    end
end

local function OnBtnClicked(self)
    local tbData = self.ListHelper:GetSelectedData()
    local nState = tbData.nState

    if nState == SceneStyleState.InUse then
        logerror("UIHomeStyle, Style's state is InUse, button should be hidden")
    elseif nState == SceneStyleState.Owned then
        ProcessOwnedStyle(self, tbData.nSceneId)
    elseif nState == SceneStyleState.Unlocked then
        HomelandSystem:RequestPurchaseScene(tbData.nSceneId)
    else
        logerror("UIHomeStyle, Style's state is Locked, button should be hidden")
    end
end

local function OnPurchaseStyle(self, nSceneId)
    local tbData = self.ListHelper:GetSelectedData()
    if tbData.nSceneId == nSceneId then
        local tbDatas, nSelectedIndex = GetSceneStyleDatas(self)
        assert(nSelectedIndex > 0 and nSelectedIndex <= #tbDatas)
        self.ListHelper:SetData(tbDatas)
        self.ListHelper:SetSelectedIndex(nSelectedIndex)
    end
end

local function OnSwitchStyleSucceed(self, nSceneId)
    local tbTemplate =  HomelandSceneDataTable:GetSceneTemplate(nSceneId)
    assert(tbTemplate)
    local tbParam = {bSwitchStyle = true, szHomelandBg = tbTemplate.szBackground}
    ProcedureTool:EnterHomeland(tbParam, true)
end

----------life cycle----------

function UIHomeStyle:OnLoad()
    InitWindowFrame(self)
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.vlistStyles,{}, UIDef.UP_HOME_STYLE_LIST_ITEM)
    self.ListHelper.OnSelectedChangedDelegate:Bind(OnListSelectedChanged, self)
end

function UIHomeStyle:OnShow()
    local tbDatas, nCurrentStyleIndex = GetSceneStyleDatas(self)
    assert(nCurrentStyleIndex > 0 and nCurrentStyleIndex <= #tbDatas)
    self.ListHelper:SetData(tbDatas)
    self.ListHelper:SetSelectedIndex(nCurrentStyleIndex)
end

function UIHomeStyle:OnUnload()
    self.ListHelper:Uninit()
    nCurrentSelectedIndex = nil
end

function UIHomeStyle:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnStart.OnClicked, self, OnBtnClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOMELAND_PURCHASE_SCENE, self, OnPurchaseStyle)
    EventHelper:RegisterEvent(ClientEventDef.EV_SWITCH_HOMELAND_SCENE, self, OnSwitchStyleSucceed)
end

return UIHomeStyle